#!/bin/bash
#
# validation_helpers.bash
#
# Validation utilities for customzsh test suite
# Provides functions for validating installations, configurations,
# and test results with comprehensive checks
#
# Functions:
# - validate_installation_completeness(): Check installation completion
# - validate_plugin_installation(): Verify plugin installation
# - validate_configuration_format(): Check config file format
# - validate_zshrc_content(): Verify .zshrc modifications
# - validate_backup_integrity(): Check backup file integrity
# - validate_uninstall_completeness(): Verify complete uninstallation
# - validate_dependency_availability(): Check required dependencies
#
# Author: Claude Code
# Version: 1.0
#

# Validate installation completeness
validate_installation_completeness() {
    local test_home="${1:-$HOME}"
    local config_file="${2:-$test_home/config.sh}"

    local validation_errors=()

    # Check Oh My Zsh installation
    if [ ! -d "$test_home/.oh-my-zsh" ]; then
        validation_errors+=("Oh My Zsh directory not found: $test_home/.oh-my-zsh")
    elif [ ! -f "$test_home/.oh-my-zsh/oh-my-zsh.sh" ]; then
        validation_errors+=("Oh My Zsh main script not found: $test_home/.oh-my-zsh/oh-my-zsh.sh")
    fi

    # Check .zshrc creation
    if [ ! -f "$test_home/.zshrc" ]; then
        validation_errors+=(".zshrc file not found: $test_home/.zshrc")
    fi

    # Validate config file existence and loading
    if [ ! -f "$config_file" ]; then
        validation_errors+=("Configuration file not found: $config_file")
    else
        # Source config and validate required variables
        source "$config_file" 2>/dev/null || {
            validation_errors+=("Configuration file has syntax errors: $config_file")
        }

        # Check required configuration variables
        [ -z "$ZSH_THEME" ] && validation_errors+=("ZSH_THEME not set in config")
        [ -z "$EXTERNAL_PLUGINS" ] && validation_errors+=("EXTERNAL_PLUGINS not defined in config")
        [ -z "$BUILTIN_PLUGINS" ] && validation_errors+=("BUILTIN_PLUGINS not defined in config")
        [ -z "$EZA_VERSION" ] && validation_errors+=("EZA_VERSION not set in config")
    fi

    # Check backup creation
    if [ -f "$test_home/.zshrc.pre-customzsh" ]; then
        echo "Backup file found: $test_home/.zshrc.pre-customzsh"
    else
        # Only error if there was an existing .zshrc to backup
        if [ -f "$test_home/.zshrc.original" ]; then
            validation_errors+=("Backup file not created despite existing .zshrc")
        fi
    fi

    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo "Installation validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    else
        echo "Installation validation passed"
        return 0
    fi
}

# Validate plugin installation
validate_plugin_installation() {
    local test_home="${1:-$HOME}"
    local expected_plugins="$2"

    [ -z "$expected_plugins" ] && {
        echo "Error: expected_plugins parameter required" >&2
        return 1
    }

    local validation_errors=()
    local plugins_dir="$test_home/.oh-my-zsh/custom/plugins"

    # Check custom plugins directory
    if [ ! -d "$plugins_dir" ]; then
        validation_errors+=("Custom plugins directory not found: $plugins_dir")
        echo "Plugin validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    fi

    # Validate each expected plugin
    for plugin in $expected_plugins; do
        local plugin_name
        plugin_name=$(basename "$plugin")
        local plugin_dir="$plugins_dir/$plugin_name"

        if [ ! -d "$plugin_dir" ]; then
            validation_errors+=("Plugin directory not found: $plugin_dir")
            continue
        fi

        # Check for plugin main file
        local plugin_main_file="$plugin_dir/$plugin_name.plugin.zsh"
        if [ ! -f "$plugin_main_file" ]; then
            # Some plugins might have different main file names
            local alt_files
            alt_files=$(find "$plugin_dir" -name "*.plugin.zsh" -o -name "*.zsh" -o -name "$plugin_name.sh" 2>/dev/null)
            if [ -z "$alt_files" ]; then
                validation_errors+=("Plugin main file not found for: $plugin_name")
            fi
        fi

        # Check if plugin is enabled in .zshrc
        if [ -f "$test_home/.zshrc" ]; then
            if ! grep -q "$plugin_name" "$test_home/.zshrc"; then
                validation_errors+=("Plugin not enabled in .zshrc: $plugin_name")
            fi
        fi

        echo "Plugin validated: $plugin_name"
    done

    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo "Plugin validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    else
        echo "Plugin validation passed for all plugins"
        return 0
    fi
}

# Validate configuration file format
validate_configuration_format() {
    local config_file="${1:-config.sh}"

    [ ! -f "$config_file" ] && {
        echo "Configuration file not found: $config_file" >&2
        return 1
    }

    local validation_errors=()

    # Check if file can be sourced
    if ! bash -n "$config_file" 2>/dev/null; then
        validation_errors+=("Configuration file has syntax errors")
    fi

    # Validate variable assignments
    local zsh_theme_check
    zsh_theme_check=$(grep "^ZSH_THEME=" "$config_file" || true)
    if [ -z "$zsh_theme_check" ]; then
        validation_errors+=("ZSH_THEME assignment not found")
    elif [[ ! "$zsh_theme_check" =~ ^ZSH_THEME=\".*\"$ ]]; then
        validation_errors+=("ZSH_THEME format is invalid (should be quoted)")
    fi

    # Validate array declarations
    if ! grep -q "^EXTERNAL_PLUGINS=(" "$config_file"; then
        validation_errors+=("EXTERNAL_PLUGINS array declaration not found")
    fi

    if ! grep -q "^BUILTIN_PLUGINS=(" "$config_file"; then
        validation_errors+=("BUILTIN_PLUGINS array declaration not found")
    fi

    # Check for proper array closing
    local external_plugins_lines
    external_plugins_lines=$(sed -n '/^EXTERNAL_PLUGINS=(/,/^)/p' "$config_file")
    if [ -z "$external_plugins_lines" ]; then
        validation_errors+=("EXTERNAL_PLUGINS array not properly closed")
    fi

    # Validate EZA_VERSION format
    local eza_version_check
    eza_version_check=$(grep "^EZA_VERSION=" "$config_file" || true)
    if [ -z "$eza_version_check" ]; then
        validation_errors+=("EZA_VERSION assignment not found")
    elif [[ ! "$eza_version_check" =~ ^EZA_VERSION=\".*\"$ ]]; then
        validation_errors+=("EZA_VERSION format is invalid (should be quoted)")
    fi

    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo "Configuration format validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    else
        echo "Configuration format validation passed"
        return 0
    fi
}

# Validate .zshrc content
validate_zshrc_content() {
    local zshrc_file="${1:-$HOME/.zshrc}"
    local expected_theme="${2:-robbyrussell}"
    local expected_plugins="$3"

    [ ! -f "$zshrc_file" ] && {
        echo ".zshrc file not found: $zshrc_file" >&2
        return 1
    }

    local validation_errors=()

    # Check Oh My Zsh path
    if ! grep -q "export ZSH=" "$zshrc_file"; then
        validation_errors+=("ZSH path export not found in .zshrc")
    fi

    # Check theme setting
    local theme_line
    theme_line=$(grep "^ZSH_THEME=" "$zshrc_file" || true)
    if [ -z "$theme_line" ]; then
        validation_errors+=("ZSH_THEME not set in .zshrc")
    elif [[ ! "$theme_line" =~ ZSH_THEME=\"$expected_theme\" ]]; then
        validation_errors+=("ZSH_THEME mismatch in .zshrc (expected: $expected_theme)")
    fi

    # Check plugins array
    if ! grep -q "^plugins=(" "$zshrc_file"; then
        validation_errors+=("plugins array not found in .zshrc")
    fi

    # Validate specific plugins if provided
    if [ -n "$expected_plugins" ]; then
        for plugin in $expected_plugins; do
            if ! grep -A10 "^plugins=(" "$zshrc_file" | grep -q "$plugin"; then
                validation_errors+=("Plugin not found in .zshrc: $plugin")
            fi
        done
    fi

    # Check Oh My Zsh source line
    if ! grep -q "source \$ZSH/oh-my-zsh.sh" "$zshrc_file"; then
        validation_errors+=("Oh My Zsh source line not found in .zshrc")
    fi

    # Check for eza alias if eza is configured
    if command -v eza >/dev/null 2>&1; then
        if ! grep -q "alias ls.*eza" "$zshrc_file"; then
            validation_errors+=("eza alias not found in .zshrc despite eza being installed")
        fi
    fi

    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo ".zshrc content validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    else
        echo ".zshrc content validation passed"
        return 0
    fi
}

# Validate backup integrity
validate_backup_integrity() {
    local backup_file="${1:-$HOME/.zshrc.pre-customzsh}"
    local original_file="${2:-$HOME/.zshrc.original}"

    [ ! -f "$backup_file" ] && {
        echo "Backup file not found: $backup_file" >&2
        return 1
    }

    local validation_errors=()

    # Check if backup is not empty
    if [ ! -s "$backup_file" ]; then
        validation_errors+=("Backup file is empty: $backup_file")
    fi

    # If original file is provided, compare content
    if [ -f "$original_file" ]; then
        if ! diff -q "$backup_file" "$original_file" >/dev/null 2>&1; then
            validation_errors+=("Backup content doesn't match original file")
        fi
    fi

    # Check backup file permissions
    local backup_perms
    backup_perms=$(stat -c %a "$backup_file" 2>/dev/null || stat -f %A "$backup_file" 2>/dev/null)
    if [[ ! "$backup_perms" =~ ^6[0-7][0-7]$ ]]; then
        validation_errors+=("Backup file permissions may be incorrect: $backup_perms")
    fi

    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo "Backup integrity validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    else
        echo "Backup integrity validation passed"
        return 0
    fi
}

# Validate uninstall completeness
validate_uninstall_completeness() {
    local test_home="${1:-$HOME}"
    local check_backups="${2:-true}"

    local validation_errors=()

    # Check that Oh My Zsh directory is removed
    if [ -d "$test_home/.oh-my-zsh" ]; then
        validation_errors+=("Oh My Zsh directory still exists: $test_home/.oh-my-zsh")
    fi

    # Check that customzsh .zshrc is removed
    if [ -f "$test_home/.zshrc" ]; then
        # Check if it's still a customzsh .zshrc (contains Oh My Zsh references)
        if grep -q "oh-my-zsh" "$test_home/.zshrc" 2>/dev/null; then
            validation_errors+=("customzsh .zshrc still exists: $test_home/.zshrc")
        fi
    fi

    # Check that config.sh is removed or restored
    if [ -f "$test_home/config.sh" ]; then
        validation_errors+=("config.sh file still exists: $test_home/config.sh")
    fi

    # If checking backups, verify backup files are handled
    if [ "$check_backups" = true ]; then
        if [ -f "$test_home/.zshrc.pre-customzsh" ]; then
            echo "Backup file preserved: $test_home/.zshrc.pre-customzsh"
        fi
    fi

    # Check for leftover customzsh artifacts
    local leftover_files
    leftover_files=$(find "$test_home" -name "*customzsh*" -type f 2>/dev/null || true)
    if [ -n "$leftover_files" ]; then
        validation_errors+=("Leftover customzsh files found:")
        echo "$leftover_files" | while read -r file; do
            validation_errors+=("  - $file")
        done
    fi

    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo "Uninstall validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    else
        echo "Uninstall validation passed"
        return 0
    fi
}

# Validate dependency availability
validate_dependency_availability() {
    local required_deps="${1:-git curl sudo jq}"
    local strict_mode="${2:-false}"

    local missing_deps=()
    local optional_missing=()

    # Check each required dependency
    for dep in $required_deps; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done

    # Check optional dependencies in strict mode
    if [ "$strict_mode" = true ]; then
        local optional_deps="wget tar gzip unzip"
        for dep in $optional_deps; do
            if ! command -v "$dep" >/dev/null 2>&1; then
                optional_missing+=("$dep")
            fi
        done
    fi

    # Report results
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Missing required dependencies:" >&2
        printf '%s\n' "${missing_deps[@]}" >&2
        return 1
    fi

    if [ ${#optional_missing[@]} -gt 0 ]; then
        echo "Missing optional dependencies:" >&2
        printf '%s\n' "${optional_missing[@]}" >&2
    fi

    echo "Dependency validation passed"
    return 0
}

# Validate eza installation
validate_eza_installation() {
    local expected_version="${1:-latest}"
    local installation_method="${2:-auto}"

    local validation_errors=()

    # Check if eza is installed
    if ! command -v eza >/dev/null 2>&1; then
        validation_errors+=("eza command not found in PATH")
        echo "eza installation validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    fi

    # Get installed version
    local installed_version
    installed_version=$(eza --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")

    # Validate version if not "latest"
    if [ "$expected_version" != "latest" ] && [ "$expected_version" != "unknown" ]; then
        if [[ ! "$installed_version" =~ $expected_version ]]; then
            validation_errors+=("eza version mismatch (expected: $expected_version, got: $installed_version)")
        fi
    fi

    # Check if eza works properly
    local test_output
    if ! test_output=$(eza --help 2>&1); then
        validation_errors+=("eza command execution failed")
    fi

    # Check if aliases are set up
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "eza" "$HOME/.zshrc"; then
            validation_errors+=("eza aliases not found in .zshrc")
        fi
    fi

    # Report validation results
    if [ ${#validation_errors[@]} -gt 0 ]; then
        echo "eza installation validation failed:" >&2
        printf '%s\n' "${validation_errors[@]}" >&2
        return 1
    else
        echo "eza installation validation passed (version: $installed_version)"
        return 0
    fi
}

# Validate file permissions
validate_file_permissions() {
    local file_path="$1"
    local expected_perms="$2"

    [ -z "$file_path" ] || [ -z "$expected_perms" ] && {
        echo "Error: file_path and expected_perms parameters required" >&2
        return 1
    }

    [ ! -e "$file_path" ] && {
        echo "File not found: $file_path" >&2
        return 1
    }

    local actual_perms
    actual_perms=$(stat -c %a "$file_path" 2>/dev/null || stat -f %A "$file_path" 2>/dev/null)

    if [ "$actual_perms" != "$expected_perms" ]; then
        echo "Permission mismatch for $file_path (expected: $expected_perms, got: $actual_perms)" >&2
        return 1
    else
        echo "File permissions validated: $file_path ($actual_perms)"
        return 0
    fi
}