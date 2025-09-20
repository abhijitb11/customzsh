# Qwen Code Context

This is a custom zsh setup script that automates the installation and configuration of Oh My Zsh with popular plugins and modern tools. The project provides a complete, ready-to-use zsh environment with enhanced productivity features.

## Project Overview

The project has been significantly enhanced with enterprise-grade features including:
- Configuration management system with `config.sh.example`
- Automated testing framework with bats-core
- Enterprise error handling with fail-fast behavior
- Complete idempotency for safe re-execution
- Backup and restore system for configuration protection
- Version management for eza tool
- Cross-platform support for multiple package managers (apt, dnf, pacman, zypper, brew)
- Docker-based cross-platform testing infrastructure

## Key Components

### `customzsh.sh`
- Main installation script with enterprise features
- Configuration-driven architecture
- Dynamic plugin installation system
- Comprehensive error handling and validation
- Uninstall and rollback capabilities
- Professional output formatting

### `install_eza.sh` 
- Dedicated cross-platform eza installation script with comprehensive package manager support (apt, dnf, pacman, zypper, brew)
- For Debian/Ubuntu systems, uses the official deb.gierens.de repository as primary fallback when eza is not available in default repositories, with PPA as secondary fallback
- Includes proper error handling and installation verification

### `.zshrc`
- Pre-configured zsh settings with agnoster theme
- Essential plugins (git, zsh-autosuggestions, zsh-syntax-highlighting, z, command-not-found, cp)
- eza aliases for enhanced directory listing (`alias ls="eza --icons --group-directories-first"`)

### Configuration System
- `config.sh.example`: Template with all available options
  - `ZSH_THEME`: Theme selection
  - `EXTERNAL_PLUGINS[]`: Array of external plugins to install
  - `EZA_VERSION`: Version specification ("latest" or specific)
  - `BUILTIN_PLUGINS[]`: Documentation of built-in plugins

### Testing Infrastructure
- `run_tests.sh`: Test runner for quality assurance with unit/integration separation
- `tests/`: Comprehensive automated test suite with 11 unit tests and 65 integration tests across 4 categories
- `run_docker_tests.sh`: Docker-based cross-platform testing across Ubuntu, Debian, Fedora, and Arch Linux

## Plugin Details

### Custom Plugins (Externally Downloaded)
- **zsh-syntax-highlighting**: Provides syntax highlighting for commands as you type
- **zsh-autosuggestions**: Suggests commands as you type based on history and completions

### Built-in Oh My Zsh Plugins (No Download Required)
- **z**: Jump quickly to frequently used directories
- **command-not-found**: Provides command suggestions when you type a command that doesn't exist (requires command-not-found package)
- **cp**: Enhanced copy command with additional aliases and functionality
- **git**: Git integration with useful aliases and functions

## Recent Updates (2025-09-20)

### Docker Testing Infrastructure Release
- Multi-distribution Docker container support (Ubuntu, Debian, Fedora, Arch Linux)
- Cross-platform package manager detection and support (apt, dnf, pacman, zypper)
- Parallel and serial test execution modes for optimal performance
- Automatic Docker resource cleanup and management
- Network-free testing using specific version configurations

### Enhanced Test Suite
- 65 new integration test cases across 4 specialized .bats files
- Plugin installation validation for external plugins
- Comprehensive test runner with flexible execution options

## Recent Updates (2025-09-19)

### Configuration Management System
- Customizable themes, external plugins, and tool versions via `config.sh`
- Dynamic plugin installation from configuration arrays
- Version management for eza (specific versions or "latest" auto-detection)
- User-specific configurations excluded from git via `.gitignore`

### Enterprise Error Handling
- Fail-fast behavior with `set -e` in all scripts
- Explicit error checking with descriptive messages
- Comprehensive dependency validation with `check_dependencies()` function
- Standardized output functions: `info()`, `success()`, `error()`

### Complete Idempotency
- Existence checks for packages, Oh My Zsh, plugins, and configuration files
- Smart skipping of already-installed components
- Safe multiple runs without conflicts or duplicates

### Backup and Restore System
- Automatic backup of existing `.zshrc` to `.zshrc.pre-customzsh`
- Complete uninstall functionality with `--uninstall` flag
- Original configuration restoration capabilities

## Usage

```bash
chmod +x customzsh.sh
./customzsh.sh
```

The script will:
1. Install required dependencies (zsh, git, curl)
2. Install eza (modern ls replacement) 
3. Set up Oh My Zsh framework
4. Install zsh plugins
5. Configure .zshrc with agnoster theme and plugins
6. Change default shell to zsh

## Development Conventions

The project follows a modular approach:
- The main installation script (`customzsh.sh`) orchestrates the entire process
- The eza installation is separated into its own script (`install_eza.sh`) for better maintainability
- Configuration is handled through `.zshrc` which is copied to user's home directory
- All scripts are designed to be idempotent and safe to run multiple times

## Testing

The project includes comprehensive automated testing:
1. Unit tests (11 test cases) covering core functionality
2. Integration tests (65 test cases) across 4 categories
3. Docker-based cross-platform testing across Ubuntu, Debian, Fedora, and Arch Linux