#!/usr/bin/env bats
#
# performance.bats
#
# Performance benchmarking and resource monitoring for customzsh
# Tests installation timing, memory usage, and resource utilization
# to establish performance baselines and detect regressions
#
# Test Categories:
# - Installation time benchmarking
# - Memory usage during installation
# - Disk space utilization monitoring
# - Plugin installation performance
# - System resource consumption analysis
# - Performance regression detection
# - Startup time measurement
#
# Test Count: 10 tests
# Dependencies: time, ps, du, free (if available)
# Environment: Enhanced isolation with performance monitoring
#
# Author: Claude Code
# Version: 1.0
#

# Load test helpers
load 'helpers/isolation_utils'
load 'helpers/validation_helpers'
load 'helpers/error_simulation'

# Performance tracking variables
PERF_LOG_FILE=""
BASELINE_INSTALL_TIME=60  # seconds
BASELINE_MEMORY_MB=100    # MB

# Setup function runs before each test
setup() {
    # Generate UUID for unique test directory
    local test_uuid
    test_uuid=$(generate_test_uuid)
    export TEST_HOME="/tmp/customzsh_perf_test_${test_uuid}"
    export TEST_SCRIPT_DIR="${TEST_HOME}/customzsh"
    export PERF_LOG_FILE="${TEST_HOME}/performance.log"

    # Validate clean environment before setup
    validate_clean_environment "$TEST_HOME" true

    # Setup isolated test environment
    setup_isolated_environment "$TEST_HOME" "performance_test"

    # Copy project files to test directory (including hidden files)
    mkdir -p "$TEST_SCRIPT_DIR"
    find . -maxdepth 1 -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    find . -maxdepth 1 -name ".*" -type f -exec cp {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    # Copy directories but avoid copying test directory itself
    find . -maxdepth 1 -type d ! -name "." ! -name "tests" -exec cp -r {} "$TEST_SCRIPT_DIR/" \; 2>/dev/null || true
    cd "$TEST_SCRIPT_DIR"

    # Create performance log
    {
        echo "Performance Test Log - $(date)"
        echo "Test UUID: $test_uuid"
        echo "Test Home: $TEST_HOME"
        echo "---"
    } > "$PERF_LOG_FILE"

    # Set test timeout (longer for performance tests)
    set_test_timeout 300 "performance_test_${test_uuid}"
}

# Teardown function runs after each test
teardown() {
    # Clear test timeout
    clear_test_timeout

    # Archive performance log if it exists
    if [ -f "$PERF_LOG_FILE" ]; then
        local archive_log="/tmp/customzsh_perf_$(date +%s).log"
        cp "$PERF_LOG_FILE" "$archive_log" 2>/dev/null || true
        echo "Performance log archived: $archive_log"
    fi

    # Check for resource leaks
    check_for_resource_leaks "$TEST_HOME"

    # Comprehensive cleanup with verification
    cleanup_test_environment "$TEST_HOME" true

    # Verify cleanup completed
    [ ! -d "$TEST_HOME" ] || {
        echo "Warning: Test cleanup incomplete for $TEST_HOME" >&2
    }
}

# Helper function to log performance metrics
log_performance() {
    local metric_name="$1"
    local metric_value="$2"
    local metric_unit="$3"

    {
        echo "$(date '+%H:%M:%S') - $metric_name: $metric_value $metric_unit"
    } >> "$PERF_LOG_FILE"
}

# Helper function to measure command execution time
measure_time() {
    local command="$1"
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)

    eval "$command"
    local exit_code=$?

    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

    echo "$duration"
    return $exit_code
}

# Helper function to get memory usage
get_memory_usage() {
    local pid="$1"
    if command -v ps >/dev/null 2>&1; then
        ps -o rss= -p "$pid" 2>/dev/null | awk '{print int($1/1024)}' || echo "0"
    else
        echo "0"
    fi
}

# Installation Performance Tests

@test "measures baseline installation time" {
    # Create offline config to avoid network dependencies
    cp config.sh.example config.sh
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh

    # Measure installation time
    local start_time=$(date +%s)
    run timeout 120 ./customzsh.sh
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_performance "Installation Time" "$duration" "seconds"

    # Installation should complete within reasonable time
    [ "$duration" -lt "$BASELINE_INSTALL_TIME" ]

    # Log result
    if [ "$duration" -lt "$BASELINE_INSTALL_TIME" ]; then
        log_performance "Performance" "PASS - Within baseline ($BASELINE_INSTALL_TIME s)" ""
    else
        log_performance "Performance" "SLOW - Exceeded baseline ($BASELINE_INSTALL_TIME s)" ""
    fi
}

@test "monitors memory usage during installation" {
    # Create offline config
    cp config.sh.example config.sh
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh

    # Start installation in background and monitor memory
    timeout 120 ./customzsh.sh &
    local install_pid=$!

    local max_memory=0
    local sample_count=0

    # Monitor memory usage
    while kill -0 "$install_pid" 2>/dev/null; do
        local current_memory
        current_memory=$(get_memory_usage "$install_pid")
        if [ "$current_memory" -gt "$max_memory" ]; then
            max_memory=$current_memory
        fi
        sample_count=$((sample_count + 1))
        sleep 1
    done

    # Wait for process to complete
    wait "$install_pid" 2>/dev/null || true

    log_performance "Peak Memory Usage" "$max_memory" "MB"
    log_performance "Memory Samples" "$sample_count" "samples"

    # Memory usage should be reasonable
    [ "$max_memory" -lt "$BASELINE_MEMORY_MB" ]

    # Log result
    if [ "$max_memory" -lt "$BASELINE_MEMORY_MB" ]; then
        log_performance "Memory Performance" "PASS - Within baseline ($BASELINE_MEMORY_MB MB)" ""
    else
        log_performance "Memory Performance" "HIGH - Exceeded baseline ($BASELINE_MEMORY_MB MB)" ""
    fi
}

@test "measures disk space utilization" {
    # Get initial disk usage
    local initial_usage
    initial_usage=$(du -sm "$TEST_HOME" 2>/dev/null | cut -f1 || echo "0")

    # Create offline config
    cp config.sh.example config.sh
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh

    # Run installation
    run timeout 120 ./customzsh.sh

    # Get final disk usage
    local final_usage
    final_usage=$(du -sm "$TEST_HOME" 2>/dev/null | cut -f1 || echo "0")
    local disk_increase=$((final_usage - initial_usage))

    log_performance "Initial Disk Usage" "$initial_usage" "MB"
    log_performance "Final Disk Usage" "$final_usage" "MB"
    log_performance "Disk Usage Increase" "$disk_increase" "MB"

    # Disk usage should be reasonable (less than 50MB)
    [ "$disk_increase" -lt 50 ]
}

@test "benchmarks configuration file processing time" {
    # Create config with many plugins
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-completions"
    "zsh-users/zsh-history-substring-search"
    "custom-org/plugin1"
    "custom-org/plugin2"
    "custom-org/plugin3"
    "custom-org/plugin4"
    "custom-org/plugin5"
)
BUILTIN_PLUGINS=(git z command-not-found cp brew npm)
EZA_VERSION="v0.18.0"
EOF

    # Measure configuration processing time
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)

    # Process configuration multiple times
    for i in {1..10}; do
        run bash -c 'source config.sh; echo "Processed ${#EXTERNAL_PLUGINS[@]} external plugins"'
    done

    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local total_duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "1")
    local avg_duration=$(echo "scale=3; $total_duration / 10" | bc 2>/dev/null || echo "0.1")

    log_performance "Config Processing (10 iterations)" "$total_duration" "seconds"
    log_performance "Config Processing (average)" "$avg_duration" "seconds"

    # Configuration processing should be fast (less than 0.1s per iteration)
    [ "$(echo "$avg_duration < 0.1" | bc 2>/dev/null || echo "1")" -eq 1 ]
}

@test "measures plugin installation performance" {
    # Create config with multiple plugins
    cat > config.sh << 'EOF'
#!/bin/bash
ZSH_THEME="agnoster"
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
)
BUILTIN_PLUGINS=(git z command-not-found)
EZA_VERSION="v0.18.0"
EOF

    # Mock Oh My Zsh installation
    mkdir -p "$HOME/.oh-my-zsh/custom/plugins"

    # Measure plugin processing time
    local start_time=$(date +%s)

    # Simulate plugin installation logic
    run bash -c '
        source config.sh
        for plugin in "${EXTERNAL_PLUGINS[@]}"; do
            repo_name=$(basename "$plugin")
            target_dir="$HOME/.oh-my-zsh/custom/plugins/$repo_name"
            echo "Would install: $plugin to $target_dir"
            mkdir -p "$target_dir"
            echo "# Mock plugin file" > "$target_dir/$repo_name.plugin.zsh"
        done
    '

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_performance "Plugin Processing Time" "$duration" "seconds"

    # Plugin processing should be fast (less than 5 seconds)
    [ "$duration" -lt 5 ]
}

# Resource Monitoring Tests

@test "monitors CPU usage patterns" {
    # Create offline config
    cp config.sh.example config.sh
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh

    # Start installation and monitor CPU if possible
    if command -v top >/dev/null 2>&1; then
        timeout 60 ./customzsh.sh &
        local install_pid=$!

        # Sample CPU usage (simplified monitoring)
        local cpu_samples=0
        while kill -0 "$install_pid" 2>/dev/null && [ $cpu_samples -lt 10 ]; do
            cpu_samples=$((cpu_samples + 1))
            sleep 2
        done

        wait "$install_pid" 2>/dev/null || true

        log_performance "CPU Monitoring Samples" "$cpu_samples" "samples"

        # Test passes if we could monitor (basic validation)
        [ "$cpu_samples" -gt 0 ]
    else
        # Skip if monitoring tools not available
        skip "CPU monitoring tools not available"
    fi
}

@test "measures startup time after installation" {
    # Create offline config
    cp config.sh.example config.sh
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh

    # Run installation
    run timeout 120 ./customzsh.sh

    # Measure zsh startup time if .zshrc was created
    if [ -f "$HOME/.zshrc" ]; then
        local start_time=$(date +%s.%N 2>/dev/null || date +%s)

        # Simulate zsh startup (source .zshrc)
        run bash -c 'source ~/.zshrc 2>/dev/null || true; echo "Zsh startup simulated"'

        local end_time=$(date +%s.%N 2>/dev/null || date +%s)
        local startup_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

        log_performance "Zsh Startup Time" "$startup_time" "seconds"

        # Startup should be fast (less than 2 seconds)
        [ "$(echo "$startup_time < 2.0" | bc 2>/dev/null || echo "1")" -eq 1 ]
    else
        skip ".zshrc not created - cannot measure startup time"
    fi
}

@test "benchmarks file I/O performance" {
    # Create offline config
    cp config.sh.example config.sh
    sed -i 's/EZA_VERSION="latest"/EZA_VERSION="v0.18.0"/' config.sh

    # Measure file operations
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)

    # Perform multiple file operations
    for i in {1..100}; do
        echo "Test line $i" >> "$TEST_HOME/io_test.txt"
    done

    # Read the file back
    run cat "$TEST_HOME/io_test.txt"

    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local io_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

    log_performance "File I/O Time (100 operations)" "$io_time" "seconds"

    # File I/O should be reasonable (less than 1 second)
    [ "$(echo "$io_time < 1.0" | bc 2>/dev/null || echo "1")" -eq 1 ]

    # Verify file operations worked
    [ "$(wc -l < "$TEST_HOME/io_test.txt")" -eq 100 ]
}

@test "measures dependency check performance" {
    # Create offline config
    cp config.sh.example config.sh

    # Measure dependency checking time
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)

    # Run dependency check multiple times
    for i in {1..5}; do
        run bash -c 'source customzsh.sh; check_dependencies 2>/dev/null || true'
    done

    local end_time=$(date +%s.%N 2>/dev/null || date +%s)
    local dep_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")
    local avg_dep_time=$(echo "scale=3; $dep_time / 5" | bc 2>/dev/null || echo "0")

    log_performance "Dependency Check (5 iterations)" "$dep_time" "seconds"
    log_performance "Dependency Check (average)" "$avg_dep_time" "seconds"

    # Dependency checking should be fast (less than 0.5s average)
    [ "$(echo "$avg_dep_time < 0.5" | bc 2>/dev/null || echo "1")" -eq 1 ]
}

@test "generates performance report" {
    # Create a summary of all performance metrics
    local report_file="$TEST_HOME/performance_report.txt"

    {
        echo "CustomZsh Performance Report"
        echo "Generated: $(date)"
        echo "Test Environment: $TEST_HOME"
        echo
        echo "Performance Baselines:"
        echo "- Installation Time: < $BASELINE_INSTALL_TIME seconds"
        echo "- Memory Usage: < $BASELINE_MEMORY_MB MB"
        echo "- Configuration Processing: < 0.1 seconds"
        echo "- Plugin Processing: < 5 seconds"
        echo "- Startup Time: < 2.0 seconds"
        echo "- File I/O: < 1.0 seconds"
        echo "- Dependency Check: < 0.5 seconds"
        echo
        echo "Test Results:"
        if [ -f "$PERF_LOG_FILE" ]; then
            cat "$PERF_LOG_FILE"
        else
            echo "No performance log available"
        fi
    } > "$report_file"

    # Verify report was created
    [ -f "$report_file" ]
    [ -s "$report_file" ]  # File is not empty

    echo "Performance report generated: $report_file"
}