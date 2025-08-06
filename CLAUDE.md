# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a customzsh setup script that automates the installation and configuration of Oh My Zsh with popular plugins. The project consists of:

- `customzsh.sh`: Main installation script that sets up zsh, Oh My Zsh, and plugins
- `.zshrc`: Custom zsh configuration file with agnoster theme and useful plugins

## Usage

To run the installation script:
```bash
chmod +x customzsh.sh
./customzsh.sh
```

## Architecture

The installation process follows these steps:
1. Installs zsh and required dependencies via apt
2. Installs eza (modern ls replacement) with repository fallback if needed
3. Downloads and installs Oh My Zsh framework
4. Clones popular zsh plugins (syntax highlighting, autosuggestions)
5. Copies custom .zshrc configuration to user's home directory
6. Changes default shell to zsh and sources the new configuration

## Key Components

- **customzsh.sh**: Automated installer that handles dependency installation, Oh My Zsh setup, plugin installation, and shell configuration. Now uses the dedicated install_eza.sh script for eza installation and installs the command-not-found package for enhanced command suggestions
- **install_eza.sh**: Dedicated cross-platform eza installation script with comprehensive package manager support (apt, dnf, pacman, zypper, brew) and fallback options (cargo). For Debian/Ubuntu systems, uses the official deb.gierens.de repository as primary fallback when eza is not available in default repositories, with PPA as secondary fallback. Includes proper error handling and installation verification
- **.zshrc**: Pre-configured zsh settings with agnoster theme, essential plugins (git, zsh-autosuggestions, zsh-syntax-highlighting, z, command-not-found, cp), and eza aliases for enhanced directory listing

## Plugin Details

### Custom Plugins (Externally Downloaded)
- **zsh-syntax-highlighting**: Provides syntax highlighting for commands as you type
- **zsh-autosuggestions**: Suggests commands as you type based on history and completions

### Built-in Oh My Zsh Plugins (No Download Required)
- **z**: Jump quickly to frequently used directories
- **command-not-found**: Provides command suggestions when you type a command that doesn't exist (requires command-not-found package)
- **cp**: Enhanced copy command with additional aliases and functionality
- **git**: Git integration with useful aliases and functions

## Recent Updates

- **Enhanced plugin support**: Added command-not-found package installation to support the command-not-found plugin functionality, with clear documentation distinguishing between built-in and custom plugins
- **Official eza repository support**: Updated install_eza.sh to use the official deb.gierens.de repository for Debian/Ubuntu systems when eza is not available in default repositories, with automatic GPG key handling
- **Enhanced eza installation**: Created dedicated install_eza.sh script with cross-platform support and robust error handling
- **Improved reliability**: Added installation verification, proper error handling for package managers, and shell-agnostic sourcing
- **Modular architecture**: Separated eza installation logic into its own script for better maintainability