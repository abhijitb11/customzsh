# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a production-ready, automated zsh setup system that provides enterprise-quality shell environment configuration. The project has been comprehensively enhanced with configuration management, automated testing, error handling, and rollback capabilities.

**Key Components:**
- `customzsh.sh`: Main installation script with enterprise features
- `install_eza.sh`: Cross-platform eza installation with version management
- `.zshrc`: Custom zsh configuration template
- `config.sh.example`: Configuration system template
- `tests/`: Comprehensive automated test suite
- `run_tests.sh`: Test runner for quality assurance

## Architecture

The project follows a modern, enterprise-grade architecture:

### Configuration-Driven Design
1. **Config File Creation**: Script creates `config.sh` from template on first run
2. **Dynamic Loading**: Configuration is sourced and validated before execution
3. **Customizable Components**: Themes, plugins, and tool versions are configurable
4. **Version Management**: Support for specific versions or latest auto-detection

### Error Handling Philosophy
- **Fail-Fast**: Scripts use `set -e` and exit immediately on errors
- **Descriptive Messages**: Standardized `info()`, `success()`, `error()` functions
- **Dependency Validation**: Pre-flight checks for required system tools
- **Graceful Degradation**: Clear error messages with suggested solutions

### Idempotency Design
- **Existence Checks**: All components check for prior installation
- **Safe Re-runs**: Multiple executions without conflicts or duplicates
- **State Awareness**: Scripts understand current system state
- **Skip Logic**: Already-installed components are bypassed

### Testing Framework
- **Bats Integration**: Professional testing with bats-core framework
- **Comprehensive Coverage**: 11 test cases covering all functionality
- **Isolated Environments**: Tests run in temporary, clean environments
- **Automated Validation**: CI/CD ready test suite

## File Structure and Responsibilities

### Core Scripts
- **`customzsh.sh`**: Primary installation orchestrator
  - Dependency validation (`check_dependencies()`)
  - Configuration loading and validation
  - Plugin management (dynamic from config)
  - Error handling and user feedback
  - Uninstall and rollback capabilities

- **`install_eza.sh`**: Specialized eza installation
  - Cross-platform package manager support
  - GitHub API integration for version detection
  - Configuration-driven version targeting
  - Installation verification and feedback

### Configuration System
- **`config.sh.example`**: Template with all available options
  - `ZSH_THEME`: Theme selection
  - `EXTERNAL_PLUGINS[]`: Array of external plugins to install
  - `EZA_VERSION`: Version specification ("latest" or specific)
  - `BUILTIN_PLUGINS[]`: Documentation of built-in plugins

- **`.gitignore`**: Excludes user-specific configurations
  - `config.sh` (user-specific)
  - Test artifacts and temporary files

### Testing Infrastructure
- **`tests/test_installation.sh`**: Main test suite
  - Dependency validation tests
  - Configuration handling tests
  - Idempotency verification
  - Error scenario testing
  - Backup/restore validation

- **`run_tests.sh`**: Test runner and orchestrator
  - Framework validation
  - Test execution
  - Result reporting

## Key Features Implemented (2025-09-19)

### 1. Configuration Management
- Dynamic plugin installation from configuration arrays
- Theme and version management
- User-specific configuration exclusion from git

### 2. Enterprise Error Handling
- Comprehensive `set -e` implementation
- Standardized output functions with consistent formatting
- Dependency validation before execution
- Descriptive error messages with actionable guidance

### 3. Complete Idempotency
- Package installation checks
- Oh My Zsh existence validation
- Plugin directory verification
- Configuration file comparison

### 4. Backup and Restore System
- Automatic `.zshrc` backup to `.zshrc.pre-customzsh`
- Uninstall functionality with `--uninstall` flag
- Complete system restoration capabilities

### 5. Version Management for eza
- GitHub API integration for latest version detection
- Configurable version targeting
- Installation verification and validation

### 6. Automated Testing
- 11 comprehensive test cases
- bats-core framework integration
- CI/CD ready test infrastructure

## Development Guidelines

### Before Making Changes
1. **Run Tests**: Always execute `./run_tests.sh` before modifications
2. **Understand Architecture**: Review configuration-driven design
3. **Follow Error Handling**: Use established `info()`, `success()`, `error()` patterns
4. **Maintain Idempotency**: Ensure multiple runs are safe

### Error Handling Patterns
```bash
# Use standardized output functions
info "Starting operation..."
if command_that_might_fail; then
    success "Operation completed successfully."
else
    error "Operation failed. Check dependencies."
    exit 1
fi

# Always check for existing components
if [ -d "$target_directory" ]; then
    info "Component already installed. Skipping."
else
    info "Installing component..."
    # installation logic
fi
```

### Testing Methodology
- **Unit Tests**: Individual function validation
- **Integration Tests**: Full workflow verification
- **Idempotency Tests**: Multiple execution safety
- **Error Scenario Tests**: Failure handling validation

### Configuration Guidelines
- All user-customizable options should go in `config.sh.example`
- Use arrays for plugin lists to enable dynamic installation
- Version specifications should support both "latest" and specific versions
- Document all configuration options clearly

## Plugin Architecture

### External Plugins (Downloaded)
- **zsh-syntax-highlighting**: Real-time command syntax highlighting
- **zsh-autosuggestions**: History-based command suggestions
- Installed via GitHub cloning to custom plugin directory
- Configurable via `EXTERNAL_PLUGINS[]` array

### Built-in Oh My Zsh Plugins (No Download)
- **git**: Git integration and aliases
- **z**: Frecency-based directory jumping
- **command-not-found**: Package suggestion for missing commands
- **cp**: Enhanced copy operations
- Enabled via `.zshrc` configuration

## Version Management

### eza Version Handling
- **Latest Detection**: GitHub API integration with `jq` parsing
- **Specific Versions**: Support for pinned version installation
- **Validation**: Version comparison and verification
- **Configuration**: User-controllable via `EZA_VERSION` setting

### Dependency Management
- **Required Tools**: `git`, `curl`, `sudo`, `jq`
- **Validation**: Pre-flight checks with `check_dependencies()`
- **Error Handling**: Clear messages for missing dependencies

## Docker Testing Infrastructure

### Multi-Distribution Container Support
The project includes comprehensive Docker-based testing across multiple Linux distributions:

- **Supported Distributions**: Ubuntu (latest, 20.04), Debian (stable), Fedora (latest), Arch Linux (latest)
- **Package Manager Detection**: Automatic detection and support for apt, dnf, pacman, zypper
- **Non-Root Testing**: Realistic user scenarios with testuser account and sudo privileges
- **Network Independence**: Tests run without external API dependencies using specific versions

### Docker Test Orchestrator (`run_docker_tests.sh`)
Advanced test execution system with enterprise capabilities:

```bash
# Test all distributions
./run_docker_tests.sh

# Test specific distributions
./run_docker_tests.sh ubuntu debian --verbose

# Available options
./run_docker_tests.sh --help
./run_docker_tests.sh --list           # List supported distributions
./run_docker_tests.sh --parallel       # Parallel execution (default)
./run_docker_tests.sh --serial         # Serial execution for debugging
./run_docker_tests.sh --verbose        # Detailed output
./run_docker_tests.sh --no-cleanup     # Keep Docker images for debugging
```

### Docker Architecture Components
- **Dockerfile.test**: Multi-stage builds optimized for different package managers
- **Parallel Execution**: Concurrent container builds and test execution
- **Resource Management**: Automatic cleanup of Docker images and containers
- **Result Collection**: Per-distribution test results and logging
- **CI/CD Ready**: Non-interactive execution suitable for automated pipelines

## Modular Test Framework

### Test Architecture Overview
The project uses a two-tier testing system:

#### Unit Tests (11 test cases)
- **File**: `tests/test_installation.sh`
- **Purpose**: Core functionality validation
- **Execution**: Fast, isolated function testing
- **Coverage**: Dependency checking, configuration handling, error scenarios

#### Integration Tests (65 test cases across 4 categories)
- **Specialized .bats files**: 1,294 total lines of test code
- **Isolated environments**: Temporary test directories with full cleanup
- **Network-free operation**: Uses specific eza version (v0.18.0) to avoid API calls

### Integration Test Categories

#### Installation Testing (`tests/installation.bats` - 25 test cases)
- End-to-end installation workflow validation
- Plugin directory creation and structure verification
- Configuration file processing and validation
- External plugin installation simulation
- Built-in plugin documentation verification

#### Idempotency Testing (`tests/idempotency.bats` - 12 test cases)
- Multi-run safety validation
- State consistency across executions
- Plugin installation skip logic
- Configuration loading stability
- File permission preservation

#### Uninstall Testing (`tests/uninstall.bats` - 14 test cases)
- Complete system removal validation
- Backup restoration functionality
- Plugin directory cleanup verification
- User file preservation testing
- Multiple uninstall run safety

#### Configuration Testing (`tests/configuration.bats` - 14 test cases)
- Theme customization validation
- Plugin array processing verification
- Version specification handling
- Configuration syntax validation
- Edge case handling for plugin names

### Enhanced Test Runner (`run_tests.sh`)
Professional test orchestration with flexible execution modes:

```bash
# Execute different test suites
./run_tests.sh --suite all          # All tests (default)
./run_tests.sh --suite unit         # Unit tests only
./run_tests.sh --suite integration  # Integration tests only

# Execution modes
./run_tests.sh --verbose            # Detailed output
./run_tests.sh --fast              # Skip slower tests
./run_tests.sh --docker            # Docker environment optimization
./run_tests.sh --ci                # CI/CD environment optimization

# Information commands
./run_tests.sh --list              # List available test suites
./run_tests.sh --help              # Show usage information
```

## Plugin Installation Validation

### Comprehensive Plugin Testing
The testing framework validates complete plugin installation workflows:

#### External Plugin Installation
- **GitHub Repository Cloning**: Simulated and validated git clone operations
- **Directory Structure**: Verification of `~/.oh-my-zsh/custom/plugins/` structure
- **Plugin Configuration**: Array processing from `config.sh` validation
- **Idempotency**: Skip logic for already-installed plugins

#### Verified Plugins
- **zsh-autosuggestions**: Fish-like command autosuggestions
- **zsh-syntax-highlighting**: Real-time command syntax highlighting
- **Configuration Validation**: .zshrc plugin array verification
- **Repository Mapping**: GitHub repository to local directory mapping

#### Plugin Test Coverage
- Plugin directory creation logic
- Configuration array processing (`EXTERNAL_PLUGINS[]`)
- Built-in plugin documentation (`BUILTIN_PLUGINS[]`)
- Network simulation for GitHub cloning
- Plugin enablement in .zshrc configuration

## Testing Coverage

### Unit Test Coverage (11 test cases)
1. Dependency checking functionality
2. Configuration file creation and validation
3. Uninstall flag handling
4. Idempotency for zsh installation check
5. .zshrc backup functionality
6. Configuration file format validation
7. eza installation script handling
8. Error handling prevention
9. Output helper functions
10. Plugin installation logic
11. Missing file graceful handling

### Integration Test Coverage (65 test cases)
1. **Installation Tests (25 cases)**: Complete workflow validation
2. **Idempotency Tests (12 cases)**: Multi-run safety verification
3. **Uninstall Tests (14 cases)**: System removal and restoration
4. **Configuration Tests (14 cases)**: Customization and validation

### Cross-Platform Validation
- Ubuntu (latest and 20.04) with apt package manager
- Debian (stable) with apt package manager
- Fedora (latest) with dnf package manager
- Arch Linux (latest) with pacman package manager
- Automatic package manager detection and adaptation

## Maintenance Notes

### When Adding New Features
- Update `config.sh.example` if user-configurable
- Add corresponding test cases to appropriate .bats files
- Test across all distributions: `./run_docker_tests.sh`
- Update documentation (README, CHANGELOG, CLAUDE.md)
- Ensure idempotency is maintained
- Follow established error handling patterns
- Validate plugin installation if plugin-related changes

### Docker Testing Workflow
For comprehensive validation during development:

```bash
# Quick local validation
./run_tests.sh --suite unit          # Fast unit tests
./run_tests.sh --suite integration   # Local integration tests

# Cross-platform validation
./run_docker_tests.sh ubuntu         # Test specific distribution
./run_docker_tests.sh --parallel     # Test all distributions
./run_docker_tests.sh --verbose      # Detailed debugging output

# CI/CD integration
./run_tests.sh --ci                  # CI-optimized local tests
./run_docker_tests.sh --serial       # Serial Docker tests for CI
```

### Plugin Development and Testing
When working with plugin functionality:

1. **Plugin Configuration**: Update `EXTERNAL_PLUGINS[]` arrays in config files
2. **Installation Logic**: Verify plugin cloning and directory creation in `customzsh.sh`
3. **Integration Testing**: Add test cases to `tests/installation.bats` for new plugins
4. **Cross-Platform Validation**: Ensure plugin installation works across all Docker distributions
5. **.zshrc Integration**: Validate plugin enablement in the Oh My Zsh configuration

### When Modifying Existing Features
- Run full test suite before and after changes
- Verify backward compatibility with existing configurations
- Update tests if behavior changes
- Document breaking changes in CHANGELOG

### Release Process
1. Ensure all unit tests pass: `./run_tests.sh --suite unit`
2. Run integration tests: `./run_tests.sh --suite integration`
3. Validate cross-platform compatibility: `./run_docker_tests.sh`
4. Update CHANGELOG.md with detailed changes
5. Update version references if applicable
6. Test installation on clean system
7. Verify uninstall functionality works correctly
8. Validate Docker testing infrastructure with all distributions

## Recent Major Updates

### 2025-09-20: Docker Testing Infrastructure Release
This second major release adds enterprise-grade cross-platform testing capabilities:

- **Docker Cross-Platform Testing**: Multi-distribution validation across Ubuntu, Debian, Fedora, and Arch Linux
- **Modular Test Framework**: 65 new integration tests across 4 specialized categories (1,294 lines of test code)
- **Professional Test Orchestration**: Enhanced test runner with unit/integration separation and CI/CD optimization
- **Plugin Installation Validation**: Comprehensive testing of zsh-autosuggestions and zsh-syntax-highlighting plugins
- **Network-Independent Testing**: Removed external API dependencies for reliable CI/CD execution
- **Enterprise Testing Infrastructure**: Parallel execution, automatic cleanup, and detailed result reporting

### 2025-09-19: Major Enterprise Enhancement Release
Initial transformation from a basic setup script to an enterprise-quality automation system:

- **Production-Ready Architecture**: Configuration management, error handling, testing
- **Professional Quality**: Comprehensive documentation, standardized patterns
- **Enterprise Features**: Backup/restore, uninstall, version management
- **Reliability**: Automated testing, idempotency, dependency validation
- **Maintainability**: Modular design, clear separation of concerns

The project now serves as a reference implementation for shell automation best practices with comprehensive cross-platform testing validation.