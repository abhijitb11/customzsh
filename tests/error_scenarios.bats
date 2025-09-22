#!/usr/bin/env bats
#
# error_scenarios.bats
#
# Comprehensive error condition testing for customzsh
# Tests various failure scenarios that may occur during installation
# and ensures graceful handling of error conditions.
#
# Test Categories:
# - Network failures (git clone, GitHub API, DNS)
# - Permission issues (sudo, directory access, filesystem)
# - Repository validation (invalid URLs, non-existent repos)
# - System resource constraints (disk space, memory)
# - Configuration errors (malformed files, invalid syntax)
#
# Author: Claude Code
# Version: 1.0
#

# Load test helpers
load 'helpers/isolation_utils'
load 'helpers/validation_helpers'
load 'helpers/error_simulation'

setup() {
    # Generate UUID for unique test directory
    local test_uuid
    test_uuid=$(generate_test_uuid)
    export TEST_HOME="/tmp/customzsh_error_test_${test_uuid}"
    export TEST_SCRIPT_DIR="${TEST_HOME}/customzsh"

    # Validate clean environment before setup
    validate_clean_environment "$TEST_HOME" true

    # Setup isolated test environment
    setup_isolated_environment "$TEST_HOME" "error_test"

    # Copy project files to test directory (including hidden files)
    mkdir -p "$TEST_SCRIPT_DIR"
    find . -maxdepth 1 -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    find . -maxdepth 1 -name ".*" -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    # Copy directories but avoid copying test directory itself
    find . -maxdepth 1 -type d ! -name "." ! -name "tests" -exec cp -r {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    cd "$TEST_SCRIPT_DIR"

    # Set test timeout
    set_test_timeout 120 "error_test_${test_uuid}"
}

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

# Network Failure Tests

@test "handles git clone network failure gracefully" {
    cd "$TEST_SCRIPT_DIR"

    # Create a config that will trigger git clone
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
)
BUILTIN_PLUGINS=(git z command-not-found)
EZA_VERSION="v0.18.0"
EOF

    # Mock git to simulate network failure
    cat > git << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: unable to access 'https://github.com/zsh-users/zsh-syntax-highlighting.git/': Could not resolve host: github.com" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
    chmod +x git
    export PATH="$PWD:$PATH"

    # Run installation and expect graceful failure
    run ./customzsh.sh

    # Should fail with appropriate error message
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Failed to install plugin" ]] || [[ "$output" =~ "network" ]] || [[ "$output" =~ "Could not resolve host" ]]
}

@test "handles GitHub API rate limiting gracefully" {
    cd "$TEST_SCRIPT_DIR"

    # Create config with eza latest version (requires GitHub API)
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=()
BUILTIN_PLUGINS=(git z)
EZA_VERSION="latest"
EOF

    # Mock curl to simulate rate limiting
    cat > curl << 'EOF'
#!/bin/bash
if [[ "$*" =~ "api.github.com" ]]; then
    echo '{"message": "API rate limit exceeded for 0.0.0.0. (But here'\''s the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)", "documentation_url": "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"}' >&2
    exit 22
fi
exec /usr/bin/curl "$@"
EOF
    chmod +x curl
    export PATH="$PWD:$PATH"

    # Run eza installation script
    run ./install_eza.sh

    # Should handle rate limiting gracefully
    [ "$status" -ne 0 ]
    [[ "$output" =~ "rate limit" ]] || [[ "$output" =~ "API" ]] || [[ "$output" =~ "GitHub" ]]
}

@test "handles DNS resolution failures gracefully" {
    cd "$TEST_SCRIPT_DIR"

    # Create config that requires network access
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=("zsh-users/zsh-autosuggestions")
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Mock nslookup/dig to simulate DNS failure
    cat > nslookup << 'EOF'
#!/bin/bash
echo "** server can't find github.com: NXDOMAIN" >&2
exit 1
EOF
    chmod +x nslookup
    export PATH="$PWD:$PATH"

    # Mock curl to simulate DNS resolution failure
    cat > curl << 'EOF'
#!/bin/bash
if [[ "$*" =~ "github.com" ]]; then
    echo "curl: (6) Could not resolve host: github.com" >&2
    exit 6
fi
exec /usr/bin/curl "$@"
EOF
    chmod +x curl
    export PATH="$PWD:$PATH"

    run ./customzsh.sh

    # Should fail gracefully with DNS error
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Could not resolve host" ]] || [[ "$output" =~ "DNS" ]] || [[ "$output" =~ "network" ]]
}

# Permission and Filesystem Tests

@test "handles permission denied on .oh-my-zsh directory" {
    cd "$TEST_SCRIPT_DIR"

    # Create config
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=()
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Pre-create oh-my-zsh directory with restrictive permissions
    mkdir -p "$HOME/.oh-my-zsh"
    chmod 000 "$HOME/.oh-my-zsh"

    run ./customzsh.sh

    # Should handle permission error gracefully
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Permission denied" ]] || [[ "$output" =~ "permission" ]] || [[ "$output" =~ "access" ]]

    # Cleanup: restore permissions for teardown
    chmod 755 "$HOME/.oh-my-zsh" 2>/dev/null || true
}

@test "handles sudo authentication failure" {
    cd "$TEST_SCRIPT_DIR"

    # Create config that requires sudo (eza installation)
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=()
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Mock sudo to fail authentication
    cat > sudo << 'EOF'
#!/bin/bash
echo "sudo: 3 incorrect password attempts" >&2
exit 1
EOF
    chmod +x sudo
    export PATH="$PWD:$PATH"

    run ./install_eza.sh

    # Should handle sudo failure gracefully
    [ "$status" -ne 0 ]
    [[ "$output" =~ "sudo" ]] || [[ "$output" =~ "password" ]] || [[ "$output" =~ "authentication" ]]
}

@test "handles read-only filesystem scenarios" {
    cd "$TEST_SCRIPT_DIR"

    # Create config
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=()
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Create a read-only directory for .oh-my-zsh
    mkdir -p "$HOME/.oh-my-zsh"
    chmod 444 "$HOME/.oh-my-zsh"

    # Mock attempt to write to read-only location
    run ./customzsh.sh

    # Should detect and handle read-only filesystem
    [ "$status" -ne 0 ]
    [[ "$output" =~ "read-only" ]] || [[ "$output" =~ "Permission denied" ]] || [[ "$output" =~ "cannot create" ]]

    # Cleanup
    chmod 755 "$HOME/.oh-my-zsh" 2>/dev/null || true
}

# Repository Validation Tests

@test "handles invalid GitHub repository URLs" {
    cd "$TEST_SCRIPT_DIR"

    # Create config with invalid repository URL format
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=(
    "not-a-valid/repo/format/too-many-slashes"
    "invalid-chars-#$%"
    ""
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    run ./customzsh.sh

    # Should handle invalid repository format gracefully
    [ "$status" -ne 0 ]
    [[ "$output" =~ "invalid" ]] || [[ "$output" =~ "repository" ]] || [[ "$output" =~ "format" ]]
}

@test "handles non-existent repositories" {
    cd "$TEST_SCRIPT_DIR"

    # Create config with non-existent repository
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=(
    "nonexistent-user/nonexistent-repo-$(date +%s)"
)
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Mock git clone to simulate repository not found
    cat > git << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: repository 'https://github.com/nonexistent-user/nonexistent-repo.git' not found" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
    chmod +x git
    export PATH="$PWD:$PATH"

    run ./customzsh.sh

    # Should handle non-existent repository gracefully
    [ "$status" -ne 0 ]
    [[ "$output" =~ "not found" ]] || [[ "$output" =~ "repository" ]] || [[ "$output" =~ "failed" ]]
}

@test "handles private repository access denial" {
    cd "$TEST_SCRIPT_DIR"

    # Create config with private repository (simulated)
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=("private-user/private-repo")
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Mock git clone to simulate private repo access denial
    cat > git << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: could not read Username for 'https://github.com': terminal prompts disabled" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
    chmod +x git
    export PATH="$PWD:$PATH"

    run ./customzsh.sh

    # Should handle private repository access denial
    [ "$status" -ne 0 ]
    [[ "$output" =~ "could not read" ]] || [[ "$output" =~ "Username" ]] || [[ "$output" =~ "access" ]]
}

# System Resource Constraint Tests

@test "handles disk space exhaustion during installation" {
    cd "$TEST_SCRIPT_DIR"

    # Create config
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Mock df to simulate low disk space
    cat > df << 'EOF'
#!/bin/bash
if [[ "$*" =~ "-h" ]]; then
    echo "Filesystem      Size  Used Avail Use% Mounted on"
    echo "/dev/sda1        10M   10M     0 100% /"
    exit 0
fi
exec /usr/bin/df "$@"
EOF
    chmod +x df
    export PATH="$PWD:$PATH"

    # Mock git clone to simulate disk full error
    cat > git << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: write error: No space left on device" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
    chmod +x git
    export PATH="$PWD:$PATH"

    run ./customzsh.sh

    # Should handle disk space exhaustion
    [ "$status" -ne 0 ]
    [[ "$output" =~ "No space left" ]] || [[ "$output" =~ "disk" ]] || [[ "$output" =~ "space" ]]
}

@test "handles corrupted download scenarios" {
    cd "$TEST_SCRIPT_DIR"

    # Create config
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=()
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Mock curl to simulate corrupted download
    cat > curl << 'EOF'
#!/bin/bash
if [[ "$*" =~ "github.com/api" ]]; then
    echo '{"incomplete": "json response' # Intentionally malformed JSON
    exit 0
fi
exec /usr/bin/curl "$@"
EOF
    chmod +x curl
    export PATH="$PWD:$PATH"

    run ./install_eza.sh

    # Should handle corrupted download gracefully
    [ "$status" -ne 0 ]
    [[ "$output" =~ "parse" ]] || [[ "$output" =~ "invalid" ]] || [[ "$output" =~ "corrupted" ]] || [[ "$output" =~ "malformed" ]]
}

# Configuration Error Tests

@test "handles missing dependency tools gracefully" {
    cd "$TEST_SCRIPT_DIR"

    # Create config
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=()
BUILTIN_PLUGINS=(git)
EZA_VERSION="latest"
EOF

    # Hide required dependency (jq)
    mkdir -p hidden_bins
    if command -v jq >/dev/null 2>&1; then
        mv "$(command -v jq)" hidden_bins/ 2>/dev/null || true
    fi

    run ./customzsh.sh

    # Should detect missing dependency
    [ "$status" -ne 0 ]
    [[ "$output" =~ "jq" ]] || [[ "$output" =~ "dependency" ]] || [[ "$output" =~ "required" ]]

    # Restore jq if we moved it
    if [ -f "hidden_bins/jq" ]; then
        mv hidden_bins/jq /usr/bin/ 2>/dev/null || sudo mv hidden_bins/jq /usr/bin/ || true
    fi
}

@test "handles incomplete plugin installation gracefully" {
    cd "$TEST_SCRIPT_DIR"

    # Create config
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=("zsh-users/zsh-syntax-highlighting")
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Mock git clone to simulate partial failure
    cat > git << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    # Create directory but simulate failure
    mkdir -p "$4" 2>/dev/null || true
    echo "fatal: early EOF" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
    chmod +x git
    export PATH="$PWD:$PATH"

    run ./customzsh.sh

    # Should handle partial installation failure
    [ "$status" -ne 0 ]
    [[ "$output" =~ "early EOF" ]] || [[ "$output" =~ "failed" ]] || [[ "$output" =~ "incomplete" ]]
}

@test "handles system interruption during installation" {
    cd "$TEST_SCRIPT_DIR"

    # Create config
    cat > config.sh << EOF
ZSH_THEME="robbyrussell"
EXTERNAL_PLUGINS=("zsh-users/zsh-autosuggestions")
BUILTIN_PLUGINS=(git)
EZA_VERSION="v0.18.0"
EOF

    # Mock git clone to simulate interruption
    cat > git << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: the remote end hung up unexpectedly" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
    chmod +x git
    export PATH="$PWD:$PATH"

    run ./customzsh.sh

    # Should handle system interruption
    [ "$status" -ne 0 ]
    [[ "$output" =~ "hung up" ]] || [[ "$output" =~ "remote" ]] || [[ "$output" =~ "interrupted" ]]
}