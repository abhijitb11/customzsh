# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-06-17

### Added
- **Essential Oh My Zsh plugins**: Enhanced .zshrc configuration with productivity-focused plugins
  - Added `z` plugin for smart directory jumping based on frecency
  - Added `command-not-found` plugin for helpful command suggestions
  - Added `cp` plugin for enhanced copy operations with progress indicators
- **Official eza repository support**: Updated install_eza.sh to use deb.gierens.de repository
  - Primary fallback for Debian/Ubuntu systems when eza not in default repositories
  - Automatic GPG key installation and repository configuration
  - PPA remains as secondary fallback option
- **install_eza.sh**: New dedicated cross-platform eza installation script
  - Support for multiple package managers (apt, dnf, pacman, zypper, brew)
  - Cargo fallback installation method
  - Comprehensive error handling and installation verification
  - Shell-agnostic sourcing to prevent errors in non-zsh environments
- **eza integration**: Enhanced automatic installation of eza (modern ls replacement)
  - Script now tries `apt install eza` first
  - Falls back to adding official eza repository if not available in default repos
  - Adds eza repository with proper GPG key verification
- **Enhanced ls command**: Added `alias ls="eza --icons --group-directories-first"` to .zshrc
  - Provides colorful, icon-rich directory listings
  - Groups directories first for better organization

### Changed
- **customzsh.sh**: Updated to use install_eza.sh script instead of inline eza installation
- **CLAUDE.md**: Updated documentation to reflect modular architecture changes
- Updated installation process to include eza setup
- Extended .zshrc configuration with eza aliases

### Fixed
- Added `--noconfirm` flag to pacman commands for non-interactive operation
- Improved error handling for PPA addition in apt-based systems
- Fixed source command to handle non-zsh shells gracefully
- Added proper verification that eza installation succeeded
- **install_eza.sh**: Made script executable with proper permissions (chmod +x)

### Improved
- Modular architecture with separated eza installation logic
- Better cross-platform compatibility
- More robust error handling throughout installation process