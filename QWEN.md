# Project Overview

This is a custom zsh setup script that automates the installation and configuration of Oh My Zsh with popular plugins and modern tools. The project provides a complete, ready-to-use zsh environment with enhanced productivity features.

## Features

- **Oh My Zsh Framework**: Full installation and setup
- **Agnoster Theme**: Beautiful prompt with git integration
- **Essential Plugins**: 
  - `git` - Git command shortcuts and information (built-in)
  - `zsh-autosuggestions` - Fish-like autosuggestions (external)
  - `zsh-syntax-highlighting` - Command syntax highlighting (external)
  - `z` - Jump to frequently used directories (built-in)
  - `command-not-found` - Suggests packages when commands aren't found (built-in)
  - `cp` - Enhanced copy operations with useful aliases (built-in)
- **Modern Tools**: eza (modern ls replacement) with cross-platform installation
- **Custom Aliases**: Pre-configured eza aliases for enhanced directory listing

## Project Structure

```
customzsh/
├── customzsh.sh              # Main installation script
├── install_eza.sh             # Dedicated cross-platform eza installation script
├── .zshrc                     # Custom zsh configuration file with agnoster theme and plugins
├── README.md                  # Project documentation
├── CHANGELOG.md               # Version history and updates
└── CLAUDE.md                  # Guidance for Claude Code
```

## Installation Process

The installation process follows these steps:
1. Installs zsh and required dependencies via apt
2. Installs eza (modern ls replacement) with repository fallback if needed
3. Downloads and installs Oh My Zsh framework
4. Clones popular zsh plugins (syntax highlighting, autosuggestions)
5. Copies custom .zshrc configuration to user's home directory
6. Changes default shell to zsh and sources the new configuration

## Key Components

### `customzsh.sh`
- Automated installer that handles dependency installation, Oh My Zsh setup, plugin installation, and shell configuration
- Now uses the dedicated install_eza.sh script for eza installation
- Installs the command-not-found package for enhanced command suggestions

### `install_eza.sh` 
- Dedicated cross-platform eza installation script with comprehensive package manager support (apt, dnf, pacman, zypper, brew)
- For Debian/Ubuntu systems, uses the official deb.gierens.de repository as primary fallback when eza is not available in default repositories, with PPA as secondary fallback
- Includes proper error handling and installation verification

### `.zshrc`
- Pre-configured zsh settings with agnoster theme
- Essential plugins (git, zsh-autosuggestions, zsh-syntax-highlighting, z, command-not-found, cp)
- eza aliases for enhanced directory listing (`alias ls="eza --icons --group-directories-first"`)

## Plugin Details

### Custom Plugins (Externally Downloaded)
- **zsh-syntax-highlighting**: Provides syntax highlighting for commands as you type
- **zsh-autosuggestions**: Suggests commands as you type based on history and completions

### Built-in Oh My Zsh Plugins (No Download Required)
- **z**: Jump quickly to frequently used directories
- **command-not-found**: Provides command suggestions when you type a command that doesn't exist (requires command-not-found package)
- **cp**: Enhanced copy command with additional aliases and functionality
- **git**: Git integration with useful aliases and functions

## Usage

```bash
chmod +x customzsh.sh
./customzsh.sh
```

## Building and Running

The project is a self-contained installation script. To use it:
1. Make the script executable: `chmod +x customzsh.sh`
2. Run the script: `./customzsh.sh`

The script will:
- Install required dependencies (zsh, git, curl)
- Install eza (modern ls replacement) 
- Set up Oh My Zsh framework
- Install zsh plugins
- Configure .zshrc with agnoster theme and plugins
- Change default shell to zsh

## Development Conventions

The project follows a modular approach:
- The main installation script (`customzsh.sh`) orchestrates the entire process
- The eza installation is separated into its own script (`install_eza.sh`) for better maintainability
- Configuration is handled through `.zshrc` which is copied to user's home directory
- All scripts are designed to be idempotent and safe to run multiple times

## Testing

The project doesn't include explicit tests, but can be verified by:
1. Running the installation script
2. Checking that zsh is properly configured with the agnoster theme
3. Verifying that all plugins are installed and working
4. Confirming that eza is installed and aliased to ls command