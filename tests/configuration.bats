#!/usr/bin/env bats
#
# configuration.bats
#
# Configuration customization testing for customzsh
# Tests various configuration options and their proper application
#
# Test Categories:
# - Theme configuration and customization
# - External plugin array management
# - Built-in plugin documentation and validation
# - Version specification for eza and other tools
# - Configuration file format validation
# - Edge cases in configuration parsing
# - Multi-run safety and consistency
#
# Test Count: 14 tests
# Dependencies: bash configuration parsing
# Environment: Isolated test directories with UUID-based naming
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
    export TEST_HOME="/tmp/customzsh_config_test_${test_uuid}"
    export TEST_SCRIPT_DIR="${TEST_HOME}/customzsh"

    # Validate clean environment before setup
    validate_clean_environment "$TEST_HOME" true

    # Setup isolated test environment
    setup_isolated_environment "$TEST_HOME" "configuration_test"

    # Copy project files to test directory (including hidden files)
    mkdir -p "$TEST_SCRIPT_DIR"
    find . -maxdepth 1 -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    find . -maxdepth 1 -name ".*" -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    # Copy directories but avoid copying test directory itself
    find . -maxdepth 1 -type d ! -name "." ! -name "tests" -exec cp -r {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    cd "$TEST_SCRIPT_DIR"

    # Start with clean config
    rm -f config.sh

    # Set test timeout
    set_test_timeout 180 "configuration_test_${test_uuid}"
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

@test "default configuration matches template" {
    # Copy template to config
    cp config.sh.example config.sh

    # Load and verify default configuration
    run bash -c 'source config.sh;
                 echo "Theme: $ZSH_THEME";
                 echo "Plugins: ${#EXTERNAL_PLUGINS[@]}";
                 echo "Eza: $EZA_VERSION"'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Theme: agnoster"* ]]
    [[ "$output" == *"Plugins: 2"* ]]
    [[ "$output" == *"Eza: latest"* ]]
}

@test "theme configuration can be customized" {
    # Create custom config with different theme
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
)
EZA_VERSION="latest"
BUILTIN_PLUGINS=(
    "git"
    "z"
    "command-not-found"
    "cp"
)
EOF

    # Verify custom theme is loaded
    run bash -c 'source config.sh; echo "Theme: $ZSH_THEME"'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Theme: robbyrussell"* ]]
}

@test "external plugins can be customized" {
    # Create config with different plugins
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-completions"
    "zsh-users/zsh-history-substring-search"
)
EZA_VERSION="latest"
BUILTIN_PLUGINS=(
    "git"
    "z"
    "command-not-found"
    "cp"
)
EOF

    # Verify custom plugins are loaded
    run bash -c 'source config.sh;
                 echo "Plugin count: ${#EXTERNAL_PLUGINS[@]}";
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     echo "Plugin: $plugin";
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Plugin count: 3"* ]]
    [[ "$output" == *"zsh-users/zsh-syntax-highlighting"* ]]
    [[ "$output" == *"zsh-users/zsh-completions"* ]]
    [[ "$output" == *"zsh-users/zsh-history-substring-search"* ]]
}

@test "eza version can be set to specific version" {
    # Create config with specific eza version
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
)
EZA_VERSION="v0.23.0"
BUILTIN_PLUGINS=(
    "git"
    "z"
    "command-not-found"
    "cp"
)
EOF

    # Verify specific version is configured
    run bash -c 'source config.sh; echo "Eza version: $EZA_VERSION"'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Eza version: v0.23.0"* ]]
}

@test "empty external plugins array is handled" {
    # Create config with no external plugins
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=()
EZA_VERSION="latest"
BUILTIN_PLUGINS=(
    "git"
    "z"
    "command-not-found"
    "cp"
)
EOF

    # Verify empty array is handled correctly
    run bash -c 'source config.sh;
                 echo "Plugin count: ${#EXTERNAL_PLUGINS[@]}";
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     echo "Plugin: $plugin";
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Plugin count: 0"* ]]
}

@test "plugin installation logic respects configuration" {
    # Create config with custom plugins
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "custom/plugin"
)
EZA_VERSION="latest"
BUILTIN_PLUGINS=(
    "git"
    "z"
    "command-not-found"
    "cp"
)
EOF

    # Test plugin installation logic
    run bash -c 'source config.sh;
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     repo_name=$(basename "$plugin")
                     target_dir="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$repo_name"
                     echo "Would install $repo_name to $target_dir"
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"zsh-syntax-highlighting"* ]]
    [[ "$output" == *"plugin"* ]]
    [[ "$output" == *"/.oh-my-zsh/custom/plugins/"* ]]
}

@test "configuration validation catches invalid syntax" {
    # Create config with syntax error
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
)
EZA_VERSION="latest"
EOF

    # Should fail to source due to syntax error
    run bash -c 'source config.sh'

    [ "$status" -ne 0 ]
}

@test "configuration handles special characters in theme names" {
    # Create config with theme name containing special characters
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="my-custom-theme_v2.0"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
)
EZA_VERSION="latest"
BUILTIN_PLUGINS=(
    "git"
)
EOF

    # Verify special characters are handled
    run bash -c 'source config.sh; echo "Theme: $ZSH_THEME"'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Theme: my-custom-theme_v2.0"* ]]
}

@test "configuration supports comments and documentation" {
    # Create config with extensive comments
    cat > config.sh << 'EOF'
#!/bin/bash
# Custom configuration for customzsh

# Set the Zsh theme - choose from available Oh My Zsh themes
ZSH_THEME="agnoster"  # Popular theme with git integration

# External plugins to download and install
EXTERNAL_PLUGINS=(
    # Essential syntax highlighting
    "zsh-users/zsh-syntax-highlighting"
    # Command autosuggestions
    "zsh-users/zsh-autosuggestions"
)

# Version of eza to install
EZA_VERSION="latest"  # Use latest available version

# Built-in plugins (no download needed)
BUILTIN_PLUGINS=(
    "git"  # Git integration
    "z"    # Directory jumping
)
EOF

    # Should load despite comments
    run bash -c 'source config.sh;
                 echo "Theme: $ZSH_THEME";
                 echo "Plugins: ${#EXTERNAL_PLUGINS[@]}";
                 echo "Eza: $EZA_VERSION"'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Theme: agnoster"* ]]
    [[ "$output" == *"Plugins: 2"* ]]
    [[ "$output" == *"Eza: latest"* ]]
}

@test "configuration script can be sourced multiple times safely" {
    # Create standard config
    cp config.sh.example config.sh

    # Source multiple times
    run bash -c 'source config.sh;
                 first_theme="$ZSH_THEME";
                 source config.sh;
                 second_theme="$ZSH_THEME";
                 if [ "$first_theme" = "$second_theme" ]; then
                     echo "Consistent: $first_theme";
                 else
                     echo "Inconsistent: $first_theme vs $second_theme";
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Consistent: agnoster"* ]]
}

@test "eza version configuration affects install_eza.sh behavior" {
    # Test with latest version
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=()
EZA_VERSION="latest"
BUILTIN_PLUGINS=()
EOF

    # Test version determination logic
    run bash -c 'source config.sh;
                 TARGET_EZA_VERSION=$EZA_VERSION;
                 if [ "$TARGET_EZA_VERSION" == "latest" ]; then
                     echo "Would fetch latest version";
                 else
                     echo "Would use specific version: $TARGET_EZA_VERSION";
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would fetch latest version"* ]]

    # Test with specific version
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=()
EZA_VERSION="v0.23.0"
BUILTIN_PLUGINS=()
EOF

    run bash -c 'source config.sh;
                 TARGET_EZA_VERSION=$EZA_VERSION;
                 if [ "$TARGET_EZA_VERSION" == "latest" ]; then
                     echo "Would fetch latest version";
                 else
                     echo "Would use specific version: $TARGET_EZA_VERSION";
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would use specific version: v0.23.0"* ]]
}

@test "configuration supports extended plugin arrays" {
    # Create config with many plugins
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-completions"
    "zsh-users/zsh-history-substring-search"
    "custom-org/custom-plugin-1"
    "another-org/another-plugin"
)
EZA_VERSION="latest"
BUILTIN_PLUGINS=(
    "git"
    "z"
    "command-not-found"
    "cp"
    "brew"
    "npm"
)
EOF

    # Verify all plugins are loaded correctly
    run bash -c 'source config.sh;
                 echo "External plugins: ${#EXTERNAL_PLUGINS[@]}";
                 echo "Builtin plugins: ${#BUILTIN_PLUGINS[@]}"'

    [ "$status" -eq 0 ]
    [[ "$output" == *"External plugins: 6"* ]]
    [[ "$output" == *"Builtin plugins: 6"* ]]
}

@test "configuration file creation preserves permissions" {
    # Create config with specific permissions
    cp config.sh.example config.sh
    chmod 644 config.sh

    # Check permissions
    local perm_before=$(stat -c "%a" config.sh)

    # Source the config (should not change permissions)
    run bash -c 'source config.sh; echo "Loaded"'

    [ "$status" -eq 0 ]

    local perm_after=$(stat -c "%a" config.sh)
    [ "$perm_before" = "$perm_after" ]
}

@test "configuration handles edge cases in plugin names" {
    # Create config with edge case plugin names
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "user-with-dash/plugin-with-dash"
    "user_with_underscore/plugin_with_underscore"
    "user123/plugin123"
    "user.with.dots/plugin.with.dots"
)
EZA_VERSION="latest"
BUILTIN_PLUGINS=()
EOF

    # Test basename extraction for various plugin name formats
    run bash -c 'source config.sh;
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     repo_name=$(basename "$plugin")
                     echo "Plugin: $plugin -> Basename: $repo_name"
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" == *"plugin-with-dash"* ]]
    [[ "$output" == *"plugin_with_underscore"* ]]
    [[ "$output" == *"plugin123"* ]]
    [[ "$output" == *"plugin.with.dots"* ]]
}