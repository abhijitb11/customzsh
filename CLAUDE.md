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

## Testing Coverage

The test suite validates:
1. Dependency checking functionality
2. Configuration file creation and validation
3. Uninstall flag handling
4. Idempotency for all components
5. Backup and restore mechanisms
6. Plugin installation logic
7. Version management capabilities
8. Error handling scenarios
9. Output function consistency
10. Missing file graceful handling
11. Cross-platform compatibility

## Maintenance Notes

### When Adding New Features
- Update `config.sh.example` if user-configurable
- Add corresponding test cases
- Update documentation (README, CHANGELOG, CLAUDE.md)
- Ensure idempotency is maintained
- Follow established error handling patterns

### When Modifying Existing Features
- Run full test suite before and after changes
- Verify backward compatibility with existing configurations
- Update tests if behavior changes
- Document breaking changes in CHANGELOG

### Release Process
1. Ensure all tests pass: `./run_tests.sh`
2. Update CHANGELOG.md with detailed changes
3. Update version references if applicable
4. Test installation on clean system
5. Verify uninstall functionality works correctly

## Recent Major Updates (2025-09-19)

This release represents a complete transformation from a basic setup script to an enterprise-quality automation system with:

- **Production-Ready Architecture**: Configuration management, error handling, testing
- **Professional Quality**: Comprehensive documentation, standardized patterns
- **Enterprise Features**: Backup/restore, uninstall, version management
- **Reliability**: Automated testing, idempotency, dependency validation
- **Maintainability**: Modular design, clear separation of concerns

The project now serves as a reference implementation for shell automation best practices.