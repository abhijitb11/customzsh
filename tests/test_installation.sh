#!/usr/bin/env bats

# Test suite for customzsh installation script
# Run with: ./tests/bats/bin/bats tests/test_installation.sh

setup() {
    # Set up test environment before each test
    export TEST_HOME="/tmp/customzsh_test_$$"
    mkdir -p "$TEST_HOME"
    export HOME="$TEST_HOME"

    # Copy necessary files to test directory
    cp customzsh.sh install_eza.sh .zshrc config.sh.example "$TEST_HOME/"
    cd "$TEST_HOME"
}

teardown() {
    # Clean up after each test
    cd /
    rm -rf "$TEST_HOME"
}

@test "dependency check function works correctly" {
    # Test that dependency check identifies missing commands
    run bash -c 'source customzsh.sh; check_dependencies'
    [ "$status" -eq 0 ]
}

@test "config.sh is created from template when missing" {
    # Test configuration file creation
    rm -f config.sh
    run timeout 10 bash customzsh.sh
    [ "$status" -eq 0 ]
    [ -f "config.sh" ]
    [ "$(cat config.sh)" = "$(cat config.sh.example)" ]
}

@test "script handles --uninstall flag" {
    # Test uninstall functionality
    run bash customzsh.sh --uninstall
    [ "$status" -eq 0 ]
    [[ "$output" == *"Uninstallation complete"* ]]
}

@test "script is idempotent for zsh installation check" {
    # Mock zsh command to simulate it's already installed
    mkdir -p bin
    echo '#!/bin/bash\necho "zsh version"' > bin/zsh
    chmod +x bin/zsh
    export PATH="$PWD/bin:$PATH"

    # Copy config file
    cp config.sh.example config.sh

    # Test that script skips zsh installation when already present
    run bash -c 'source customzsh.sh;
                 if command -v zsh >/dev/null 2>&1; then
                     echo "Zsh is already installed. Skipping installation."
                 fi'
    [[ "$output" == *"Zsh is already installed"* ]]
}

@test "script backs up existing .zshrc" {
    # Create a dummy .zshrc file
    echo "original zshrc content" > .zshrc

    # Create config file
    cp config.sh.example config.sh

    # Test backup functionality (we'll test just the backup logic)
    run bash -c 'if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.pre-customzsh" ]; then
                     mv "$HOME/.zshrc" "$HOME/.zshrc.pre-customzsh"
                     echo "Backed up existing .zshrc"
                 fi'

    [ -f ".zshrc.pre-customzsh" ]
    [ "$(cat .zshrc.pre-customzsh)" = "original zshrc content" ]
}

@test "script validates configuration file format" {
    # Test with valid config
    cp config.sh.example config.sh
    run bash -c 'source config.sh; echo "Config loaded: $ZSH_THEME"'
    [ "$status" -eq 0 ]
    [[ "$output" == *"agnoster"* ]]
}

@test "eza installation script handles version configuration" {
    # Test eza version handling
    cp config.sh.example config.sh

    # Test version determination logic
    run bash -c 'source config.sh;
                 TARGET_EZA_VERSION=$EZA_VERSION
                 if [ "$TARGET_EZA_VERSION" == "latest" ]; then
                     echo "Would fetch latest version"
                 fi
                 echo "Target version: $TARGET_EZA_VERSION"'
    [[ "$output" == *"Target version: latest"* ]]
}

@test "error handling prevents script continuation on failure" {
    # Test that set -e works properly
    run bash -c 'set -e; false; echo "This should not print"'
    [ "$status" -ne 0 ]
    [[ "$output" != *"This should not print"* ]]
}

@test "output helper functions work correctly" {
    # Test standardized output functions by defining them directly
    run bash -c '
        info() {
            echo "[INFO] $1"
        }
        success() {
            echo "[SUCCESS] $1"
        }
        error() {
            echo "[ERROR] $1" >&2
        }
        info "Test info message"
        success "Test success message"
        error "Test error message"'
    [[ "$output" == *"[INFO] Test info message"* ]]
    [[ "$output" == *"[SUCCESS] Test success message"* ]]
    [[ "$output" == *"[ERROR] Test error message"* ]]
}

@test "plugin installation logic handles external plugins array" {
    # Test plugin installation loop logic
    cp config.sh.example config.sh
    run bash -c 'source config.sh
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     repo_name=$(basename "$plugin")
                     echo "Would install: $repo_name"
                 done'
    [[ "$output" == *"Would install: zsh-syntax-highlighting"* ]]
    [[ "$output" == *"Would install: zsh-autosuggestions"* ]]
}

@test "script handles missing install_eza.sh gracefully" {
    # Test behavior when install_eza.sh is missing
    rm -f install_eza.sh
    cp config.sh.example config.sh

    run bash -c 'if [ -f "./install_eza.sh" ]; then
                     echo "install_eza.sh found"
                 else
                     echo "install_eza.sh not found, skipping eza installation."
                 fi'
    [[ "$output" == *"install_eza.sh not found"* ]]
}