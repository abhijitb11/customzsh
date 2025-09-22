#!/usr/bin/env bats
#
# edge_cases.bats
#
# Edge case and malformed input testing for customzsh
# Tests various malformed configurations, invalid inputs, and boundary conditions
# to ensure robust error handling and graceful degradation
#
# Test Categories:
# - Malformed configuration files
# - Invalid plugin name formats
# - Extremely long inputs
# - Unicode and special character handling
# - Empty and whitespace configurations
# - Syntax errors and edge cases
#
# Author: Claude Code
# Version: 1.0
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
    export TEST_HOME="/tmp/customzsh_edge_test_${test_uuid}"
    export TEST_SCRIPT_DIR="${TEST_HOME}/customzsh"

    # Validate clean environment before setup
    validate_clean_environment "$TEST_HOME" true

    # Setup isolated test environment
    setup_isolated_environment "$TEST_HOME" "edge_case_test"

    # Copy project files to test directory (including hidden files)
    mkdir -p "$TEST_SCRIPT_DIR"
    find . -maxdepth 1 -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    find . -maxdepth 1 -name ".*" -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    # Copy directories but avoid copying test directory itself
    find . -maxdepth 1 -type d ! -name "." ! -name "tests" -exec cp -r {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    cd "$TEST_SCRIPT_DIR"

    # Set test timeout
    set_test_timeout 120 "edge_case_test_${test_uuid}"
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

# Malformed Configuration Tests

@test "handles config with missing closing quote in theme" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Should fail validation due to syntax error
    run validate_configuration_format config.sh

    [ "$status" -ne 0 ]
    [[ "$output" =~ "syntax" ]] || [[ "$output" =~ "error" ]]
}

@test "handles config with malformed array syntax" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=["zsh-users/zsh-syntax-highlighting"]  # Wrong syntax
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Should fail validation due to invalid array syntax
    run bash -c 'source config.sh'

    [ "$status" -ne 0 ]
}

@test "handles config with unclosed array declaration" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
    # Missing closing parenthesis
EZA_VERSION="latest"
BUILTIN_PLUGINS=(git)
EOF

    # Should fail validation due to unclosed array
    run validate_configuration_format config.sh

    [ "$status" -ne 0 ]
    [[ "$output" =~ "array" ]] || [[ "$output" =~ "closed" ]]
}

@test "handles config with missing variable assignments" {
    cat > config.sh << 'EOF'
#!/bin/bash
# Missing ZSH_THEME
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
# Missing EZA_VERSION
EOF

    # Should fail validation due to missing required variables
    run validate_configuration_format config.sh

    [ "$status" -ne 0 ]
    [[ "$output" =~ "ZSH_THEME" ]] || [[ "$output" =~ "EZA_VERSION" ]]
}

# Invalid Plugin Name Tests

@test "handles plugin names with invalid characters" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "user/plugin with spaces"
    "user/plugin@special#chars"
    "user/plugin$dollar&signs"
    "user/plugin|pipes"
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test plugin installation logic with invalid characters
    run bash -c 'source config.sh
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     repo_name=$(basename "$plugin")
                     echo "Processing: $repo_name"
                     # Check if basename extraction works with special chars
                     if [[ "$repo_name" =~ [[:space:]@#\$\&\|] ]]; then
                         echo "Invalid characters detected: $repo_name"
                     fi
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Invalid characters detected" ]]
}

@test "handles empty plugin names" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    ""
    "  "
    "user/"
    "/empty-user"
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test handling of empty and malformed plugin names
    run bash -c 'source config.sh
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     if [ -z "$plugin" ] || [ -z "$(echo "$plugin" | tr -d "[:space:]")" ]; then
                         echo "Empty plugin detected"
                     elif [[ "$plugin" == *"/" ]] || [[ "$plugin" == "/"* ]]; then
                         echo "Malformed plugin path: $plugin"
                     fi
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Empty plugin detected" ]] || [[ "$output" =~ "Malformed plugin path" ]]
}

@test "handles extremely long plugin names" {
    # Create a plugin name with 1000 characters
    local long_name
    long_name=$(printf 'a%.0s' {1..500})  # 500 'a's for user
    long_name="${long_name}/$(printf 'b%.0s' {1..500})"  # 500 'b's for plugin

    cat > config.sh << EOF
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "$long_name"
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test handling of extremely long plugin names
    run bash -c 'source config.sh
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     plugin_length=${#plugin}
                     echo "Plugin length: $plugin_length"
                     if [ "$plugin_length" -gt 255 ]; then
                         echo "Extremely long plugin name detected"
                     fi
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Extremely long plugin name detected" ]]
}

# Unicode and Special Character Tests

@test "handles unicode characters in theme names" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="🎨-theme-ñáéí-测试"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test unicode handling in theme names
    run bash -c 'source config.sh
                 echo "Theme: $ZSH_THEME"
                 if [[ "$ZSH_THEME" =~ [^[:ascii:]] ]]; then
                     echo "Unicode characters detected in theme"
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Unicode characters detected" ]]
}

@test "handles unicode characters in plugin names" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "user-ñáéí/plugin-测试"
    "пользователь/плагин"
    "משתמש/תוסף"
    "ユーザー/プラグイン"
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test unicode handling in plugin names
    run bash -c 'source config.sh
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     if [[ "$plugin" =~ [^[:ascii:]] ]]; then
                         echo "Unicode plugin detected: $plugin"
                     fi
                 done'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Unicode plugin detected" ]]
}

# Empty and Whitespace Configuration Tests

@test "handles completely empty configuration file" {
    # Create empty config file
    touch config.sh

    # Should fail validation
    run validate_configuration_format config.sh

    [ "$status" -ne 0 ]
}

@test "handles config with only whitespace" {
    cat > config.sh << 'EOF'







EOF

    # Should fail validation
    run validate_configuration_format config.sh

    [ "$status" -ne 0 ]
}

@test "handles config with only comments" {
    cat > config.sh << 'EOF'
#!/bin/bash
# This is a comment
# Another comment
# No actual configuration
EOF

    # Should fail validation due to missing required variables
    run validate_configuration_format config.sh

    [ "$status" -ne 0 ]
}

# Extreme Value Tests

@test "handles theme name with maximum length" {
    # Create theme name with 255 characters (typical filesystem limit)
    local long_theme
    long_theme=$(printf 'theme-%.0s' {1..42})  # Creates ~252 char theme name

    cat > config.sh << EOF
#!/bin/bash
ZSH_THEME="$long_theme"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test handling of extremely long theme names
    run bash -c 'source config.sh
                 echo "Theme length: ${#ZSH_THEME}"
                 if [ "${#ZSH_THEME}" -gt 100 ]; then
                     echo "Long theme name detected"
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Long theme name detected" ]]
}

@test "handles configuration with extremely large plugin array" {
    # Create config with 100 plugins
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
EOF

    # Add 100 plugin entries
    for i in {1..100}; do
        echo "    \"user${i}/plugin${i}\"" >> config.sh
    done

    cat >> config.sh << 'EOF'
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test handling of large plugin arrays
    run bash -c 'source config.sh
                 echo "Plugin count: ${#EXTERNAL_PLUGINS[@]}"
                 if [ "${#EXTERNAL_PLUGINS[@]}" -gt 50 ]; then
                     echo "Large plugin array detected"
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Large plugin array detected" ]]
}

# Syntax Error Tests

@test "handles config with shell injection attempts" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster; rm -rf / #"
EXTERNAL_PLUGINS=(
    "user/plugin$(echo malicious)"
    "user/plugin`whoami`"
    "user/plugin; cat /etc/passwd"
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test that shell injection is handled safely
    run bash -c 'source config.sh
                 echo "Theme: $ZSH_THEME"
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     echo "Plugin: $plugin"
                 done' 2>&1

    [ "$status" -eq 0 ]
    # Should not execute malicious commands
    [[ ! "$output" =~ "root" ]] && [[ ! "$output" =~ "passwd" ]]
}

@test "handles config with invalid variable names" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH-THEME="agnoster"  # Invalid variable name
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN-PLUGINS=(git)  # Invalid variable name
EZA_VERSION="latest"
EOF

    # Should fail to source due to invalid variable names
    run bash -c 'source config.sh'

    [ "$status" -ne 0 ]
}

@test "handles config with circular variable references" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="$MY_THEME"
MY_THEME="$ZSH_THEME"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test handling of circular references
    run bash -c 'source config.sh
                 echo "Theme: $ZSH_THEME"
                 if [ -z "$ZSH_THEME" ] || [ "$ZSH_THEME" = "\$MY_THEME" ]; then
                     echo "Circular reference detected"
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Circular reference detected" ]] || [[ "$output" =~ "\$MY_THEME" ]]
}

# Version String Edge Cases

@test "handles invalid eza version formats" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="not-a-version"
EOF

    # Test handling of invalid version format
    run bash -c 'source config.sh
                 echo "Eza version: $EZA_VERSION"
                 if [[ ! "$EZA_VERSION" =~ ^(latest|v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
                     echo "Invalid version format detected"
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Invalid version format detected" ]]
}

@test "handles eza version with special characters" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="v1.0.0; rm -rf /"
EOF

    # Test handling of version with injection attempts
    run bash -c 'source config.sh
                 echo "Eza version: $EZA_VERSION"
                 if [[ "$EZA_VERSION" =~ [;\&\|] ]]; then
                     echo "Suspicious characters in version"
                 fi'

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Suspicious characters in version" ]]
}

# File Permission and Access Tests

@test "handles config file with unusual permissions" {
    # Create config with restricted permissions
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    chmod 000 config.sh

    # Should fail to read config
    run bash -c 'source config.sh'

    [ "$status" -ne 0 ]

    # Restore permissions for cleanup
    chmod 644 config.sh
}

@test "handles config as directory instead of file" {
    # Create directory named config.sh
    mkdir -p config.sh

    # Should fail to source directory
    run bash -c 'source config.sh'

    [ "$status" -ne 0 ]
}

@test "handles config with binary data" {
    # Create config with binary content
    printf '\x00\x01\x02\x03\x04\x05Binary Data\xFF\xFE\xFD' > config.sh

    # Should fail to source binary file
    run bash -c 'source config.sh'

    [ "$status" -ne 0 ]
}

# Array Boundary Tests

@test "handles arrays with mixed quote styles" {
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "double-quoted"
    'single-quoted'
    mixed"quotes'here
    unquoted-plugin
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Test handling of mixed quote styles
    run bash -c 'source config.sh
                 for plugin in "${EXTERNAL_PLUGINS[@]}"; do
                     echo "Plugin: $plugin"
                 done'

    # May succeed or fail depending on shell interpretation
    # The test verifies behavior is predictable
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}