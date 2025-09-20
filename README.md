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

### Test Suites

The testing system includes two complementary test suites:

#### Unit Tests
Fast, isolated tests covering core functionality:
```bash
./run_tests.sh --suite unit
```

#### Integration Tests
Comprehensive end-to-end testing with modular test files:
```bash
./run_tests.sh --suite integration
```

Test categories:
- `installation.bats`: End-to-end installation workflow
- `idempotency.bats`: Multi-run safety validation
- `uninstall.bats`: Complete removal testing
- `configuration.bats`: Config customization testing

#### Advanced Test Options
```bash
./run_tests.sh --help              # Show all options
./run_tests.sh --verbose           # Detailed output
./run_tests.sh --list              # List available test suites
./run_tests.sh --suite all         # Run all tests (default)
```

## Docker Testing

For comprehensive cross-platform validation, the project includes Docker-based testing across multiple Linux distributions.

### Docker Requirements

- Docker Engine installed and running
- At least 4GB available disk space
- Internet connection for base image downloads

### Quick Docker Testing

Test on all supported distributions:
```bash
./run_docker_tests.sh
```

Test specific distributions:
```bash
./run_docker_tests.sh ubuntu debian    # Test only Ubuntu and Debian
./run_docker_tests.sh fedora           # Test only Fedora
```

### Docker Test Options

```bash
./run_docker_tests.sh --help           # Show all options
./run_docker_tests.sh --list           # List supported distributions
./run_docker_tests.sh --verbose        # Detailed output
./run_docker_tests.sh --parallel       # Parallel testing (default)
./run_docker_tests.sh --serial         # Serial testing
./run_docker_tests.sh --no-cleanup     # Keep Docker images after testing
```

### Supported Distributions

- **Ubuntu**: `ubuntu:latest`, `ubuntu:20.04`
- **Debian**: `debian:stable`
- **Fedora**: `fedora:latest`
- **Arch Linux**: `archlinux:latest`

### Docker Test Architecture

The Docker testing system uses:

1. **Multi-stage Dockerfile** (`Dockerfile.test`) for efficient builds
2. **Cross-platform package manager support** (apt, dnf, pacman)
3. **Non-root user testing** for realistic scenarios
4. **Parallel execution** for faster results
5. **Automatic cleanup** of Docker resources

### Docker Test Results

Test results are stored in `test_results/` directory:
```
test_results/
├── build_ubuntu.log           # Build logs per distribution
├── test_ubuntu.log            # Test execution logs
├── result_ubuntu              # Test results (PASS/FAIL)
└── ...
```

### CI/CD Integration

For automated testing environments:
```bash
# CI-optimized execution
./run_docker_tests.sh --verbose --serial

# Local development
./run_tests.sh --docker --verbose
```

### Troubleshooting Docker Tests

**Docker daemon not running:**
```bash
sudo systemctl start docker    # Linux
# or
open -a Docker                 # macOS
```

**Permission issues:**
```bash
sudo usermod -aG docker $USER  # Add user to docker group (Linux)
# Then log out and back in
```

**Disk space issues:**
```bash
docker system prune -f         # Clean up unused Docker resources
```

**Network connectivity:**
- Ensure internet access for package downloads
- Check firewall settings for Docker bridge network

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