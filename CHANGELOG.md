# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2025-06-18

### Added
- **eza integration**: Added automatic installation of eza (modern ls replacement)
  - Script now tries `apt install eza` first
  - Falls back to adding official eza repository if not available in default repos
  - Adds eza repository with proper GPG key verification
- **Enhanced ls command**: Added `alias ls="eza --icons --group-directories-first"` to .zshrc
  - Provides colorful, icon-rich directory listings
  - Groups directories first for better organization

### Changed
- Updated installation process to include eza setup
- Extended .zshrc configuration with eza aliases
- Updated CLAUDE.md documentation to reflect new features