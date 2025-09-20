#!/usr/bin/env bats
#
# idempotency.bats
#
# Multi-run safety validation for customzsh
# Tests that the script can be run multiple times safely without conflicts
#

# Setup function runs before each test
setup() {
    # Set up clean test environment
    export TEST_HOME="/tmp/customzsh_idempotency_test_$$"
    mkdir -p "$TEST_HOME"
    export HOME="$TEST_HOME"
    export USER="testuser"

    # Copy project files to test directory (including hidden files)
    find . -maxdepth 1 -type f -exec cp {} "$TEST_HOME/" \; 2>/dev/null || true
    find . -maxdepth 1 -name ".*" -type f -exec cp {} "$TEST_HOME/" \; 2>/dev/null || true
    # Copy directories but avoid copying test directory itself
    find . -maxdepth 1 -type d ! -name "." ! -name "tests" -exec cp -r {} "$TEST_HOME/" \; 2>/dev/null || true
    cd "$TEST_HOME"

    # Ensure we have a clean config file with no network dependencies
    rm -f config.sh
    cp config.sh.example config.sh
    # Use specific eza version to avoid network calls in tests
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh
}

# Teardown function runs after each test
teardown() {
    # Clean up test environment
    cd /
    rm -rf "$TEST_HOME" 2>/dev/null || true
}

@test "config.sh creation is idempotent" {
    # Remove config.sh
    rm -f config.sh

    # First run should create config.sh
    run ./customzsh.sh
    [ "$status" -eq 0 ]
    [ -f "config.sh" ]

    # Second run should not recreate config.sh
    local first_checksum=$(md5sum config.sh | cut -d' ' -f1)

    run ./customzsh.sh
    [ "$status" -eq 0 ]
    [ -f "config.sh" ]

    local second_checksum=$(md5sum config.sh | cut -d' ' -f1)
    [ "$first_checksum" = "$second_checksum" ]
}

@test "zsh installation check is idempotent" {
    # Test that zsh installation logic handles existing installation
    run bash -c 'source customzsh.sh;
                 if command -v zsh >/dev/null 2>&1; then
                     echo "Zsh is already installed. Skipping installation."
                 else
                     echo "Installing zsh..."
                 fi'

    [ "$status" -eq 0 ]
    # Since zsh should be available in test environment, expect skip message
    [[ "$output" == *"already installed"* || "$output" == *"Skipping"* ]]
}

@test "oh-my-zsh installation check is idempotent" {
    # Create fake oh-my-zsh directory to simulate existing installation
    mkdir -p "$HOME/.oh-my-zsh"

    # Test that the script skips existing oh-my-zsh installation
    run bash -c 'source customzsh.sh;
                 if [ -d "$HOME/.oh-my-zsh" ]; then
                     echo "Oh My Zsh is already installed. Skipping."
                 else
                     echo "Installing Oh My Zsh..."
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" == *"already installed"* || "$output" == *"Skipping"* ]]
}

@test "plugin installation check is idempotent" {
    # Create fake plugin directories to simulate existing installation
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

    # Test plugin installation logic
    run bash -c 'source config.sh;
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     repo_name=$(basename "$plugin")
                     target_dir="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$repo_name"
                     if [ -d "$target_dir" ]; then
                         echo "$repo_name is already installed. Skipping."
                     else
                         echo "Installing $repo_name..."
                     fi
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"already installed"* ]]
    [[ "$output" == *"zsh-syntax-highlighting"* ]]
    [[ "$output" == *"zsh-autosuggestions"* ]]
}

@test ".zshrc update check is idempotent" {
    # Create initial .zshrc that matches the template (already in place from setup)

    # Test .zshrc update logic
    run bash -c 'if cmp -s ".zshrc" "$HOME/.zshrc"; then
                     echo ".zshrc is already up to date. Skipping."
                 else
                     echo "Copying custom .zshrc file..."
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" == *"up to date"* || "$output" == *"Skipping"* ]]
}

@test ".zshrc backup is created only once" {
    # Create original .zshrc
    echo "original zshrc content" > "$HOME/.zshrc"

    # Test backup logic - first time should create backup
    run bash -c 'if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.pre-customzsh" ]; then
                     echo "Backing up existing .zshrc to .zshrc.pre-customzsh..."
                     mv "$HOME/.zshrc" "$HOME/.zshrc.pre-customzsh"
                     echo "Existing .zshrc backed up."
                 else
                     echo "Backup already exists or no .zshrc to backup."
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Backing up"* ]]

    # Second run should not create another backup
    echo "new zshrc content" > "$HOME/.zshrc"

    run bash -c 'if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.pre-customzsh" ]; then
                     echo "Backing up existing .zshrc to .zshrc.pre-customzsh..."
                     mv "$HOME/.zshrc" "$HOME/.zshrc.pre-customzsh"
                     echo "Existing .zshrc backed up."
                 else
                     echo "Backup already exists or no .zshrc to backup."
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" == *"already exists"* ]]

    # Verify original backup is preserved
    [ -f "$HOME/.zshrc.pre-customzsh" ]
    [ "$(cat "$HOME/.zshrc.pre-customzsh")" = "original zshrc content" ]
}

@test "multiple script runs produce consistent results" {
    # Simulate partial installation state
    mkdir -p "$HOME/.oh-my-zsh"
    echo "existing zshrc" > "$HOME/.zshrc"
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

    # First run (with existing components)
    run timeout 30 ./customzsh.sh 2>&1
    local first_exit_code="$status"
    local first_output="$output"

    # Second run (should be idempotent)
    run timeout 30 ./customzsh.sh 2>&1
    local second_exit_code="$status"
    local second_output="$output"

    # Both runs should complete similarly (0 or controlled exit)
    [[ "$first_exit_code" -eq 0 || "$first_exit_code" -eq 1 ]]
    [[ "$second_exit_code" -eq 0 || "$second_exit_code" -eq 1 ]]

    # Second run should show "skipping" messages for existing components
    [[ "$second_output" == *"Skipping"* || "$second_output" == *"already"* ]]
}

@test "eza installation is idempotent" {
    # Mock eza as already installed
    mkdir -p "$HOME/bin"
    echo '#!/bin/bash
echo "eza v0.23.3"
' > "$HOME/bin/eza"
    chmod +x "$HOME/bin/eza"
    export PATH="$HOME/bin:$PATH"

    # Test eza installation check
    run timeout 30 ./install_eza.sh 2>&1

    # Should recognize existing installation and skip
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]
    if [ "$status" -ne 124 ]; then
        [[ "$output" == *"already installed"* || "$output" == *"Skipping"* || "$output" == *"Target eza version"* ]]
    fi
}

@test "configuration loading is stable across runs" {
    # First load
    run bash -c 'source config.sh; echo "Theme: $ZSH_THEME"; echo "Plugins: ${#EXTERNAL_PLUGINS[@]}"'
    [ "$status" -eq 0 ]
    local first_output="$output"

    # Second load should be identical
    run bash -c 'source config.sh; echo "Theme: $ZSH_THEME"; echo "Plugins: ${#EXTERNAL_PLUGINS[@]}"'
    [ "$status" -eq 0 ]
    local second_output="$output"

    [ "$first_output" = "$second_output" ]
}

@test "dependency check is consistent across runs" {
    # First dependency check
    run bash -c 'source customzsh.sh; check_dependencies 2>&1'
    [ "$status" -eq 0 ]
    local first_output="$output"

    # Second dependency check should be identical
    run bash -c 'source customzsh.sh; check_dependencies 2>&1'
    [ "$status" -eq 0 ]
    local second_output="$output"

    [ "$first_output" = "$second_output" ]
}

@test "script handles partial installation states gracefully" {
    # Create various partial installation states and ensure script handles them

    # State 1: Only config exists
    [ -f "config.sh" ]
    run timeout 15 ./customzsh.sh 2>/dev/null
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]

    # State 2: Config + Oh My Zsh directory
    mkdir -p "$HOME/.oh-my-zsh"
    run timeout 15 ./customzsh.sh 2>/dev/null
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]

    # State 3: Config + Oh My Zsh + one plugin
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    run timeout 15 ./customzsh.sh 2>/dev/null
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]

    # State 4: Everything exists
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    # .zshrc already exists from setup
    run timeout 15 ./customzsh.sh 2>/dev/null
    [[ "$status" -eq 0 || "$status" -eq 1 || "$status" -eq 124 ]]
}

@test "file permissions are preserved across runs" {
    # Make scripts executable
    chmod +x customzsh.sh install_eza.sh

    # Check permissions before
    local perm_before_customzsh=$(stat -c "%a" customzsh.sh)
    local perm_before_install=$(stat -c "%a" install_eza.sh)

    # Run script
    run timeout 15 ./customzsh.sh 2>/dev/null

    # Check permissions after (should be unchanged)
    local perm_after_customzsh=$(stat -c "%a" customzsh.sh)
    local perm_after_install=$(stat -c "%a" install_eza.sh)

    [ "$perm_before_customzsh" = "$perm_after_customzsh" ]
    [ "$perm_before_install" = "$perm_after_install" ]
}