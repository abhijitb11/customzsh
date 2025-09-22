#!/bin/bash
#
# error_simulation.bash
#
# Helper functions for simulating various error conditions in customzsh tests
# Provides utilities for network failures, permission issues, and system constraints
#
# Functions:
# - simulate_network_failure(): Mock network connectivity issues
# - create_permission_denied_scenario(): Set up permission-based failures
# - mock_invalid_repository(): Simulate repository access problems
# - simulate_disk_full(): Mock disk space exhaustion
# - mock_corrupted_download(): Simulate file corruption
# - simulate_rate_limiting(): Mock GitHub API rate limits
#
# Author: Claude Code
# Version: 1.0
#

# Simulate network failure by creating mock network tools
simulate_network_failure() {
    local failure_type="${1:-dns}"
    local mock_dir="$2"

    [ -z "$mock_dir" ] && {
        echo "Error: mock_dir parameter required" >&2
        return 1
    }

    mkdir -p "$mock_dir"

    case "$failure_type" in
        "dns")
            # Mock curl for DNS resolution failure
            cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "github.com" ]]; then
    echo "curl: (6) Could not resolve host: github.com" >&2
    exit 6
fi
exec /usr/bin/curl "$@"
EOF
            ;;
        "timeout")
            # Mock curl for timeout
            cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "github.com" ]]; then
    echo "curl: (28) Connection timed out after 10001 milliseconds" >&2
    exit 28
fi
exec /usr/bin/curl "$@"
EOF
            ;;
        "connection_refused")
            # Mock curl for connection refused
            cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "github.com" ]]; then
    echo "curl: (7) Failed to connect to github.com port 443: Connection refused" >&2
    exit 7
fi
exec /usr/bin/curl "$@"
EOF
            ;;
    esac

    chmod +x "$mock_dir/curl"
    echo "Network failure simulation created: $failure_type"
}

# Create permission denied scenarios
create_permission_denied_scenario() {
    local scenario_type="${1:-directory}"
    local target_path="$2"

    [ -z "$target_path" ] && {
        echo "Error: target_path parameter required" >&2
        return 1
    }

    case "$scenario_type" in
        "directory")
            # Create directory with no permissions
            mkdir -p "$target_path"
            chmod 000 "$target_path"
            echo "Permission denied scenario created for directory: $target_path"
            ;;
        "file")
            # Create file with no permissions
            touch "$target_path"
            chmod 000 "$target_path"
            echo "Permission denied scenario created for file: $target_path"
            ;;
        "readonly")
            # Create read-only filesystem simulation
            mkdir -p "$target_path"
            chmod 444 "$target_path"
            echo "Read-only scenario created for: $target_path"
            ;;
    esac
}

# Mock invalid repository scenarios
mock_invalid_repository() {
    local error_type="${1:-not_found}"
    local mock_dir="$2"

    [ -z "$mock_dir" ] && {
        echo "Error: mock_dir parameter required" >&2
        return 1
    }

    mkdir -p "$mock_dir"

    case "$error_type" in
        "not_found")
            # Mock git clone for repository not found
            cat > "$mock_dir/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: repository 'https://github.com/nonexistent-user/nonexistent-repo.git' not found" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
            ;;
        "private_access")
            # Mock git clone for private repository access denial
            cat > "$mock_dir/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: could not read Username for 'https://github.com': terminal prompts disabled" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
            ;;
        "network_error")
            # Mock git clone for network error during clone
            cat > "$mock_dir/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: unable to access 'https://github.com/user/repo.git/': Could not resolve host: github.com" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
            ;;
        "interrupted")
            # Mock git clone for interrupted connection
            cat > "$mock_dir/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: the remote end hung up unexpectedly" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF
            ;;
    esac

    chmod +x "$mock_dir/git"
    echo "Invalid repository mock created: $error_type"
}

# Simulate disk full scenarios
simulate_disk_full() {
    local mock_dir="$1"

    [ -z "$mock_dir" ] && {
        echo "Error: mock_dir parameter required" >&2
        return 1
    }

    mkdir -p "$mock_dir"

    # Mock df to show full disk
    cat > "$mock_dir/df" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "-h" ]]; then
    echo "Filesystem      Size  Used Avail Use% Mounted on"
    echo "/dev/sda1        10M   10M     0 100% /"
    exit 0
fi
exec /usr/bin/df "$@"
EOF

    # Mock git clone to fail with disk full
    cat > "$mock_dir/git" << 'EOF'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
    echo "fatal: write error: No space left on device" >&2
    exit 128
fi
exec /usr/bin/git "$@"
EOF

    chmod +x "$mock_dir/df" "$mock_dir/git"
    echo "Disk full simulation created"
}

# Mock corrupted download scenarios
mock_corrupted_download() {
    local corruption_type="${1:-malformed_json}"
    local mock_dir="$2"

    [ -z "$mock_dir" ] && {
        echo "Error: mock_dir parameter required" >&2
        return 1
    }

    mkdir -p "$mock_dir"

    case "$corruption_type" in
        "malformed_json")
            # Mock curl to return malformed JSON
            cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "api.github.com" ]]; then
    echo '{"incomplete": "json response' # Intentionally malformed
    exit 0
fi
exec /usr/bin/curl "$@"
EOF
            ;;
        "empty_response")
            # Mock curl to return empty response
            cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "api.github.com" ]]; then
    echo ""
    exit 0
fi
exec /usr/bin/curl "$@"
EOF
            ;;
        "binary_corruption")
            # Mock curl to return binary garbage
            cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "github.com" ]] && [[ "$*" =~ "releases" ]]; then
    printf '\x00\x01\x02\x03\x04\x05\x06\x07'
    exit 0
fi
exec /usr/bin/curl "$@"
EOF
            ;;
    esac

    chmod +x "$mock_dir/curl"
    echo "Corrupted download mock created: $corruption_type"
}

# Simulate GitHub API rate limiting
simulate_rate_limiting() {
    local mock_dir="$1"

    [ -z "$mock_dir" ] && {
        echo "Error: mock_dir parameter required" >&2
        return 1
    }

    mkdir -p "$mock_dir"

    # Mock curl to return rate limit error
    cat > "$mock_dir/curl" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "api.github.com" ]]; then
    cat << 'RATE_LIMIT_JSON'
{
  "message": "API rate limit exceeded for 0.0.0.0. (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)",
  "documentation_url": "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
}
RATE_LIMIT_JSON
    exit 22
fi
exec /usr/bin/curl "$@"
EOF

    chmod +x "$mock_dir/curl"
    echo "Rate limiting simulation created"
}

# Simulate sudo authentication failure
simulate_sudo_failure() {
    local mock_dir="$1"

    [ -z "$mock_dir" ] && {
        echo "Error: mock_dir parameter required" >&2
        return 1
    }

    mkdir -p "$mock_dir"

    # Mock sudo to fail authentication
    cat > "$mock_dir/sudo" << 'EOF'
#!/bin/bash
echo "sudo: 3 incorrect password attempts" >&2
exit 1
EOF

    chmod +x "$mock_dir/sudo"
    echo "Sudo failure simulation created"
}

# Simulate missing dependency
simulate_missing_dependency() {
    local dependency="$1"
    local mock_dir="$2"

    [ -z "$dependency" ] || [ -z "$mock_dir" ] && {
        echo "Error: dependency and mock_dir parameters required" >&2
        return 1
    }

    mkdir -p "$mock_dir"

    # Create mock that fails for the specific dependency
    cat > "$mock_dir/$dependency" << EOF
#!/bin/bash
echo "$dependency: command not found" >&2
exit 127
EOF

    chmod +x "$mock_dir/$dependency"
    echo "Missing dependency simulation created for: $dependency"
}

# Clean up mock environment
cleanup_error_simulation() {
    local mock_dir="$1"

    [ -z "$mock_dir" ] && {
        echo "Error: mock_dir parameter required" >&2
        return 1
    }

    if [ -d "$mock_dir" ]; then
        rm -rf "$mock_dir"
        echo "Error simulation cleanup completed"
    fi
}

# Validate error simulation setup
validate_error_simulation() {
    local mock_dir="$1"
    local expected_mocks="$2"

    [ -z "$mock_dir" ] || [ -z "$expected_mocks" ] && {
        echo "Error: mock_dir and expected_mocks parameters required" >&2
        return 1
    }

    local validation_passed=true

    for mock in $expected_mocks; do
        if [ ! -f "$mock_dir/$mock" ] || [ ! -x "$mock_dir/$mock" ]; then
            echo "Validation failed: $mock not found or not executable" >&2
            validation_passed=false
        fi
    done

    if [ "$validation_passed" = true ]; then
        echo "Error simulation validation passed"
        return 0
    else
        echo "Error simulation validation failed" >&2
        return 1
    fi
}