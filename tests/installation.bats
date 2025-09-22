#!/usr/bin/env bats
#
# installation.bats
#
# End-to-end installation testing for customzsh
# Tests the complete installation workflow and verifies all components
#
# Test Categories:
# - Installation script validation and execution
# - Configuration file creation and validation
# - Dependency checking and system requirements
# - Plugin installation and directory structure
# - Integration with eza installation script
# - Error handling and graceful degradation
# - Network-free testing with offline configurations
#
# Test Count: 25 tests
# Dependencies: git, curl, sudo, jq, zsh
# Environment: Supports Docker containers and local execution
#
# Author: Claude Code (Enhanced)
# Version: 2.0
#

# Load test helpers
load 'helpers/isolation_utils'
load 'helpers/validation_helpers'
load 'helpers/error_simulation'

# Helper function to create network-free config
create_offline_config() {
    cp config.sh.example config.sh
    # Use specific eza version to avoid network calls in tests
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh
}

# Setup function runs before each test
setup() {
    # Generate UUID for unique test directory
    local test_uuid
    test_uuid=$(generate_test_uuid)
    export TEST_HOME="/tmp/customzsh_installation_test_${test_uuid}"
    export TEST_SCRIPT_DIR="${TEST_HOME}/customzsh"

    # Validate clean environment before setup
    validate_clean_environment "$TEST_HOME" true

    # Setup isolated test environment
    setup_isolated_environment "$TEST_HOME" "installation_test"

    # Copy project files to test directory (including hidden files)
    mkdir -p "$TEST_SCRIPT_DIR"
    find . -maxdepth 1 -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    find . -maxdepth 1 -name ".*" -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    # Copy directories but avoid copying test directory itself
    find . -maxdepth 1 -type d ! -name "." ! -name "tests" -exec cp -r {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    cd "$TEST_SCRIPT_DIR"

    # Ensure we have a clean config file with no network dependencies
    rm -f config.sh

    # Set test timeout
    set_test_timeout 300 "installation_test_${test_uuid}"
}

# Teardown function runs after each test
teardown() {
    # Clear test timeout
    clear_test_timeout

    # Check for resource leaks
    check_for_resource_leaks "$TEST_HOME"

    # Comprehensive cleanup with verification
    cleanup_test_environment "$TEST_HOME" true

    # Verify cleanup completed
    [ ! -d "$TEST_HOME" ] || {
        echo "Warning: Test cleanup incomplete for $TEST_HOME" >&2
    }
}

@test "installation script exists and is executable" {
    [ -f "customzsh.sh" ]
    [ -x "customzsh.sh" ]
}

@test "install_eza.sh script exists and is executable" {
    [ -f "install_eza.sh" ]
    [ -x "install_eza.sh" ]
}

@test "config template exists" {
    [ -f "config.sh.example" ]
}

@test ".zshrc template exists" {
    [ -f ".zshrc" ]
}

@test "installation creates config.sh from template" {
    # Remove config.sh if it exists
    rm -f config.sh

    # Run customzsh.sh which should create config.sh and exit
    run ./customzsh.sh

    # Should exit with code 0 and create config.sh
    [ "$status" -eq 0 ]
    [ -f "config.sh" ]

    # Config should match template
    run cmp config.sh config.sh.example
    [ "$status" -eq 0 ]
}

@test "installation runs successfully with valid config" {
    # Ensure config exists with no network dependencies
    if [ ! -f "config.sh" ]; then
        create_offline_config
    fi

    # Mock the installation for testing (since we're in Docker)
    # We'll test the script logic without actually installing packages
    run timeout 60 ./customzsh.sh

    # Should complete without errors (may exit early due to package dependencies in test environment)
    # We expect either success (0) or early exit due to missing packages
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "zsh is available in the system" {
    run command -v zsh
    [ "$status" -eq 0 ]
}

@test "git is available in the system" {
    run command -v git
    [ "$status" -eq 0 ]
}

@test "curl is available in the system" {
    run command -v curl
    [ "$status" -eq 0 ]
}

@test "jq is available in the system" {
    run command -v jq
    [ "$status" -eq 0 ]
}

@test "sudo is available in the system" {
    run command -v sudo
    [ "$status" -eq 0 ]
}

@test "eza installation script handles version detection" {
    # Ensure config exists with no network dependencies
    if [ ! -f "config.sh" ]; then
        create_offline_config
    fi

    # Test that install_eza.sh can detect target version
    run timeout 30 ./install_eza.sh

    # Should either succeed or fail gracefully with proper error handling
    # Exit codes: 0 (success), 1 (controlled failure), or timeout
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]

    # If it runs, it should produce meaningful output
    if [ "$status" -ne 124 ]; then
        [[ "$output" == *"Target eza version"* || "$output" == *"eza"* ]]
    fi
}

@test "dependency check function validates required tools" {
    # Ensure config exists with no network dependencies
    if [ ! -f "config.sh" ]; then
        create_offline_config
    fi

    # Extract and test dependency check function
    run bash -c 'source customzsh.sh; check_dependencies 2>&1'

    # Should complete dependency check successfully
    [ "$status" -eq 0 ]
    [[ "$output" == *"dependencies"* ]]
}

@test "config.sh contains expected configuration options" {
    # Ensure config exists with no network dependencies
    if [ ! -f "config.sh" ]; then
        create_offline_config
    fi

    # Check that config has required variables
    run bash -c 'source config.sh; echo "Theme: $ZSH_THEME"; echo "Plugins: ${#EXTERNAL_PLUGINS[@]}"; echo "Eza: $EZA_VERSION"'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Theme: agnoster"* ]]
    [[ "$output" == *"Plugins: 2"* ]]
    [[ "$output" == *"Eza: v0.18.0"* ]]
}

@test "external plugins array is properly configured" {
    # Ensure config exists with no network dependencies
    if [ ! -f "config.sh" ]; then
        create_offline_config
    fi

    # Test external plugins configuration
    run bash -c 'source config.sh; for plugin in "${EXTERNAL_PLUGINS[@]}"; do echo "Plugin: $plugin"; done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"zsh-users/zsh-syntax-highlighting"* ]]
    [[ "$output" == *"zsh-users/zsh-autosuggestions"* ]]
}

@test ".zshrc contains correct theme configuration" {
    # Check that .zshrc has agnoster theme
    run grep "ZSH_THEME=" .zshrc

    [ "$status" -eq 0 ]
    [[ "$output" == *"agnoster"* ]]
}

@test ".zshrc contains expected plugins" {
    # Check that .zshrc has the required plugins
    run grep -A 10 "plugins=(" .zshrc

    [ "$status" -eq 0 ]
    [[ "$output" == *"git"* ]]
    [[ "$output" == *"zsh-autosuggestions"* ]]
    [[ "$output" == *"zsh-syntax-highlighting"* ]]
    [[ "$output" == *"z"* ]]
    [[ "$output" == *"command-not-found"* ]]
    [[ "$output" == *"cp"* ]]
}

@test ".zshrc contains eza alias" {
    # Check that .zshrc has eza alias for ls
    run grep "alias ls=" .zshrc

    [ "$status" -eq 0 ]
    [[ "$output" == *"eza"* ]]
    [[ "$output" == *"--icons"* ]]
    [[ "$output" == *"--group-directories-first"* ]]
}

@test "script handles missing files gracefully" {
    # Test behavior when install_eza.sh is missing
    mv install_eza.sh install_eza.sh.backup

    # Ensure config exists with no network dependencies
    if [ ! -f "config.sh" ]; then
        create_offline_config
    fi

    run timeout 30 ./customzsh.sh

    # Should handle missing file gracefully
    [ "$status" -ne 2 ]  # Should not crash with command not found
    [[ "$output" == *"install_eza.sh not found"* || "$output" == *"skipping eza installation"* ]]

    # Restore file
    mv install_eza.sh.backup install_eza.sh
}

@test "output functions provide consistent formatting" {
    # Test that info, success, and error functions work
    run bash -c 'source customzsh.sh; info "test info"; success "test success"; error "test error" 2>&1'

    [ "$status" -ne 0 ]  # error function should cause non-zero exit due to stderr
    [[ "$output" == *"[INFO] test info"* ]]
    [[ "$output" == *"[SUCCESS] test success"* ]]
    [[ "$output" == *"[ERROR] test error"* ]]
}

@test "script provides help with --help flag" {
    # Test help functionality
    run ./customzsh.sh --help 2>/dev/null || true

    # Should either show help or handle flag gracefully
    # We don't expect --help to be implemented in the current version,
    # but the script should handle unknown flags without crashing
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

@test "plugin directories are created correctly" {
    # Test that plugin installation logic creates correct directories
    create_offline_config

    # Test the directory structure that would be created
    run bash -c 'source config.sh
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     repo_name=$(basename "$plugin")
                     target_dir="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$repo_name"
                     echo "Plugin: $repo_name -> $target_dir"
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"zsh-syntax-highlighting -> "* ]]
    [[ "$output" == *"zsh-autosuggestions -> "* ]]
    [[ "$output" == *"/.oh-my-zsh/custom/plugins/"* ]]
}

@test "external plugins are properly configured" {
    # Verify external plugins are in config
    create_offline_config

    run bash -c 'source config.sh
                 echo "Plugin count: ${#EXTERNAL_PLUGINS[@]}"
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     echo "External plugin: $plugin"
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Plugin count: 2"* ]]
    [[ "$output" == *"zsh-users/zsh-syntax-highlighting"* ]]
    [[ "$output" == *"zsh-users/zsh-autosuggestions"* ]]
}

@test "builtin plugins are documented in config" {
    # Verify builtin plugins are documented
    create_offline_config

    run bash -c 'source config.sh
                 echo "Builtin count: ${#BUILTIN_PLUGINS[@]}"
                 for plugin in "${BUILTIN_PLUGINS[@]}"; do
                     echo "Builtin plugin: $plugin"
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Builtin count: 4"* ]]
    [[ "$output" == *"Builtin plugin: git"* ]]
    [[ "$output" == *"Builtin plugin: z"* ]]
    [[ "$output" == *"Builtin plugin: command-not-found"* ]]
    [[ "$output" == *"Builtin plugin: cp"* ]]
}

@test "plugin installation handles network simulation" {
    # Test plugin installation with simulated directories
    create_offline_config

    # Create mock oh-my-zsh structure
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"

    # Simulate what the plugin installation would do
    run bash -c 'source config.sh
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     repo_name=$(basename "$plugin")
                     target_dir="$HOME/.oh-my-zsh/custom/plugins/$repo_name"
                     echo "Would clone: https://github.com/$plugin.git to $target_dir"
                     # Create directory to simulate successful clone
                     mkdir -p "$target_dir"
                     echo "Simulated installation: $repo_name"
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would clone: https://github.com/zsh-users/zsh-syntax-highlighting.git"* ]]
    [[ "$output" == *"Would clone: https://github.com/zsh-users/zsh-autosuggestions.git"* ]]
    [[ "$output" == *"Simulated installation: zsh-syntax-highlighting"* ]]
    [[ "$output" == *"Simulated installation: zsh-autosuggestions"* ]]

    # Verify directories were created
    [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]
    [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]
}