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
- **Enterprise CI/CD Pipeline**: Production-grade GitHub Actions workflow with comprehensive testing infrastructure
- **Automated Testing**: Extensive test suite with 131+ test cases across 8 specialized categories for maximum reliability
- **Dependency Validation**: Pre-installation checks for required system tools

## Visual Showcase

![customzsh terminal](https://example.com/customzsh-terminal.png)

*Example of customzsh in action with agnoster theme and eza integration*

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
# Set your preferred theme (available: agnoster, robbyrussell, etc.)
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
├── run_docker_tests.sh        # Docker-based test runner
├── Dockerfile.test            # Dockerfile for testing
├── tests/
│   ├── test_installation.sh   # Comprehensive test suite
│   └── bats/                  # Testing framework (submodule)
├── README.md                  # This file
├── CHANGELOG.md               # Version history
└── CLAUDE.md                  # Development guidance
```

## Configuration Guide

### Theme Selection
The following themes are available for customization:
- `agnoster` - Default theme with git integration and directory context (recommended)
- `robbyrussell` - Classic Oh My Zsh theme
- Other built-in themes from Oh My Zsh framework

### Plugin Management
You can add additional plugins by including them in the EXTERNAL_PLUGINS array:
```bash
EXTERNAL_PLUGINS=(
    "zsh-users/zsh-syntax-highlighting"
    "zsh-users/zsh-autosuggestions"
    "zdharma-continuum/fast-syntax-highlighting"  # Example of another plugin
)
```

### Version Management
For eza, you can specify either:
- `"latest"` - Automatically install the latest release from GitHub
- Specific version like `"v0.23.3"` - Install a specific version for consistency

## Benefits & Comparison

### Why Choose customzsh?
1. **Enterprise-grade reliability**: Comprehensive error handling and rollback capabilities
2. **Idempotent operations**: Safe to run multiple times without conflicts
3. **Cross-platform support**: Works across Ubuntu, Debian, Fedora, Arch Linux, and macOS
4. **Automated testing**: 131+ comprehensive tests with CI/CD pipeline ensure maximum stability
5. **Easy customization**: Simple configuration file for theme and plugin selection

### How It Compares
Compared to other zsh setup tools:
- More comprehensive error handling than typical scripts
- Built-in uninstall functionality with full restoration capability
- Automated testing framework that validates all installation scenarios
- Cross-platform package manager support (apt, dnf, pacman, zypper)

## Troubleshooting

### Common Issues and Solutions

**Permission Denied Errors**
If you encounter permission issues during installation:
```bash
# Make sure your user has sudo privileges
sudo visudo  # Add your user to the sudoers file if needed
```

**Theme Not Displaying Correctly**
If the agnoster theme doesn't display properly:
1. Ensure you're using a compatible terminal with proper font support
2. Install powerline fonts for full theme functionality

**Plugin Installation Failures**
If external plugins fail to install:
```bash
# Check your internet connection and GitHub access
# Try installing manually: git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
```

### Reporting Issues
Found a bug or have a feature request? Please submit an issue on our [GitHub repository](https://github.com/your-repo/customzsh/issues).

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
- `installation.bats`: End-to-end installation workflow (25 test cases)
- `idempotency.bats`: Multi-run safety validation (12 test cases)
- `uninstall.bats`: Complete removal testing (14 test cases)
- `configuration.bats`: Config customization testing (14 test cases)
- `performance.bats`: Resource usage and timing benchmarks (10 test cases)
- `compatibility.bats`: Cross-platform shell validation (8 test cases)

#### Cross-Platform Docker Testing
Comprehensive testing across multiple Linux distributions:
```bash
./run_docker_tests.sh                    # Test all distributions
./run_docker_tests.sh ubuntu debian      # Test specific distributions
./run_docker_tests.sh --parallel         # Parallel execution (default)
./run_docker_tests.sh --serial           # Serial execution for debugging
./run_docker_tests.sh --verbose          # Detailed output
./run_docker_tests.sh --list             # List available distributions
```

Supported distributions:
- **Ubuntu**: Latest + 20.04 LTS (apt package manager)
- **Debian**: Stable release (apt package manager)
- **Fedora**: Latest release (dnf package manager)
- **Arch Linux**: Rolling release (pacman package manager)

#### Performance & Compatibility Testing
Extended validation with specialized test suites:
```bash
# Performance benchmarking tests
./run_docker_tests.sh --include-perf

# Cross-platform compatibility tests
./run_docker_tests.sh --include-compat

# Combined performance and compatibility testing
./run_docker_tests.sh --include-perf --include-compat
```

#### Advanced Test Options
```bash
./run_tests.sh --help              # Show all options
./run_tests.sh --verbose           # Detailed output
./run_tests.sh --list              # List available test suites
./run_tests.sh --suite all         # Run all tests (default)
./run_tests.sh --fast              # Skip slower tests
./run_tests.sh --ci                # CI/CD optimized execution
```

## Docker Testing & CI/CD

For comprehensive cross-platform validation, the project includes Docker-based testing across multiple Linux distributions with enterprise-grade CI/CD integration.

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

### CI/CD Pipeline

The project features a comprehensive GitHub Actions workflow (`.github/workflows/test.yml`) with enterprise-grade capabilities:

#### Automated Testing Pipeline
- **Multi-stage Workflow**: 8 specialized jobs with dependency management
- **Cross-platform Validation**: Automated testing across 5 Linux distributions
- **Performance Monitoring**: Automated baseline tracking and regression detection
- **Quality Assurance**: Comprehensive security scanning and health monitoring
- **Test Analytics**: Historical trend analysis with success rate tracking

#### Professional Reporting
- **Enhanced Test Summaries**: Comprehensive markdown reports with execution timing
- **Performance Analysis**: Automated regression detection with threshold alerts
- **Quality Metrics**: Success rate calculation with quality rating assignment
- **Coverage Analysis**: Detailed breakdown of test coverage across all categories

#### Artifact Management
- **Structured Collection**: Organized artifact storage with extended retention policies
- **Historical Data**: Long-term analytics data (90-day retention) for trend analysis
- **Quality Reports**: Security and health analysis with actionable recommendations
- **Performance Metrics**: Automated baseline tracking with regression detection

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