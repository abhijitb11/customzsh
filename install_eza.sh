#!/bin/bash
#
# install_eza.sh
#
# This script installs eza (modern ls replacement) with cross-platform
# package manager support and comprehensive fallback options. It supports
# apt, dnf, pacman, zypper, brew, and cargo installation methods.
# For Debian/Ubuntu systems, it uses the official deb.gierens.de repository
# as primary fallback when eza is not available in default repositories.
#
set -e

# --- Function to check if a command exists ---
command_exists() {
    command -v "$1" &> /dev/null
}

# --- Function to get latest eza version from GitHub ---
get_latest_eza_version() {
    echo "Fetching the latest version of eza..."
    local latest_version=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | jq -r .tag_name)
    if [ -z "$latest_version" ] || [ "$latest_version" == "null" ]; then
        echo "Error: Could not fetch the latest version of eza. Please check your network connection or set a specific version in config.sh." >&2
        exit 1
    fi
    echo "Latest version is $latest_version."
    echo "$latest_version"
}

# --- Function to install eza on Debian/Ubuntu ---
install_eza_apt() {
    echo "Attempting to install eza using apt..."
    sudo apt update
    if sudo apt install -y eza; then
        echo "eza installed successfully via apt."
        return 0 # Success
    else
        echo "eza not found in default apt repositories, attempting to add official eza repository..."
        
        # Ensure gpg is installed
        if ! command_exists gpg; then
            echo "Installing gpg..."
            sudo apt update
            if ! sudo apt install -y gpg; then
                echo "Failed to install gpg."
                return 1
            fi
        fi
        
        # Add eza repository from deb.gierens.de
        echo "Adding eza repository from deb.gierens.de..."
        sudo mkdir -p /etc/apt/keyrings
        if ! wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg; then
            echo "Failed to download and install GPG key."
            return 1
        fi
        
        if ! echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list; then
            echo "Failed to add eza repository."
            return 1
        fi
        
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update
        
        if sudo apt install -y eza; then
            echo "eza installed successfully via official repository."
            return 0 # Success
        else
            echo "Failed to install eza from official repository, trying PPA fallback..."
            
            # Fallback to PPA if official repo fails
            if ! command_exists add-apt-repository; then
                echo "Installing 'software-properties-common' to enable add-apt-repository..."
                if ! sudo apt install -y software-properties-common; then
                    echo "Failed to install software-properties-common."
                    return 1
                fi
            fi
            if ! sudo add-apt-repository ppa:eza-community/eza -y; then
                echo "Failed to add eza PPA repository."
                return 1
            fi
            sudo apt update
            if sudo apt install -y eza; then
                echo "eza installed successfully via PPA fallback."
                return 0 # Success
            else
                echo "Failed to install eza even after trying official repository and PPA."
                return 1 # Failure
            fi
        fi
    fi
}


# --- Load Configuration and Determine Target Version ---
if [ -f "config.sh" ]; then
    source "config.sh"
else
    echo "Warning: config.sh not found. Using default EZA_VERSION='latest'."
    EZA_VERSION="latest"
fi

TARGET_EZA_VERSION=$EZA_VERSION
if [ "$TARGET_EZA_VERSION" == "latest" ]; then
    TARGET_EZA_VERSION=$(get_latest_eza_version)
fi
echo "Target eza version is set to: $TARGET_EZA_VERSION"
# --- Main Installation Logic ---
if command_exists eza && [[ $(eza --version 2>/dev/null) == *"$TARGET_EZA_VERSION"* ]]; then
    echo "eza version $TARGET_EZA_VERSION is already installed. Skipping."
else
    echo "Installing eza version $TARGET_EZA_VERSION..."
    if [ "$(uname -s)" = "Linux" ]; then
        if command_exists apt; then
            install_eza_apt
        elif command_exists dnf; then
            echo "Attempting to install eza using dnf..."
            if ! sudo dnf install -y eza; then
                echo "Failed to install eza via dnf."
            fi
        elif command_exists pacman; then
            echo "Attempting to install eza using pacman..."
            sudo pacman -S --noconfirm eza
        elif command_exists zypper; then
            echo "Attempting to install eza using zypper..."
            if ! sudo zypper install -y eza; then
                echo "Failed to install eza via zypper."
            fi
        else
            echo "No supported package manager found for automatic installation on your Linux distribution."
            if command_exists cargo; then
                echo "Attempting to install eza using cargo (Rust package manager)..."
                if ! cargo install eza; then
                    echo "Failed to install eza via cargo."
                fi
            else
                echo "Please install eza manually or install Rust/Cargo (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh) to use 'cargo install eza'."
            fi
        fi
    elif [ "$(uname -s)" = "Darwin" ]; then
        if command_exists brew; then
            echo "Attempting to install eza using Homebrew..."
            if ! brew install eza; then
                echo "Failed to install eza via Homebrew."
            fi
        else
            echo "Homebrew not found. Please install Homebrew (brew.sh) or install eza manually."
        fi
    else
        echo "Unsupported operating system. Please install eza manually."
        if command_exists cargo; then
            echo "Attempting to install eza using cargo (Rust package manager)..."
            if ! cargo install eza; then
                echo "Failed to install eza via cargo."
            fi
        else
            echo "Please install Rust/Cargo (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh) to use 'cargo install eza'."
        fi
    fi
fi

# --- Append alias to .zshrc if not already present ---
ALIAS_LINE='alias ls="eza --icons --group-directories-first"'
if ! grep -qxF "${ALIAS_LINE}" ~/.zshrc; then
    echo -e "\n# eza alias for ls" >> ~/.zshrc
    echo "${ALIAS_LINE}" >> ~/.zshrc
    echo "Alias added to ~/.zshrc."
else
    echo "Alias already present in ~/.zshrc."
fi

# --- Verify installation and provide feedback ---
if command_exists eza; then
    echo "eza installation verified successfully!"
    echo "Setup complete. You can now use 'ls' in Zsh to see eza in action."
    
    # Only source if we're running in zsh
    if [ "$0" = "zsh" ] || [ -n "$ZSH_VERSION" ]; then
        echo "Sourcing ~/.zshrc to apply changes to the current session."
        source ~/.zshrc
    else
        echo "Please start a new zsh session or run 'source ~/.zshrc' in zsh to apply changes."
    fi
else
    echo "Warning: eza installation could not be verified. Please check manually."
    echo "You may need to restart your terminal or source ~/.zshrc manually."
fi