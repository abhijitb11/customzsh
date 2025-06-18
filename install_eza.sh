#!/bin/bash

# --- Function to check if a command exists ---
command_exists() {
    command -v "$1" &> /dev/null
}

# --- Function to install eza on Debian/Ubuntu ---
install_eza_apt() {
    echo "Attempting to install eza using apt..."
    sudo apt update
    if sudo apt install -y eza; then
        echo "eza installed successfully via apt."
        return 0 # Success
    else
        echo "eza not found in default apt repositories, attempting to add PPA..."
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
            echo "eza installed successfully via PPA."
            return 0 # Success
        else
            echo "Failed to install eza even after adding PPA."
            return 1 # Failure
        fi
    fi
}

# --- Main Installation Logic ---
if command_exists eza; then
    echo "eza is already installed."
else
    echo "eza not found. Attempting to install..."
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