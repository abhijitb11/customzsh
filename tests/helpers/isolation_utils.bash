#!/bin/bash
#
# isolation_utils.bash
#
# Test isolation utilities for customzsh test suite
# Provides functions for creating isolated test environments,
# managing test directories, and ensuring comprehensive cleanup
#
# Functions:
# - generate_test_uuid(): Create unique test identifiers
# - setup_isolated_environment(): Create isolated test environment
# - validate_clean_environment(): Verify environment is clean before test
# - cleanup_test_environment(): Comprehensive test cleanup
# - check_for_resource_leaks(): Detect resource leaks after tests
# - create_test_backup(): Backup existing files before testing
# - restore_test_backup(): Restore backed up files after testing
#
# Author: Claude Code
# Version: 1.0
#

# Generate unique test identifier
generate_test_uuid() {
    local uuid_method="${1:-auto}"

    case "$uuid_method" in
        "uuidgen")
            if command -v uuidgen >/dev/null 2>&1; then
                uuidgen
            else
                echo "Error: uuidgen not available" >&2
                return 1
            fi
            ;;
        "timestamp")
            date +%s%N 2>/dev/null || echo "${RANDOM}${RANDOM}$$"
            ;;
        "auto")
            if command -v uuidgen >/dev/null 2>&1; then
                uuidgen
            else
                # Fallback for environments without uuidgen or nanosecond date
                date +%s 2>/dev/null || echo "${RANDOM}${RANDOM}$$"
            fi
            ;;
        *)
            echo "Error: Invalid UUID method: $uuid_method" >&2
            return 1
            ;;
    esac
}

# Setup isolated test environment
setup_isolated_environment() {
    local test_home="$1"
    local test_name="${2:-unknown_test}"

    [ -z "$test_home" ] && {
        echo "Error: test_home parameter required" >&2
        return 1
    }

    # Create test directory structure
    mkdir -p "$test_home"
    mkdir -p "$test_home/.config"
    mkdir -p "$test_home/.cache"
    mkdir -p "$test_home/.local/bin"

    # Set up isolated environment variables
    export TEST_ORIGINAL_HOME="$HOME"
    export TEST_ORIGINAL_PATH="$PATH"
    export TEST_ORIGINAL_USER="$USER"
    export TEST_ORIGINAL_SUDO_USER="$SUDO_USER"

    # Override environment for isolation
    export HOME="$test_home"
    export USER="testuser"
    export SUDO_USER=""

    # Create test metadata
    cat > "$test_home/.test_metadata" << EOF
TEST_NAME="$test_name"
TEST_START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
TEST_PID="$$"
TEST_UUID="$(basename "$test_home" | sed 's/.*_//')"
ORIGINAL_HOME="$TEST_ORIGINAL_HOME"
ORIGINAL_PATH="$TEST_ORIGINAL_PATH"
ORIGINAL_USER="$TEST_ORIGINAL_USER"
EOF

    echo "Isolated test environment created: $test_home"
}

# Validate clean environment before test
validate_clean_environment() {
    local test_home="${1:-$HOME}"
    local strict_mode="${2:-false}"

    # Skip validation if test directory doesn't exist yet (which is normal)
    if [ ! -d "$test_home" ]; then
        echo "Test directory does not exist yet (normal for new tests)"
        return 0
    fi

    local validation_errors=()

    # Check for existing Oh My Zsh installation
    if [ -d "$test_home/.oh-my-zsh" ]; then
        validation_errors+=("Oh My Zsh directory already exists: $test_home/.oh-my-zsh")
    fi

    # Check for existing .zshrc
    if [ -f "$test_home/.zshrc" ]; then
        validation_errors+=(".zshrc file already exists: $test_home/.zshrc")
    fi

    # Check for existing config files
    if [ -f "$test_home/config.sh" ]; then
        validation_errors+=("config.sh file already exists: $test_home/config.sh")
    fi

    # Check for leftover backup files
    if [ -f "$test_home/.zshrc.pre-customzsh" ]; then
        validation_errors+=("Backup file already exists: $test_home/.zshrc.pre-customzsh")
    fi

    # In strict mode, check for any unexpected files (but allow common system files)
    if [ "$strict_mode" = true ]; then
        local unexpected_files
        unexpected_files=$(find "$test_home" -type f ! -name ".test_metadata" ! -name ".bashrc" ! -name ".profile" 2>/dev/null || true)
        if [ -n "$unexpected_files" ]; then
            validation_errors+=("Unexpected files found in test environment:")
            while IFS= read -r file; do
                [ -n "$file" ] && validation_errors+=("  - $file")
            done <<< "$unexpected_files"
        fi
    fi

    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo "Environment validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    else
        echo "Environment validation passed"
        return 0
    fi
}

# Comprehensive test cleanup
cleanup_test_environment() {
    local test_home="${1:-$HOME}"
    local force_cleanup="${2:-false}"

    # Read test metadata if available
    local test_metadata_file="$test_home/.test_metadata"
    if [ -f "$test_metadata_file" ]; then
        source "$test_metadata_file"
        echo "Cleaning up test: $TEST_NAME (UUID: $TEST_UUID)"
    fi

    # Restore original environment variables
    if [ -n "$TEST_ORIGINAL_HOME" ]; then
        export HOME="$TEST_ORIGINAL_HOME"
    fi
    if [ -n "$TEST_ORIGINAL_PATH" ]; then
        export PATH="$TEST_ORIGINAL_PATH"
    fi
    if [ -n "$TEST_ORIGINAL_USER" ]; then
        export USER="$TEST_ORIGINAL_USER"
    fi
    if [ -n "$TEST_ORIGINAL_SUDO_USER" ]; then
        export SUDO_USER="$TEST_ORIGINAL_SUDO_USER"
    fi

    # Clean up test directory
    if [ -d "$test_home" ] && [[ "$test_home" =~ "/tmp/" ]]; then
        # Safety check: only clean directories in /tmp
        if [ "$force_cleanup" = true ] || [[ "$test_home" =~ "customzsh.*test" ]]; then
            # Remove any restrictive permissions before cleanup
            find "$test_home" -type d -exec chmod 755 {} \; 2>/dev/null || true
            find "$test_home" -type f -exec chmod 644 {} \; 2>/dev/null || true

            rm -rf "$test_home"
            echo "Test environment cleaned up: $test_home"
        else
            echo "Warning: Skipping cleanup of suspicious directory: $test_home" >&2
        fi
    fi

    # Unset test-specific environment variables
    unset TEST_ORIGINAL_HOME TEST_ORIGINAL_PATH TEST_ORIGINAL_USER TEST_ORIGINAL_SUDO_USER
    unset TEST_HOME TEST_SCRIPT_DIR TEST_UUID
}

# Check for resource leaks after tests
check_for_resource_leaks() {
    local test_home="${1:-$HOME}"
    local leak_report_file="${2:-/tmp/resource_leaks.log}"

    # Skip resource leak detection in Docker environments to avoid false positives
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        echo "Skipping resource leak detection in Docker environment"
        return 0
    fi

    local leaks_found=false

    # Check for leftover processes (only if not in Docker)
    local test_processes
    test_processes=$(pgrep -f "customzsh.*test" 2>/dev/null || true)
    if [ -n "$test_processes" ]; then
        echo "Resource leak detected: customzsh test processes still running" >&2
        echo "PIDs: $test_processes" >&2
        leaks_found=true
    fi

    # Check for leftover temporary files specific to our test pattern
    local temp_files
    temp_files=$(find /tmp -name "*customzsh*test*" -type f 2>/dev/null || true)
    if [ -n "$temp_files" ]; then
        # Filter out current test directory
        temp_files=$(echo "$temp_files" | grep -v "^$test_home" || true)
        if [ -n "$temp_files" ]; then
            echo "Resource leak detected: temporary test files not cleaned up" >&2
            echo "$temp_files" >&2
            leaks_found=true
        fi
    fi

    # Check for leftover directories specific to our test pattern
    local temp_dirs
    temp_dirs=$(find /tmp -name "*customzsh*test*" -type d 2>/dev/null | grep -v "^$test_home" || true)
    if [ -n "$temp_dirs" ]; then
        echo "Resource leak detected: temporary test directories not cleaned up" >&2
        echo "$temp_dirs" >&2
        leaks_found=true
    fi

    # Write leak report if requested
    if [ -n "$leak_report_file" ] && [ "$leaks_found" = true ]; then
        {
            echo "Resource Leak Report - $(date)"
            echo "Test Home: $test_home"
            echo "Processes: $test_processes"
            echo "Temp Files: $temp_files"
            echo "Temp Dirs: $temp_dirs"
            echo "---"
        } >> "$leak_report_file"
    fi

    if [ "$leaks_found" = true ]; then
        echo "Resource leaks detected - see above for details" >&2
        return 1
    else
        echo "No resource leaks detected"
        return 0
    fi
}

# Create backup of existing files before testing
create_test_backup() {
    local backup_dir="${1:-/tmp/customzsh_test_backup_$$}"
    local files_to_backup="$2"

    [ -z "$files_to_backup" ] && {
        # Default files to backup
        files_to_backup="$HOME/.zshrc $HOME/.oh-my-zsh $HOME/.zshrc.pre-customzsh"
    }

    mkdir -p "$backup_dir"

    local backup_manifest="$backup_dir/.backup_manifest"
    echo "# Backup created on $(date)" > "$backup_manifest"
    echo "# Original HOME: $HOME" >> "$backup_manifest"

    for file_path in $files_to_backup; do
        if [ -e "$file_path" ]; then
            local backup_name
            backup_name=$(echo "$file_path" | sed 's|/|_|g')

            if [ -d "$file_path" ]; then
                cp -r "$file_path" "$backup_dir/$backup_name"
                echo "DIR:$file_path:$backup_name" >> "$backup_manifest"
            elif [ -f "$file_path" ]; then
                cp "$file_path" "$backup_dir/$backup_name"
                echo "FILE:$file_path:$backup_name" >> "$backup_manifest"
            fi

            echo "Backed up: $file_path -> $backup_dir/$backup_name"
        fi
    done

    echo "$backup_dir"
}

# Restore backed up files after testing
restore_test_backup() {
    local backup_dir="$1"
    local force_restore="${2:-false}"

    [ -z "$backup_dir" ] && {
        echo "Error: backup_dir parameter required" >&2
        return 1
    }

    local backup_manifest="$backup_dir/.backup_manifest"

    if [ ! -f "$backup_manifest" ]; then
        echo "Error: Backup manifest not found: $backup_manifest" >&2
        return 1
    fi

    echo "Restoring backup from: $backup_dir"

    while IFS=':' read -r file_type original_path backup_name; do
        # Skip comments
        [[ "$file_type" =~ ^#.*$ ]] && continue

        local backup_file="$backup_dir/$backup_name"

        if [ ! -e "$backup_file" ]; then
            echo "Warning: Backup file not found: $backup_file" >&2
            continue
        fi

        # Remove existing file/directory if force restore is enabled
        if [ "$force_restore" = true ] && [ -e "$original_path" ]; then
            rm -rf "$original_path"
        fi

        case "$file_type" in
            "FILE")
                if [ ! -f "$original_path" ]; then
                    cp "$backup_file" "$original_path"
                    echo "Restored file: $original_path"
                else
                    echo "Warning: File exists, skipping restore: $original_path" >&2
                fi
                ;;
            "DIR")
                if [ ! -d "$original_path" ]; then
                    cp -r "$backup_file" "$original_path"
                    echo "Restored directory: $original_path"
                else
                    echo "Warning: Directory exists, skipping restore: $original_path" >&2
                fi
                ;;
        esac
    done < "$backup_manifest"

    echo "Backup restoration completed"
}

# Cleanup backup directory
cleanup_test_backup() {
    local backup_dir="$1"

    [ -z "$backup_dir" ] && {
        echo "Error: backup_dir parameter required" >&2
        return 1
    }

    if [ -d "$backup_dir" ] && [[ "$backup_dir" =~ "/tmp/" ]]; then
        rm -rf "$backup_dir"
        echo "Backup cleanup completed: $backup_dir"
    else
        echo "Warning: Skipping cleanup of suspicious backup directory: $backup_dir" >&2
    fi
}

# Set test timeout
set_test_timeout() {
    local timeout_seconds="${1:-300}"  # 5 minute default
    local test_name="${2:-current_test}"

    (
        sleep "$timeout_seconds"
        echo "Test timeout reached for: $test_name" >&2
        # Find and kill test processes
        pkill -f "customzsh.*test" 2>/dev/null || true
        pkill -f "bats.*test" 2>/dev/null || true
    ) &

    local timeout_pid=$!
    echo "$timeout_pid" > "/tmp/test_timeout_$$"

    echo "Test timeout set: ${timeout_seconds}s for $test_name (PID: $timeout_pid)"
}

# Clear test timeout
clear_test_timeout() {
    local timeout_file="/tmp/test_timeout_$$"

    if [ -f "$timeout_file" ]; then
        local timeout_pid
        timeout_pid=$(cat "$timeout_file")
        kill "$timeout_pid" 2>/dev/null || true
        rm -f "$timeout_file"
        echo "Test timeout cleared (PID: $timeout_pid)"
    fi
}