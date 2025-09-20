#!/bin/bash
#
# Test runner for customzsh project
# This script runs the automated test suite using bats
#

set -e

echo "CustomZsh Test Runner"
echo "===================="

# Check if bats is available
if [ ! -f "tests/bats/bin/bats" ]; then
    echo "Error: bats testing framework not found."
    echo "Please ensure git submodules are initialized:"
    echo "  git submodule update --init --recursive"
    exit 1
fi

# Make test scripts executable
chmod +x tests/test_installation.sh

# Run the test suite
echo "Running test suite..."
./tests/bats/bin/bats tests/test_installation.sh

echo ""
echo "Test run complete!"