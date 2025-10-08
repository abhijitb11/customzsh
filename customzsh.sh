#!/bin/bash
#
# customzsh.sh
#
# This script automates the installation and configuration of Oh My Zsh
# with a curated set of plugins and tools for an enhanced shell experience.
# It installs zsh, Oh My Zsh framework, popular plugins, and modern tools
# like eza (modern ls replacement) to provide a complete terminal setup.
#
set -e

# --- Output Helper Functions ---
info() {
    echo \"[INFO] $1\"
}

success() {
    echo \"[SUCCESS] $1\"
}

error() {
    echo \"[ERROR] $1\" >&2
}


# --- Uninstall Function ---
uninstall() {
    info "Uninstalling customzsh components..."
    
    # Remove Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "Removing Oh My Zsh directory..."
        rm -rf "$HOME/.oh-my-zsh"
        success "Oh My Zsh directory removed."
    fi
    
    # Restore original .zshrc if backup exists
    if [ -f "$HOME/.zshrc.pre-customzsh" ]; then
        info "Restoring original .zshrc..."
        mv "$HOME/.zshrc.pre-customzsh" "$HOME/.zshrc"
        success "Original .zshrc restored."
    else
        info "No .zshrc backup found to restore."
    fi
    
    success "Uninstallation complete."
}

# --- Check for uninstall flag ---
if [ "$1" == "--uninstall" ]; then
    uninstall
    exit 0
fi
# --- Dependency Check Function ---
check_dependencies() {
    info "Checking for required dependencies..."
    local missing=0
    for cmd in git curl sudo; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Required command '$cmd' is not installed."
            missing=1
        fi
    done

    if [ "$missing" -eq 1 ]; then
        error "Please install the missing dependencies and run the script again."
        exit 1
    fi
    success "All dependencies are present."
}

# --- Check Dependencies ---
check_dependencies

# --- Load Configuration ---
if [ -f "config.sh" ]; then
    info "Loading configuration from config.sh..."
    source "config.sh"
else
    info "Creating config.sh from template..."
    cp "config.sh.example" "config.sh"
    info "Created config.sh. Please review it and run the script again."
    exit 0
fi

# --- Install Required Toolchain ---
## install required toolchain
if command -v zsh >/dev/null 2>&1; then
    info "Zsh is already installed. Skipping installation."
else
    info "Installing required toolchain..."
    if sudo apt install -y zsh zsh-doc git curl command-not-found jq; then
        success "Toolchain installed successfully."
    else
        error "Failed to install required packages. Aborting."
        exit 1
    fi
fi

# --- Install eza (Modern ls Replacement) ---
## install eza (modern ls replacement)
if [ -f "./install_eza.sh" ]; then
    info "Running install_eza.sh script..."
    chmod +x ./install_eza.sh
    ./install_eza.sh
else
    error "install_eza.sh not found, skipping eza installation."
    info "Please ensure install_eza.sh is in the same directory as this script."
fi

# --- Install Oh My Zsh Framework ---
if [ -d "$HOME/.oh-my-zsh" ]; then
    info "Oh My Zsh is already installed. Skipping."
else
    info "Installing Oh My Zsh..."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        success "Oh My Zsh installed successfully."
    else
        error "Failed to install Oh My Zsh. Aborting."
        exit 1
    fi
fi

# --- Install Zsh Plugins ---
## get zsh plugins

info "Installing external plugins..."
for plugin in "${EXTERNAL_PLUGINS[@]}"; do
    repo_name=$(basename "$plugin")
    target_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$repo_name"

    if [ -d "$target_dir" ]; then
        info "$repo_name is already installed. Skipping."
    else
        info "Cloning $repo_name..."
        if git clone "https://github.com/$plugin.git" "$target_dir"; then
            success "$repo_name cloned successfully."
        else
            error "Failed to clone $repo_name. Aborting."
            exit 1
        fi
    fi
done

## Note: z, command-not-found, and cp are built-in Oh My Zsh plugins
## They are already configured in .zshrc and don't need separate installation
## command-not-found requires the 'command-not-found' package (installed above)

# --- Configure Zsh Settings ---
## edit default zshrc file
# get default zsh template
#wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/templates/zshrc.zsh-template -O ~/.zshrc


# change theme to agnoster
#sed -i 's/robbyrussell/agnoster/g' ~/.zshrc

# add plugins to list
#sed -i 's/plugins=(git)/plugins=(\ngit\nzsh-syntax-highlighting\nzsh-autosuggestions)/g' ~/.zshrc

## copy custom zshrc file to current user dir
if cmp -s ".zshrc" "$HOME/.zshrc"; then
    info ".zshrc is already up to date. Skipping."
else
    # Backup original .zshrc if it exists and hasnt been backed up already
    if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc.pre-customzsh" ]; then
        info "Backing up existing .zshrc to .zshrc.pre-customzsh..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.pre-customzsh"
        success "Existing .zshrc backed up."
    fi
    
    info "Copying custom .zshrc file..."
    if cp .zshrc ~/; then
        success "Custom .zshrc copied successfully."
    else
        error "Failed to copy .zshrc file. Aborting."
        exit 1
    fi
fi

# --- Change Default Shell and Activate ---
# change shell to zsh
info "Changing default shell to zsh..."
if chsh -s $(which zsh); then
    success "Default shell changed to zsh successfully."
else
    error "Failed to change default shell to zsh. Aborting."
    exit 1
fi
zsh

## activate zsh with new defaults
source ~/.zshrc
