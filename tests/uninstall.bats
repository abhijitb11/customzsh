#!/usr/bin/env bats
#
# uninstall.bats
#
# Complete removal testing for customzsh
# Tests the --uninstall functionality and system restoration
#
# Test Categories:
# - Uninstall flag recognition and processing
# - Complete Oh My Zsh removal and cleanup
# - Configuration file restoration and backup handling
# - Plugin directory cleanup and validation
# - System state restoration to pre-installation state
# - User data preservation during uninstall
# - Multiple uninstall run safety verification
#
# Test Count: 14 tests
# Dependencies: File system operations, backup restoration
# Environment: Enhanced isolation with backup verification
#
# Author: Claude Code (Enhanced)
# Version: 2.0
#

# Load test helpers
load 'helpers/isolation_utils'
load 'helpers/validation_helpers'
load 'helpers/error_simulation'

# Setup function runs before each test
setup() {
    # Generate UUID for unique test directory
    local test_uuid
    test_uuid=$(generate_test_uuid)
    export TEST_HOME="/tmp/customzsh_uninstall_test_${test_uuid}"
    export TEST_SCRIPT_DIR="${TEST_HOME}/customzsh"

    # Validate clean environment before setup
    validate_clean_environment "$TEST_HOME" true

    # Setup isolated test environment
    setup_isolated_environment "$TEST_HOME" "uninstall_test"

    # Copy project files to test directory (including hidden files)
    mkdir -p "$TEST_SCRIPT_DIR"
    find . -maxdepth 1 -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    find . -maxdepth 1 -name ".*" -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    # Copy directories but avoid copying test directory itself
    find . -maxdepth 1 -type d ! -name "." ! -name "tests" -exec cp -r {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    cd "$TEST_SCRIPT_DIR"

    # Ensure we have a clean config file with no network dependencies
    rm -f config.sh
    cp config.sh.example config.sh
    # Use specific eza version to avoid network calls in tests
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh

    # Set test timeout
    set_test_timeout 180 "uninstall_test_${test_uuid}"
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

@test "uninstall flag is recognized and processed" {
    # Test that --uninstall flag is recognized
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]
    [[ "$output" == *"Uninstalling"* || "$output" == *"uninstall"* ]]
}

@test "uninstall removes oh-my-zsh directory" {
    # Create fake oh-my-zsh installation
    mkdir -p "$HOME/.oh-my-zsh/themes"
    mkdir -p "$HOME/.oh-my-zsh/plugins"
    echo "test file" > "$HOME/.oh-my-zsh/test.txt"

    # Verify it exists
    [ -d "$HOME/.oh-my-zsh" ]

    # Run uninstall
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]
    # Oh My Zsh directory should be removed
    [ ! -d "$HOME/.oh-my-zsh" ]
}

@test "uninstall restores original .zshrc when backup exists" {
    # Create original .zshrc and backup
    echo "original zshrc content" > "$HOME/.zshrc.pre-customzsh"
    echo "customzsh modified content" > "$HOME/.zshrc"

    # Verify setup
    [ -f "$HOME/.zshrc.pre-customzsh" ]
    [ -f "$HOME/.zshrc" ]
    [ "$(cat "$HOME/.zshrc")" = "customzsh modified content" ]

    # Run uninstall
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]
    # Original .zshrc should be restored
    [ -f "$HOME/.zshrc" ]
    [ "$(cat "$HOME/.zshrc")" = "original zshrc content" ]
    # Backup should be removed (since it was restored)
    [ ! -f "$HOME/.zshrc.pre-customzsh" ]
}

@test "uninstall handles missing backup gracefully" {
    # Create only current .zshrc (no backup)
    echo "current zshrc content" > "$HOME/.zshrc"

    # Verify no backup exists
    [ ! -f "$HOME/.zshrc.pre-customzsh" ]

    # Run uninstall
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]
    [[ "$output" == *"No .zshrc backup found"* || "$output" == *"backup"* ]]
}

@test "uninstall handles missing oh-my-zsh gracefully" {
    # Ensure oh-my-zsh doesn't exist
    [ ! -d "$HOME/.oh-my-zsh" ]

    # Run uninstall
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]
    # Should complete without errors even if nothing to remove
    [[ "$output" == *"Uninstalling"* ]]
}

@test "uninstall function can be called directly" {
    # Test that uninstall function works when called directly
    run bash -c 'source customzsh.sh; uninstall'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Uninstalling"* ]]
}

@test "complete install then uninstall cycle" {
    # Simulate a complete installation
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    mkdir -p "$HOME/.oh-my-zsh/themes"

    # Create original .zshrc and simulate customzsh installation
    echo "original user zshrc" > "$HOME/.zshrc.pre-customzsh"
    # .zshrc already exists from setup, representing installed state

    # Verify installation state
    [ -d "$HOME/.oh-my-zsh" ]
    [ -f "$HOME/.zshrc" ]
    [ -f "$HOME/.zshrc.pre-customzsh" ]

    # Run uninstall
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]

    # Verify complete removal
    [ ! -d "$HOME/.oh-my-zsh" ]
    [ -f "$HOME/.zshrc" ]
    [ "$(cat "$HOME/.zshrc")" = "original user zshrc" ]
    [ ! -f "$HOME/.zshrc.pre-customzsh" ]

    [[ "$output" == *"Uninstallation complete"* ]]
}

@test "uninstall preserves user files outside customzsh scope" {
    # Create user files that should not be touched
    echo "user file 1" > "$HOME/user_file.txt"
    mkdir -p "$HOME/user_directory"
    echo "user file 2" > "$HOME/user_directory/file.txt"

    # Create customzsh installation
    mkdir -p "$HOME/.oh-my-zsh"
    echo "original" > "$HOME/.zshrc.pre-customzsh"
    echo "modified" > "$HOME/.zshrc"

    # Run uninstall
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]

    # User files should be preserved
    [ -f "$HOME/user_file.txt" ]
    [ "$(cat "$HOME/user_file.txt")" = "user file 1" ]
    [ -d "$HOME/user_directory" ]
    [ -f "$HOME/user_directory/file.txt" ]
    [ "$(cat "$HOME/user_directory/file.txt")" = "user file 2" ]
}

@test "uninstall removes custom plugin directories" {
    # Create custom plugin directories with content
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/custom-plugin"

    echo "plugin file" > "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/test.zsh"
    echo "another file" > "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/test.zsh"

    # Verify plugins exist
    [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]
    [ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]

    # Run uninstall
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]

    # All plugin directories should be removed with oh-my-zsh
    [ ! -d "$HOME/.oh-my-zsh" ]
}

@test "uninstall output provides clear feedback" {
    # Create installation state
    mkdir -p "$HOME/.oh-my-zsh"
    echo "original" > "$HOME/.zshrc.pre-customzsh"
    echo "modified" > "$HOME/.zshrc"

    # Run uninstall and capture output
    run ./customzsh.sh --uninstall

    [ "$status" -eq 0 ]

    # Should provide informative output
    [[ "$output" == *"Uninstalling"* ]]
    [[ "$output" == *"removing"* || "$output" == *"removed"* || "$output" == *"Removing"* ]]
    [[ "$output" == *"Restoring"* || "$output" == *"restored"* ]]
    [[ "$output" == *"complete"* ]]
}

@test "uninstall works with different oh-my-zsh structures" {
    # Test with minimal oh-my-zsh structure
    mkdir -p "$HOME/.oh-my-zsh"
    run ./customzsh.sh --uninstall
    [ "$status" -eq 0 ]
    [ ! -d "$HOME/.oh-my-zsh" ]

    # Test with full oh-my-zsh structure
    mkdir -p "$HOME/.oh-my-zsh/themes"
    mkdir -p "$HOME/.oh-my-zsh/plugins"
    mkdir -p "$HOME/.oh-my-zsh/custom/themes"
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$HOME/.oh-my-zsh/lib"
    mkdir -p "$HOME/.oh-my-zsh/tools"

    run ./customzsh.sh --uninstall
    [ "$status" -eq 0 ]
    [ ! -d "$HOME/.oh-my-zsh" ]
}

@test "uninstall handles permission issues gracefully" {
    # Create oh-my-zsh directory
    mkdir -p "$HOME/.oh-my-zsh/test"

    # Make a subdirectory read-only to simulate permission issues
    chmod 444 "$HOME/.oh-my-zsh/test" 2>/dev/null || true

    # Run uninstall (should handle permission issues)
    run ./customzsh.sh --uninstall

    # Should either succeed or fail gracefully
    [[ "$status" -eq 0 || "$status" -eq 1 ]]

    # Directory should be removed if possible, or script should report issue
    if [ "$status" -eq 0 ]; then
        [ ! -d "$HOME/.oh-my-zsh" ]
    fi
}

@test "multiple uninstall runs are safe" {
    # Create installation
    mkdir -p "$HOME/.oh-my-zsh"
    echo "original" > "$HOME/.zshrc.pre-customzsh"
    echo "modified" > "$HOME/.zshrc"

    # First uninstall
    run ./customzsh.sh --uninstall
    [ "$status" -eq 0 ]

    # Second uninstall should be safe (nothing to remove)
    run ./customzsh.sh --uninstall
    [ "$status" -eq 0 ]

    # Third uninstall should still be safe
    run ./customzsh.sh --uninstall
    [ "$status" -eq 0 ]
}

@test "uninstall validation after successful removal" {
    # Create full installation state
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    echo "original content" > "$HOME/.zshrc.pre-customzsh"
    # .zshrc already exists from setup

    # Run uninstall
    run ./customzsh.sh --uninstall
    [ "$status" -eq 0 ]

    # Comprehensive validation of clean state
    [ ! -d "$HOME/.oh-my-zsh" ]
    [ ! -f "$HOME/.zshrc.pre-customzsh" ]
    [ -f "$HOME/.zshrc" ]
    [ "$(cat "$HOME/.zshrc")" = "original content" ]

    # Verify no remnants of plugins
    [ ! -d "$HOME/.oh-my-zsh/custom" ]
    [ ! -d "$HOME/.oh-my-zsh/plugins" ]
}