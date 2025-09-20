# customzsh

A production-ready, automated zsh setup system that provides comprehensive shell environment configuration with Oh My Zsh, curated plugins, and modern tools. Features enterprise-quality error handling, configuration management, automated testing, and complete rollback capabilities.

## Features

### Core Installation
- **Oh My Zsh Framework**: Automated installation and configuration
- **Agnoster Theme**: Beautiful prompt with git integration and directory context
- **Essential Plugins**: Carefully curated for maximum productivity
  - `git` - Git command shortcuts and information (built-in)
  - `zsh-autosuggestions` - Fish-like autosuggestions based on history (external)
  - `zsh-syntax-highlighting` - Real-time command syntax highlighting (external)
  - `z` - Smart directory jumping based on frecency (built-in)
  - `command-not-found` - Suggests packages when commands aren't found (built-in)
  - `cp` - Enhanced copy operations with progress indicators (built-in)
- **Modern Tools**: eza (modern ls replacement) with version management

### Enterprise Features
- **Configuration Management**: Customizable themes, plugins, and tool versions via `config.sh`
- **Error Handling**: Comprehensive error checking with descriptive messages and fail-fast behavior
- **Idempotency**: Safe to run multiple times without conflicts or duplicate installations
- **Backup & Restore**: Automatic backup of existing configurations with full rollback capability
- **Uninstall Support**: Complete removal with `--uninstall` flag and original configuration restoration
- **Version Management**: Supports specific eza versions or automatic latest release detection
- **Cross-Platform**: Enhanced support for multiple Linux distributions (apt, dnf, pacman, zypper)
- **Automated Testing**: Comprehensive test suite with 11 test cases for reliability assurance
- **Dependency Validation**: Pre-installation checks for required system tools

## Requirements

- Linux or macOS system
- Required system tools: `git`, `curl`, `sudo`, `jq`
- Internet connection for downloading components

## Quick Start

### Basic Installation
```bash
chmod +x customzsh.sh
./customzsh.sh
```

On first run, the script creates a `config.sh` file from the template. Review and modify it as needed, then run again:

```bash
./customzsh.sh
```

### Configuration Options

Customize your setup by editing `config.sh`:

```bash
# Set your preferred theme
ZSH_THEME="agnoster"

# Choose external plugins to install
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
)

# Specify eza version ("latest" or specific version like "v0.23.3")
EZA_VERSION="latest"
```

### Advanced Usage

#### Uninstall
Remove all customzsh components and restore original configuration:
```bash
./customzsh.sh --uninstall
```

#### Testing
Run the automated test suite to verify functionality:
```bash
./run_tests.sh
```

#### Version-Specific Installation
Install a specific version of eza by modifying `config.sh`:
```bash
EZA_VERSION="v0.23.3"
```

## Project Structure

```
customzsh/
├── customzsh.sh              # Main installation script
├── install_eza.sh             # Cross-platform eza installation
├── .zshrc                     # Zsh configuration template
├── config.sh.example          # Configuration template
├── run_tests.sh               # Test runner
├── tests/
│   ├── test_installation.sh   # Comprehensive test suite
│   └── bats/                  # Testing framework (submodule)
├── README.md                  # This file
├── CHANGELOG.md               # Version history
└── CLAUDE.md                  # Development guidance
```

## Testing

The project includes a comprehensive automated test suite covering:

- Dependency validation
- Configuration file handling
- Idempotency verification
- Error handling scenarios
- Backup and restore functionality
- Plugin installation logic
- Version management
- Uninstall procedures

**Run tests:**
```bash
./run_tests.sh
```

**Test Requirements:**
- bats testing framework (included as submodule)
- Git submodules initialized: `git submodule update --init --recursive`

## Error Handling

The scripts implement enterprise-grade error handling:

- **Fail-fast behavior**: Scripts exit immediately on any error
- **Descriptive messages**: Clear error descriptions with suggested solutions
- **Dependency validation**: Pre-checks for required system tools
- **Rollback capability**: Automatic restoration on failure
- **Safe re-runs**: Idempotent operations prevent conflicts

## Development

### Contributing
1. Run tests before making changes: `./run_tests.sh`
2. Ensure all tests pass after modifications
3. Update documentation for new features
4. Follow existing error handling patterns

### Architecture
- **Modular design**: Separate scripts for different concerns
- **Configuration-driven**: Behavior controlled via `config.sh`
- **Test coverage**: Comprehensive validation of all functionality
- **Cross-platform**: Support for multiple package managers

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed information about updates and changes.

## License

This project is open source and available under standard terms.