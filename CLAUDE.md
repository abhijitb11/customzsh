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

- **customzsh.sh**: Automated installer that handles dependency installation, eza installation, Oh My Zsh setup, plugin installation, and shell configuration
- **.zshrc**: Pre-configured zsh settings with agnoster theme, plugins (git, zsh-autosuggestions, zsh-syntax-highlighting), and eza aliases for enhanced directory listing