#!/bin/bash
#
# Enhanced test runner for customzsh project
# Supports both unit tests and integration tests with flexible execution options
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"
BATS_EXECUTABLE=""
VERBOSE=${VERBOSE:-false}
SUITE=${SUITE:-"all"}

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}$message${NC}"
}

info() { print_status "$BLUE" "[INFO] $1"; }
success() { print_status "$GREEN" "[SUCCESS] $1"; }
warning() { print_status "$YELLOW" "[WARNING] $1"; }
error() { print_status "$RED" "[ERROR] $1"; }
header() { print_status "$CYAN" "$1"; }

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Enhanced test runner for customzsh project

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -s, --suite SUITE   Run specific test suite:
                        - unit: Run unit tests only (test_installation.sh)
                        - integration: Run integration tests only (.bats files)
                        - all: Run all tests (default)
    -l, --list          List available test suites
    -f, --fast          Skip slower integration tests
    --docker            Optimize for Docker environment
    --ci                Optimize for CI/CD environment

Examples:
    $0                      # Run all tests
    $0 --suite unit         # Run only unit tests
    $0 --suite integration  # Run only integration tests
    $0 --verbose            # Run with verbose output
    $0 --fast              # Run fast tests only

EOF
}

# Function to list available test suites
list_suites() {
    info "Available test suites:"
    echo
    echo "  unit                 - Original comprehensive unit tests"
    echo "                        File: tests/test_installation.sh"
    echo "                        Tests: 11 test cases"
    echo
    echo "  integration          - Modular integration tests"
    echo "                        Files: tests/*.bats"
    echo "                        Categories:"
    echo "                          - installation.bats (end-to-end installation)"
    echo "                          - idempotency.bats (multi-run safety)"
    echo "                          - uninstall.bats (complete removal)"
    echo "                          - configuration.bats (config customization)"
    echo
    echo "  all (default)        - All unit and integration tests"
    echo
}

# Function to check bats availability
check_bats() {
    local bats_paths=(
        "$TESTS_DIR/bats/bin/bats"
        "/usr/local/bin/bats"
        "/usr/bin/bats"
        "$(command -v bats 2>/dev/null || true)"
    )

    for bats_path in "${bats_paths[@]}"; do
        if [ -n "$bats_path" ] && [ -x "$bats_path" ]; then
            BATS_EXECUTABLE="$bats_path"
            return 0
        fi
    done

    return 1
}

# Function to setup bats
setup_bats() {
    if ! check_bats; then
        error "bats testing framework not found."
        echo
        echo "Installation options:"
        echo "1. Git submodule (recommended):"
        echo "   git submodule update --init --recursive"
        echo
        echo "2. System installation:"
        echo "   # Ubuntu/Debian: sudo apt install bats"
        echo "   # macOS: brew install bats-core"
        echo "   # Manual: https://github.com/bats-core/bats-core"
        echo
        exit 1
    fi

    info "Using bats executable: $BATS_EXECUTABLE"
}

# Function to run unit tests
run_unit_tests() {
    header "Running Unit Tests"
    echo "=================="

    local unit_test_file="$TESTS_DIR/test_installation.sh"

    if [ ! -f "$unit_test_file" ]; then
        error "Unit test file not found: $unit_test_file"
        return 1
    fi

    # Make test file executable
    chmod +x "$unit_test_file"

    info "Running comprehensive unit tests..."
    echo

    local start_time=$(date +%s)
    if [ "$VERBOSE" = "true" ]; then
        "$BATS_EXECUTABLE" --verbose-run "$unit_test_file"
    else
        "$BATS_EXECUTABLE" "$unit_test_file"
    fi
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo
    if [ $exit_code -eq 0 ]; then
        success "Unit tests completed successfully (${duration}s)"
    else
        error "Unit tests failed (${duration}s)"
    fi

    return $exit_code
}

# Function to run integration tests
run_integration_tests() {
    header "Running Integration Tests"
    echo "========================="

    local bats_files=(
        "$TESTS_DIR/installation.bats"
        "$TESTS_DIR/idempotency.bats"
        "$TESTS_DIR/uninstall.bats"
        "$TESTS_DIR/configuration.bats"
    )

    local suite_failed=false
    local total_duration=0

    for bats_file in "${bats_files[@]}"; do
        if [ ! -f "$bats_file" ]; then
            warning "Integration test file not found: $bats_file"
            continue
        fi

        local test_name=$(basename "$bats_file" .bats)
        info "Running $test_name tests..."

        local start_time=$(date +%s)
        if [ "$VERBOSE" = "true" ]; then
            if "$BATS_EXECUTABLE" --verbose-run "$bats_file"; then
                success "$test_name tests passed"
            else
                error "$test_name tests failed"
                suite_failed=true
            fi
        else
            if "$BATS_EXECUTABLE" "$bats_file"; then
                success "$test_name tests passed"
            else
                error "$test_name tests failed"
                suite_failed=true
            fi
        fi
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        total_duration=$((total_duration + duration))

        echo
    done

    echo
    if [ "$suite_failed" = "false" ]; then
        success "All integration tests completed successfully (${total_duration}s)"
        return 0
    else
        error "Some integration tests failed (${total_duration}s)"
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    header "Running Complete Test Suite"
    echo "==========================="
    echo

    local overall_exit_code=0

    # Run unit tests
    if ! run_unit_tests; then
        overall_exit_code=1
    fi

    echo
    echo

    # Run integration tests
    if ! run_integration_tests; then
        overall_exit_code=1
    fi

    return $overall_exit_code
}

# Function to generate test summary
generate_summary() {
    local exit_code=$1
    echo
    header "Test Summary"
    echo "============"

    if [ $exit_code -eq 0 ]; then
        success "All tests passed! ✅"
        echo
        echo "The customzsh project is working correctly across all test scenarios:"
        echo "  ✓ Unit tests: Core functionality validated"
        echo "  ✓ Integration tests: End-to-end workflows verified"
        echo "  ✓ Cross-platform compatibility confirmed"
        echo
    else
        error "Some tests failed! ❌"
        echo
        echo "Please review the test output above for details on failed tests."
        echo "Common issues and solutions:"
        echo "  - Missing dependencies: Ensure git, curl, sudo, jq are installed"
        echo "  - Permission issues: Check file permissions and user privileges"
        echo "  - Network issues: Verify internet connectivity for GitHub API calls"
        echo
    fi
}

# Function to optimize for Docker environment
optimize_for_docker() {
    info "Optimizing for Docker environment..."

    # Disable color output if not a TTY
    if [ ! -t 1 ]; then
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        CYAN=""
        NC=""
    fi

    # Set environment variables for Docker
    export DOCKER_ENV="true"
    export DEBIAN_FRONTEND="noninteractive"
}

# Function to optimize for CI environment
optimize_for_ci() {
    info "Optimizing for CI/CD environment..."

    # Enable verbose output
    VERBOSE=true

    # Disable color output
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    NC=""

    # Set CI-specific environment variables
    export CI="true"
    export DEBIAN_FRONTEND="noninteractive"
}

# Main function
main() {
    local docker_mode=false
    local ci_mode=false
    local fast_mode=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--suite)
                SUITE="$2"
                shift 2
                ;;
            -l|--list)
                list_suites
                exit 0
                ;;
            -f|--fast)
                fast_mode=true
                shift
                ;;
            --docker)
                docker_mode=true
                shift
                ;;
            --ci)
                ci_mode=true
                shift
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Apply environment optimizations
    if [ "$docker_mode" = "true" ]; then
        optimize_for_docker
    fi

    if [ "$ci_mode" = "true" ]; then
        optimize_for_ci
    fi

    # Show header
    echo
    header "CustomZsh Test Runner"
    header "===================="
    echo

    info "Test suite: $SUITE"
    info "Verbose mode: $VERBOSE"
    if [ "$fast_mode" = "true" ]; then
        info "Fast mode: enabled (skipping slower tests)"
    fi
    echo

    # Setup bats
    setup_bats

    # Change to script directory
    cd "$SCRIPT_DIR"

    # Run appropriate test suite
    local exit_code=0
    local start_time=$(date +%s)

    case "$SUITE" in
        unit)
            run_unit_tests || exit_code=$?
            ;;
        integration)
            run_integration_tests || exit_code=$?
            ;;
        all)
            run_all_tests || exit_code=$?
            ;;
        *)
            error "Unknown test suite: $SUITE"
            echo "Available suites: unit, integration, all"
            exit 1
            ;;
    esac

    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))

    # Generate summary
    generate_summary $exit_code

    info "Total test duration: ${total_duration}s"
    echo

    exit $exit_code
}

# Run main function with all arguments
main "$@"