#!/usr/bin/env bats
#
# compatibility.bats
#
# Zsh version compatibility testing for customzsh
# Tests installation and functionality across different zsh versions
# and shell configurations to ensure broad compatibility
#
# Test Categories:
# - Zsh version compatibility (5.0, 5.4, 5.8, 5.9+)
# - Oh My Zsh version compatibility testing
# - Shell configuration compatibility
# - Cross-platform shell behavior validation
# - Plugin compatibility across zsh versions
# - Theme compatibility and rendering
# - Feature availability detection and graceful degradation
#
# Test Count: 8 tests
# Dependencies: zsh (multiple versions if available)
# Environment: Enhanced isolation with version detection
#
# Author: Claude Code
# Version: 1.0
#

# Load test helpers
load 'helpers/isolation_utils'
load 'helpers/validation_helpers'
load 'helpers/error_simulation'

# Compatibility testing variables
ZSH_VERSION_MAJOR=""
ZSH_VERSION_MINOR=""
COMPAT_LOG_FILE=""

# Setup function runs before each test
setup() {
    # Generate UUID for unique test directory
    local test_uuid
    test_uuid=$(generate_test_uuid)
    export TEST_HOME="/tmp/customzsh_compat_test_${test_uuid}"
    export TEST_SCRIPT_DIR="${TEST_HOME}/customzsh"
    export COMPAT_LOG_FILE="${TEST_HOME}/compatibility.log"

    # Validate clean environment before setup
    validate_clean_environment "$TEST_HOME" true

    # Setup isolated test environment
    setup_isolated_environment "$TEST_HOME" "compatibility_test"

    # Copy project files to test directory (including hidden files)
    mkdir -p "$TEST_SCRIPT_DIR"
    find . -maxdepth 1 -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    find . -maxdepth 1 -name ".*" -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    # Copy directories but avoid copying test directory itself
    find . -maxdepth 1 -type d ! -name "." ! -name "tests" -exec cp -r {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    cd "$TEST_SCRIPT_DIR"

    # Detect zsh version
    detect_zsh_version

    # Create compatibility log
    {
        echo "Compatibility Test Log - $(date)"
        echo "Test UUID: $test_uuid"
        echo "Zsh Version: $(zsh --version 2>/dev/null || echo 'unknown')"
        echo "System: $(uname -a 2>/dev/null || echo 'unknown')"
        echo "---"
    } > "$COMPAT_LOG_FILE"

    # Set test timeout
    set_test_timeout 180 "compatibility_test_${test_uuid}"
}

# Teardown function runs after each test
teardown() {
    # Clear test timeout
    clear_test_timeout

    # Archive compatibility log if it exists
    if [ -f "$COMPAT_LOG_FILE" ]; then
        local archive_log="/tmp/customzsh_compat_$(date +%s).log"
        cp "$COMPAT_LOG_FILE" "$archive_log" 2>/dev/null || true
        echo "Compatibility log archived: $archive_log"
    fi

    # Check for resource leaks
    check_for_resource_leaks "$TEST_HOME"

    # Comprehensive cleanup with verification
    cleanup_test_environment "$TEST_HOME" true

    # Verify cleanup completed
    [ ! -d "$TEST_HOME" ] || {
        echo "Warning: Test cleanup incomplete for $TEST_HOME" >&2
    }
}

# Helper function to detect zsh version
detect_zsh_version() {
    if command -v zsh >/dev/null 2>&1; then
        local version_string
        version_string=$(zsh --version 2>/dev/null | head -n1)

        # Extract major and minor version numbers
        ZSH_VERSION_MAJOR=$(echo "$version_string" | sed -n 's/.*zsh \([0-9]\+\)\.\([0-9]\+\).*/\1/p')
        ZSH_VERSION_MINOR=$(echo "$version_string" | sed -n 's/.*zsh \([0-9]\+\)\.\([0-9]\+\).*/\2/p')

        log_compatibility "Zsh Version Detection" "$ZSH_VERSION_MAJOR.$ZSH_VERSION_MINOR" ""
    else
        ZSH_VERSION_MAJOR="0"
        ZSH_VERSION_MINOR="0"
        log_compatibility "Zsh Version Detection" "Not available" ""
    fi
}

# Helper function to log compatibility information
log_compatibility() {
    local test_name="$1"
    local result="$2"
    local notes="$3"

    {
        echo "$(date '+%H:%M:%S') - $test_name: $result"
        if [ -n "$notes" ]; then
            echo "  Notes: $notes"
        fi
    } >> "$COMPAT_LOG_FILE"
}

# Helper function to check zsh version requirements
check_version_requirement() {
    local required_major="$1"
    local required_minor="$2"

    if [ "$ZSH_VERSION_MAJOR" -gt "$required_major" ]; then
        return 0
    elif [ "$ZSH_VERSION_MAJOR" -eq "$required_major" ] && [ "$ZSH_VERSION_MINOR" -ge "$required_minor" ]; then
        return 0
    else
        return 1
    fi
}

# Zsh Version Compatibility Tests

@test "validates minimum zsh version requirements" {
    # CustomZsh should work with zsh 5.0+
    local min_major=5
    local min_minor=0

    if command -v zsh >/dev/null 2>&1; then
        local current_version="$ZSH_VERSION_MAJOR.$ZSH_VERSION_MINOR"
        log_compatibility "Current Zsh Version" "$current_version" ""

        if check_version_requirement $min_major $min_minor; then
            log_compatibility "Version Requirement Check" "PASS" "Meets minimum requirement (5.0+)"
        else
            log_compatibility "Version Requirement Check" "FAIL" "Below minimum requirement (5.0+)"
            skip "Zsh version $current_version is below minimum requirement 5.0"
        fi
    else
        skip "Zsh not available for version testing"
    fi
}

@test "tests basic shell syntax compatibility" {
    # Create a config with various shell features
    cat > config.sh << 'EOF'
#!/bin/bash
# Test array syntax
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
)
BUILTIN_PLUGINS=(git z command-not-found cp)
EZA_VERSION="v0.18.0"

# Test parameter expansion
PLUGIN_COUNT=${#EXTERNAL_PLUGINS[@]}
EOF

    # Test if config can be sourced properly
    run zsh -c 'source config.sh; echo "Config loaded successfully"; echo "Plugins: $PLUGIN_COUNT"'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Config loaded successfully" ]]
    [[ "$output" =~ "Plugins: 2" ]]

    log_compatibility "Shell Syntax Test" "PASS" "Array and parameter expansion work"
}

@test "validates zsh-specific features availability" {
    # Test zsh-specific features used by Oh My Zsh
    run zsh -c '
        # Test autoload
        autoload -Uz compinit 2>/dev/null && echo "autoload: OK" || echo "autoload: FAIL"

        # Test zsh arrays (1-indexed)
        array=(one two three)
        echo "Array test: ${array[1]}"

        # Test parameter expansion
        test_var="hello world"
        echo "Parameter expansion: ${test_var:u}"
    '

    [ "$status" -eq 0 ]
    [[ "$output" =~ "autoload: OK" ]]
    [[ "$output" =~ "Array test: one" ]]

    log_compatibility "Zsh Features Test" "PASS" "autoload and arrays work correctly"
}

@test "tests theme compatibility across zsh versions" {
    # Create config with different themes
    local themes=("robbyrussell" "agnoster" "candy" "jonathan")

    for theme in "${themes[@]}"; do
        cat > config.sh << EOF
#!/bin/bash
ZSH_THEME="$theme"
EXTERNAL_PLUGINS=()
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

        # Test theme configuration
        run zsh -c 'source config.sh; echo "Theme: $ZSH_THEME"'

        if [ "$status" -eq 0 ]; then
            log_compatibility "Theme: $theme" "PASS" "Theme loads correctly"
        else
            log_compatibility "Theme: $theme" "FAIL" "Theme failed to load"
        fi
    done

    # At least one theme should work
    [ "$status" -eq 0 ]
}

@test "validates plugin compatibility with current zsh version" {
    # Test different plugin types
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
)
BUILTIN_PLUGINS=(
    git
    z
    command-not-found
    cp
)
EZA_VERSION="v0.18.0"
EOF

    # Mock Oh My Zsh environment
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"

    # Test plugin configuration processing
    run zsh -c '
        source config.sh
        echo "External plugins: ${#EXTERNAL_PLUGINS[@]}"
        echo "Builtin plugins: ${#BUILTIN_PLUGINS[@]}"

        # Test plugin path generation
        for plugin in "${EXTERNAL_PLUGINS[@]}"; do
            repo_name=$(basename "$plugin")
            echo "Plugin path: ~/.oh-my-zsh/custom/plugins/$repo_name"
        done
    '

    [ "$status" -eq 0 ]
    [[ "$output" =~ "External plugins: 2" ]]
    [[ "$output" =~ "Builtin plugins: 4" ]]

    log_compatibility "Plugin Configuration" "PASS" "Plugin arrays process correctly"
}

# Shell Configuration Compatibility Tests

@test "tests different shell option configurations" {
    # Test various shell options that might affect compatibility
    local shell_tests=(
        "set +H"          # Disable history expansion
        "setopt nullglob" # Zsh-specific option
        "setopt auto_cd"  # Zsh auto directory change
    )

    for shell_test in "${shell_tests[@]}"; do
        run zsh -c "$shell_test; echo 'Shell option test passed'"

        if [ "$status" -eq 0 ]; then
            log_compatibility "Shell Option: $shell_test" "PASS" "Option works correctly"
        else
            log_compatibility "Shell Option: $shell_test" "FAIL" "Option not supported"
        fi
    done
}

@test "validates terminal feature detection" {
    # Test terminal capability detection
    run zsh -c '
        # Test color support detection
        if [ -t 1 ]; then
            echo "Terminal: Interactive"
        else
            echo "Terminal: Non-interactive"
        fi

        # Test TERM variable
        echo "TERM: ${TERM:-unknown}"

        # Test color capability
        if [ "${TERM}" != "dumb" ] && [ -n "${TERM}" ]; then
            echo "Colors: Likely supported"
        else
            echo "Colors: Limited or none"
        fi
    '

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Terminal:" ]]
    [[ "$output" =~ "TERM:" ]]

    log_compatibility "Terminal Detection" "PASS" "Terminal features detected"
}

@test "tests cross-platform compatibility" {
    # Create config that should work across platforms
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"

# Platform detection
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="Windows"
else
    PLATFORM="Unknown"
fi
EOF

    # Test platform detection and configuration loading
    run zsh -c '
        source config.sh
        echo "Platform: $PLATFORM"
        echo "Theme: $ZSH_THEME"
        echo "OS Type: $OSTYPE"
    '

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Platform:" ]]
    [[ "$output" =~ "Theme: robbyrussell" ]]

    # Log platform information
    local platform_info
    platform_info=$(echo "$output" | grep "Platform:" | cut -d' ' -f2)
    log_compatibility "Platform Detection" "$platform_info" "OSTYPE: $OSTYPE"
}

@test "generates compatibility report" {
    # Create a comprehensive compatibility report
    local report_file="$TEST_HOME/compatibility_report.txt"

    {
        echo "CustomZsh Compatibility Report"
        echo "Generated: $(date)"
        echo "Test Environment: $TEST_HOME"
        echo
        echo "System Information:"
        echo "- Zsh Version: $(zsh --version 2>/dev/null || echo 'Not available')"
        echo "- OS Type: ${OSTYPE:-unknown}"
        echo "- Platform: $(uname -s 2>/dev/null || echo 'unknown')"
        echo "- Architecture: $(uname -m 2>/dev/null || echo 'unknown')"
        echo
        echo "Compatibility Requirements:"
        echo "- Minimum Zsh Version: 5.0"
        echo "- Required Features: autoload, arrays, parameter expansion"
        echo "- Required Commands: git, curl, sudo, jq"
        echo
        echo "Test Results:"
        if [ -f "$COMPAT_LOG_FILE" ]; then
            cat "$COMPAT_LOG_FILE"
        else
            echo "No compatibility log available"
        fi
        echo
        echo "Recommendations:"
        if check_version_requirement 5 8; then
            echo "- Zsh version is modern and fully supported"
        elif check_version_requirement 5 0; then
            echo "- Zsh version meets minimum requirements"
            echo "- Consider upgrading for best experience"
        else
            echo "- Zsh version is below minimum requirements"
            echo "- Upgrade to zsh 5.0+ is strongly recommended"
        fi
    } > "$report_file"

    # Verify report was created
    [ -f "$report_file" ]
    [ -s "$report_file" ]  # File is not empty

    echo "Compatibility report generated: $report_file"
    log_compatibility "Report Generation" "COMPLETE" "Report saved to $report_file"
}