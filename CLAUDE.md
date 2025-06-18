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

- **customzsh.sh**: Automated installer that handles dependency installation, Oh My Zsh setup, plugin installation, and shell configuration. Now uses the dedicated install_eza.sh script for eza installation
- **install_eza.sh**: Dedicated cross-platform eza installation script with comprehensive package manager support (apt, dnf, pacman, zypper, brew) and fallback options (cargo). For Debian/Ubuntu systems, uses the official deb.gierens.de repository as primary fallback when eza is not available in default repositories, with PPA as secondary fallback. Includes proper error handling and installation verification
- **.zshrc**: Pre-configured zsh settings with agnoster theme, plugins (git, zsh-autosuggestions, zsh-syntax-highlighting), and eza aliases for enhanced directory listing

## Recent Updates

- **Official eza repository support**: Updated install_eza.sh to use the official deb.gierens.de repository for Debian/Ubuntu systems when eza is not available in default repositories, with automatic GPG key handling
- **Enhanced eza installation**: Created dedicated install_eza.sh script with cross-platform support and robust error handling
- **Improved reliability**: Added installation verification, proper error handling for package managers, and shell-agnostic sourcing
- **Modular architecture**: Separated eza installation logic into its own script for better maintainability