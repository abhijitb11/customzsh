#!/bin/bash
#
# run_docker_tests.sh
#
# Docker-based cross-platform testing runner for customzsh
# Tests installation and functionality across multiple Linux distributions
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_RESULTS_DIR="$SCRIPT_DIR/test_results"
PARALLEL=${PARALLEL:-true}
CLEANUP=${CLEANUP:-true}
VERBOSE=${VERBOSE:-false}
TEST_SUITE=${TEST_SUITE:-"integration"}
INCLUDE_PERF=${INCLUDE_PERF:-false}
INCLUDE_COMPAT=${INCLUDE_COMPAT:-false}

# Test distribution configurations
# Format: "image:tag,package_manager,distro_name"
DISTROS=(
    "ubuntu:latest,apt-get,ubuntu"
    "ubuntu:20.04,apt-get,ubuntu-20.04"
    "debian:stable,apt-get,debian"
    "fedora:latest,dnf,fedora"
    "archlinux:latest,pacman,arch"
)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%H:%M:%S')] $message${NC}"
}

info() { print_status "$BLUE" "$1"; }
success() { print_status "$GREEN" "$1"; }
warning() { print_status "$YELLOW" "$1"; }
error() { print_status "$RED" "$1"; }

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [DISTRO...]

Docker-based cross-platform testing for customzsh

OPTIONS:
    -h, --help          Show this help message
    -p, --parallel      Enable parallel testing (default: true)
    -s, --serial        Disable parallel testing
    -v, --verbose       Enable verbose output
    -c, --no-cleanup    Skip cleanup of Docker images
    -l, --list          List available distributions
    -r, --results-dir   Directory for test results (default: ./test_results)
    --suite SUITE       Run specific test suite (unit, integration, all, fast)
    --include-perf      Include performance benchmarking tests
    --include-compat    Include compatibility tests

DISTRO:
    Specific distribution to test (e.g., ubuntu, debian, fedora, arch)
    If not specified, all distributions will be tested

Examples:
    $0                          # Test all distributions in parallel
    $0 ubuntu debian            # Test only Ubuntu and Debian
    $0 --serial --verbose       # Test all distributions serially with verbose output
    $0 --list                   # List available distributions

EOF
}

# Function to list available distributions
list_distros() {
    info "Available distributions for testing:"
    for distro_config in "${DISTROS[@]}"; do
        IFS="," read -r image pkg_manager distro_name <<< "$distro_config"
        echo "  - $distro_name ($image)"
    done
}

# Function to cleanup Docker resources
cleanup_docker() {
    if [ "$CLEANUP" = "true" ]; then
        info "Cleaning up Docker resources..."

        # Remove test images
        for distro_config in "${DISTROS[@]}"; do
            IFS="," read -r image pkg_manager distro_name <<< "$distro_config"
            local test_image="customzsh-test-$distro_name"
            if docker image inspect "$test_image" >/dev/null 2>&1; then
                docker rmi "$test_image" >/dev/null 2>&1 || true
            fi
        done

        # Remove dangling images
        docker image prune -f >/dev/null 2>&1 || true

        success "Docker cleanup completed"
    fi
}

# Function to setup test environment
setup_test_env() {
    # Create results directory
    mkdir -p "$TEST_RESULTS_DIR"

    # Setup cleanup trap
    trap cleanup_docker EXIT

    # Verify Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed or not available in PATH"
        exit 1
    fi

    # Verify Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon is not running"
        exit 1
    fi

    info "Docker environment verified"
}

# Function to build Docker image for a distribution
build_docker_image() {
    local distro_config=$1
    IFS="," read -r image pkg_manager distro_name <<< "$distro_config"
    local test_image="customzsh-test-$distro_name"

    info "Building Docker image for $distro_name ($image)..."

    local build_log="$TEST_RESULTS_DIR/build_$distro_name.log"

    if docker build \
        --build-arg BASE_IMAGE="$image" \
        --build-arg PKG_MANAGER="$pkg_manager" \
        --build-arg DISTRO_NAME="$distro_name" \
        -t "$test_image" \
        -f Dockerfile.test \
        . > "$build_log" 2>&1; then
        success "Built Docker image for $distro_name"
        return 0
    else
        error "Failed to build Docker image for $distro_name"
        if [ "$VERBOSE" = "true" ]; then
            cat "$build_log"
        fi
        return 1
    fi
}

# Function to run tests for a distribution
run_test_for_distro() {
    local distro_config=$1
    IFS="," read -r image pkg_manager distro_name <<< "$distro_config"
    local test_image="customzsh-test-$distro_name"
    local test_log="$TEST_RESULTS_DIR/test_$distro_name.log"
    local start_time=$(date +%s)

    info "Running tests for $distro_name..."

    # Prepare test command based on suite selection
    local test_cmd="./run_tests.sh --suite $TEST_SUITE"
    if [ "$INCLUDE_PERF" = "true" ]; then
        test_cmd="$test_cmd && ./tests/bats/bin/bats tests/performance.bats"
    fi
    if [ "$INCLUDE_COMPAT" = "true" ]; then
        test_cmd="$test_cmd && ./tests/bats/bin/bats tests/compatibility.bats"
    fi

    # Run the Docker container with tests
    if docker run --rm \
        --name "customzsh-test-$distro_name-$$" \
        -v "$TEST_RESULTS_DIR:/tmp/results" \
        "$test_image" \
        bash -c "$test_cmd" > "$test_log" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Tests passed for $distro_name (${duration}s)"
        echo "PASS" > "$TEST_RESULTS_DIR/result_$distro_name"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error "Tests failed for $distro_name (${duration}s)"
        echo "FAIL" > "$TEST_RESULTS_DIR/result_$distro_name"
        if [ "$VERBOSE" = "true" ]; then
            echo "--- Test output for $distro_name ---"
            cat "$test_log"
            echo "--- End of output ---"
        fi
        return 1
    fi
}

# Function to run test for single distribution (used for parallel execution)
test_single_distro() {
    local distro_config=$1
    IFS="," read -r image pkg_manager distro_name <<< "$distro_config"

    # Build image
    if ! build_docker_image "$distro_config"; then
        echo "FAIL" > "$TEST_RESULTS_DIR/result_$distro_name"
        return 1
    fi

    # Run tests
    run_test_for_distro "$distro_config"
}

# Function to run tests in parallel
run_parallel_tests() {
    local distros_to_test=("$@")
    local pids=()

    info "Running tests in parallel for ${#distros_to_test[@]} distributions..."

    # Start background processes
    for distro_config in "${distros_to_test[@]}"; do
        test_single_distro "$distro_config" &
        pids+=($!)
    done

    # Wait for all processes to complete
    local exit_code=0
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            exit_code=1
        fi
    done

    return $exit_code
}

# Function to run tests serially
run_serial_tests() {
    local distros_to_test=("$@")
    local exit_code=0

    info "Running tests serially for ${#distros_to_test[@]} distributions..."

    for distro_config in "${distros_to_test[@]}"; do
        if ! test_single_distro "$distro_config"; then
            exit_code=1
        fi
    done

    return $exit_code
}

# Function to generate test report
generate_report() {
    local distros_to_test=("$@")
    local total=0
    local passed=0
    local failed=0

    info "Generating test report..."
    echo
    echo "=================================="
    echo "     DOCKER TEST RESULTS"
    echo "=================================="
    echo

    for distro_config in "${distros_to_test[@]}"; do
        IFS="," read -r image pkg_manager distro_name <<< "$distro_config"
        total=$((total + 1))

        if [ -f "$TEST_RESULTS_DIR/result_$distro_name" ]; then
            local result=$(cat "$TEST_RESULTS_DIR/result_$distro_name")
            if [ "$result" = "PASS" ]; then
                success "$distro_name: PASSED"
                passed=$((passed + 1))
            else
                error "$distro_name: FAILED"
                failed=$((failed + 1))
            fi
        else
            error "$distro_name: NO RESULT"
            failed=$((failed + 1))
        fi
    done

    echo
    echo "=================================="
    echo "Summary: $passed/$total passed, $failed/$total failed"
    echo "Test logs available in: $TEST_RESULTS_DIR"
    echo "=================================="
    echo

    if [ $failed -eq 0 ]; then
        success "All tests passed! 🎉"
        return 0
    else
        error "$failed test(s) failed"
        return 1
    fi
}

# Main function
main() {
    local distros_to_test=()
    local specific_distros=()

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -p|--parallel)
                PARALLEL=true
                shift
                ;;
            -s|--serial)
                PARALLEL=false
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -c|--no-cleanup)
                CLEANUP=false
                shift
                ;;
            -l|--list)
                list_distros
                exit 0
                ;;
            -r|--results-dir)
                TEST_RESULTS_DIR="$2"
                shift 2
                ;;
            --suite)
                TEST_SUITE="$2"
                shift 2
                ;;
            --include-perf)
                INCLUDE_PERF=true
                shift
                ;;
            --include-compat)
                INCLUDE_COMPAT=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                specific_distros+=("$1")
                shift
                ;;
        esac
    done

    # Setup test environment
    setup_test_env

    # Determine which distros to test
    if [ ${#specific_distros[@]} -eq 0 ]; then
        # Test all distributions
        distros_to_test=("${DISTROS[@]}")
        info "Testing all available distributions"
    else
        # Test specific distributions
        for target in "${specific_distros[@]}"; do
            local found=false
            for distro_config in "${DISTROS[@]}"; do
                IFS="," read -r image pkg_manager distro_name <<< "$distro_config"
                if [[ "$distro_name" == *"$target"* ]] || [[ "$image" == *"$target"* ]]; then
                    distros_to_test+=("$distro_config")
                    found=true
                fi
            done
            if [ "$found" = "false" ]; then
                warning "Distribution '$target' not found in available distributions"
            fi
        done

        if [ ${#distros_to_test[@]} -eq 0 ]; then
            error "No valid distributions specified"
            list_distros
            exit 1
        fi

        info "Testing specific distributions: ${specific_distros[*]}"
    fi

    # Run tests
    local start_time=$(date +%s)
    if [ "$PARALLEL" = "true" ] && [ ${#distros_to_test[@]} -gt 1 ]; then
        run_parallel_tests "${distros_to_test[@]}"
    else
        run_serial_tests "${distros_to_test[@]}"
    fi
    local test_exit_code=$?
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))

    # Generate report
    generate_report "${distros_to_test[@]}"
    local report_exit_code=$?

    info "Total test duration: ${total_duration}s"

    # Exit with appropriate code
    if [ $test_exit_code -eq 0 ] && [ $report_exit_code -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function with all arguments
main "$@"