# CustomZsh Test Suite Documentation

## Overview

The CustomZsh test suite is an enterprise-grade testing framework providing comprehensive validation of shell environment automation across multiple platforms. This documentation describes the complete test infrastructure, execution methods, and maintenance procedures.

## Test Suite Architecture

### Test Categories

The test suite is organized into **6 specialized test files** covering different aspects of the system:

#### 1. **Installation Tests** (`installation.bats`)
- **Purpose**: End-to-end installation workflow validation
- **Test Count**: 25 tests
- **Categories**:
  - Installation script validation and execution
  - Configuration file creation and validation
  - Dependency checking and system requirements
  - Plugin installation and directory structure
  - Integration with eza installation script
  - Error handling and graceful degradation
  - Network-free testing with offline configurations

#### 2. **Configuration Tests** (`configuration.bats`)
- **Purpose**: Configuration customization and validation
- **Test Count**: 14 tests
- **Categories**:
  - Theme configuration and customization
  - External plugin array management
  - Built-in plugin documentation and validation
  - Version specification for eza and other tools
  - Configuration file format validation
  - Edge cases in configuration parsing
  - Multi-run safety and consistency

#### 3. **Idempotency Tests** (`idempotency.bats`)
- **Purpose**: Multi-run safety validation
- **Test Count**: 12 tests
- **Categories**:
  - Configuration file creation idempotency
  - Oh My Zsh installation skip logic
  - Plugin installation duplicate detection
  - Backup file handling consistency
  - State preservation across multiple runs
  - File permission and ownership consistency
  - System state validation after repeated execution

#### 4. **Uninstall Tests** (`uninstall.bats`)
- **Purpose**: Complete system removal and restoration
- **Test Count**: 14 tests
- **Categories**:
  - Uninstall flag recognition and processing
  - Complete Oh My Zsh removal and cleanup
  - Configuration file restoration and backup handling
  - Plugin directory cleanup and validation
  - System state restoration to pre-installation state
  - User data preservation during uninstall
  - Multiple uninstall run safety verification

#### 5. **Error Scenarios Tests** (`error_scenarios.bats`) ✨ NEW
- **Purpose**: Comprehensive error condition testing
- **Test Count**: 14 tests
- **Categories**:
  - Network failures (git clone, GitHub API, DNS)
  - Permission issues (sudo, directory access, filesystem)
  - Repository validation (invalid URLs, non-existent repos)
  - System resource constraints (disk space, memory)
  - Configuration errors (malformed files, invalid syntax)

#### 6. **Edge Cases Tests** (`edge_cases.bats`) ✨ NEW
- **Purpose**: Malformed input and boundary condition testing
- **Test Count**: 23 tests
- **Categories**:
  - Malformed configuration files
  - Invalid plugin name formats
  - Unicode and special character handling
  - Extremely long inputs and boundary conditions
  - Shell injection attempts and security edge cases
  - File permission and access edge cases

### Test Infrastructure

#### Helper Utilities (`tests/helpers/`)

**1. Isolation Utilities** (`isolation_utils.bash`)
- 14 functions for test environment management
- UUID-based unique test directory generation
- Comprehensive test cleanup and verification
- Resource leak detection and prevention
- Test timeout management
- Environment variable isolation

**2. Validation Helpers** (`validation_helpers.bash`)
- 10 functions for comprehensive validation
- Installation completeness verification
- Plugin installation validation
- Configuration format checking
- Backup integrity validation
- Dependency availability checking

**3. Error Simulation** (`error_simulation.bash`)
- 12 functions for error condition simulation
- Network failure simulation
- Permission denied scenarios
- Repository validation mocking
- Disk space exhaustion testing
- Corrupted download simulation

## Test Execution

### Local Execution

#### Run All Tests
```bash
./run_tests.sh                    # Complete test suite
./run_tests.sh --verbose          # Detailed output
```

#### Run Specific Test Suites
```bash
./run_tests.sh --suite unit       # Unit tests only (11 tests)
./run_tests.sh --suite integration # Integration tests (100+ tests)
./run_tests.sh --fast             # Skip slower tests
```

#### Run Individual Test Files
```bash
# Run specific test files
./tests/bats/bin/bats tests/installation.bats
./tests/bats/bin/bats tests/error_scenarios.bats
./tests/bats/bin/bats tests/edge_cases.bats

# Run with filters
./tests/bats/bin/bats tests/installation.bats --filter "config"
```

### Docker Cross-Platform Execution

#### Test All Distributions
```bash
./run_docker_tests.sh             # All distributions in parallel
./run_docker_tests.sh --verbose   # Detailed logging
./run_docker_tests.sh --serial    # Sequential execution
```

#### Test Specific Distributions
```bash
./run_docker_tests.sh ubuntu      # Ubuntu only
./run_docker_tests.sh debian fedora # Multiple specific distributions
```

#### Supported Distributions
- **Ubuntu**: latest, 20.04
- **Debian**: stable
- **Fedora**: latest
- **Arch Linux**: latest

### Test Execution Modes

#### Performance Modes
- **Parallel**: Default mode for faster execution
- **Serial**: Sequential execution for debugging
- **Fast**: Skip slower network-dependent tests
- **Verbose**: Detailed output for troubleshooting

#### Environment Modes
- **Local**: Direct execution on host system
- **Docker**: Containerized cross-platform testing
- **CI/CD**: Non-interactive automated execution

## Test Isolation and Safety

### Advanced Isolation Features

#### UUID-Based Test Directories
- Prevents test collision during parallel execution
- Format: `/tmp/customzsh_<test_type>_<uuid>`
- Automatic cleanup with verification

#### Resource Leak Detection
- Process monitoring for hanging customzsh instances
- Temporary file and directory leak detection
- Docker environment optimization
- Comprehensive cleanup verification

#### Test Timeouts
- Installation tests: 300 seconds
- Configuration tests: 180 seconds
- Idempotency tests: 240 seconds
- Uninstall tests: 180 seconds
- Error scenario tests: 120 seconds
- Edge case tests: 120 seconds

### Environment Variables

Tests use isolated environment variables to prevent interference:
- `TEST_HOME`: Unique test directory
- `TEST_SCRIPT_DIR`: Script location within test environment
- `TEST_UUID`: Unique identifier for test run
- `HOME`, `USER`, `SUDO_USER`: Isolated for test safety

## Test Dependencies

### System Requirements
- **Required**: `git`, `curl`, `sudo`, `jq`, `zsh`
- **Optional**: `wget`, `tar`, `gzip`, `unzip`
- **Testing**: `bats-core`, `docker` (for cross-platform testing)

### Docker Requirements
- Docker Engine 20.10+
- Minimum 2GB available disk space
- Network connectivity for image downloads

## Test Maintenance

### Adding New Tests

#### 1. Choose Appropriate Test File
- **Installation**: Core installation workflow
- **Configuration**: Configuration options and validation
- **Idempotency**: Multi-run safety
- **Uninstall**: Removal and restoration
- **Error Scenarios**: Error condition handling
- **Edge Cases**: Malformed input and boundaries

#### 2. Follow Test Structure
```bash
@test "descriptive test name" {
    # Test implementation
    run command_to_test

    # Assertions
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected_pattern" ]]
}
```

#### 3. Use Helper Functions
```bash
# Use isolation helpers
local test_uuid
test_uuid=$(generate_test_uuid)

# Use validation helpers
validate_installation_completeness "$TEST_HOME"

# Use error simulation
simulate_network_failure "dns" "/tmp/mock_dir"
```

#### 4. Update Documentation
- Update test count in file headers
- Document new test categories
- Update this documentation file

### Test Quality Guidelines

#### Test Naming
- Use descriptive, action-oriented names
- Include the condition being tested
- Format: "handles/validates/creates/removes [specific condition]"

#### Test Isolation
- Always use helper functions for setup/teardown
- Ensure tests can run independently
- Clean up all created resources

#### Test Assertions
- Use specific, meaningful assertions
- Test both success and failure conditions
- Validate expected output patterns

#### Error Handling
- Test error conditions thoroughly
- Verify graceful degradation
- Ensure proper error messages

## Test Results and Reporting

### Test Output Format

#### Summary Format
```
[SUCCESS] All tests passed! ✅
  ✓ Unit tests: Core functionality validated
  ✓ Integration tests: End-to-end workflows verified
  ✓ Cross-platform compatibility confirmed
```

#### Detailed Output (Verbose Mode)
- Individual test execution status
- Timing information
- Resource usage statistics
- Error details for failed tests

### Failure Investigation

#### Common Failure Patterns
1. **Resource Leaks**: Check for hanging processes
2. **Permission Issues**: Verify test environment isolation
3. **Network Dependencies**: Ensure offline test configurations
4. **Timing Issues**: Check test timeout settings

#### Debugging Commands
```bash
# Run with maximum verbosity
./run_tests.sh --suite integration --verbose

# Run single test with debugging
./tests/bats/bin/bats tests/installation.bats --filter "specific_test" --verbose-run

# Check Docker environment
./run_docker_tests.sh ubuntu --verbose --no-cleanup
```

## Performance Characteristics

### Test Execution Times

#### Local Execution
- **Unit Tests**: ~10 seconds (11 tests)
- **Integration Tests**: ~2-5 minutes (100+ tests)
- **Complete Suite**: ~3-7 minutes (120+ tests)

#### Docker Execution
- **Single Distribution**: ~3-8 minutes
- **All Distributions**: ~10-25 minutes (parallel)
- **Build Time**: ~2-5 minutes per distribution

### Resource Requirements

#### Local Testing
- **Disk Space**: ~50MB temporary files
- **Memory**: ~100MB peak usage
- **CPU**: Moderate during test execution

#### Docker Testing
- **Disk Space**: ~2GB for all distribution images
- **Memory**: ~500MB per concurrent container
- **Network**: ~500MB for initial image downloads

## Integration with CI/CD

### GitHub Actions Integration
```yaml
- name: Run CustomZsh Tests
  run: |
    ./run_tests.sh --ci --suite all
    ./run_docker_tests.sh --serial
```

### Environment Variables for CI
- `CI=true`: Enables CI-optimized test execution
- `PARALLEL=false`: Forces serial execution
- `CLEANUP=true`: Ensures complete cleanup
- `VERBOSE=false`: Reduces output verbosity

## Test Coverage Matrix

| Component | Unit | Integration | Error | Edge | Docker |
|-----------|------|-------------|-------|------|--------|
| Installation | ✅ | ✅ | ✅ | ✅ | ✅ |
| Configuration | ✅ | ✅ | ✅ | ✅ | ✅ |
| Idempotency | ✅ | ✅ | ✅ | ✅ | ✅ |
| Uninstall | ✅ | ✅ | ✅ | ✅ | ✅ |
| Error Handling | ✅ | ✅ | ✅ | ✅ | ✅ |
| Edge Cases | ✅ | ✅ | ✅ | ✅ | ✅ |

## Troubleshooting Guide

### Common Issues

#### Test Hangs or Timeouts
- **Cause**: Network dependencies or resource locks
- **Solution**: Use `--fast` mode or check timeout settings
- **Debug**: Run individual tests with verbose output

#### Resource Leak Warnings
- **Cause**: Previous test runs not cleaned up properly
- **Solution**: Manual cleanup with `pkill -f customzsh; rm -rf /tmp/customzsh*test*`
- **Prevention**: Ensure proper test isolation

#### Docker Build Failures
- **Cause**: Network connectivity or disk space issues
- **Solution**: Check Docker daemon and available space
- **Debug**: Run `docker build` manually with verbose output

#### Permission Denied Errors
- **Cause**: Insufficient permissions or SELinux restrictions
- **Solution**: Check user permissions and security contexts
- **Workaround**: Run with appropriate sudo privileges

### Support and Maintenance

For test-related issues:
1. Check test execution logs for specific error messages
2. Verify system dependencies are installed
3. Ensure sufficient disk space and permissions
4. Review test isolation and cleanup procedures
5. Consult individual test file documentation

## Version History

- **v2.0** (2025-09-20): Enterprise enhancement with error scenarios, edge cases, and advanced isolation
- **v1.0** (2025-09-19): Initial comprehensive test suite with Docker integration

---

*This documentation is maintained alongside the test suite and should be updated when adding new tests or modifying test infrastructure.*