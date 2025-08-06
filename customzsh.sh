#!/bin/bash

## install required toolchain
sudo apt install -y zsh zsh-doc git curl command-not-found

## install eza (modern ls replacement)
if [ -f "./install_eza.sh" ]; then
    echo "Running install_eza.sh script..."
    chmod +x ./install_eza.sh
    ./install_eza.sh
else
    echo "install_eza.sh not found, skipping eza installation."
    echo "Please ensure install_eza.sh is in the same directory as this script."
fi

## get oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

## get zsh plugins

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

## Note: z, command-not-found, and cp are built-in Oh My Zsh plugins
## They are already configured in .zshrc and don't need separate installation
## command-not-found requires the 'command-not-found' package (installed above)

## edit default zshrc file
# get default zsh template
#wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/templates/zshrc.zsh-template -O ~/.zshrc


# change theme to agnoster
#sed -i 's/robbyrussell/agnoster/g' ~/.zshrc

# add plugins to list
#sed -i 's/plugins=(git)/plugins=(\ngit\nzsh-syntax-highlighting\nzsh-autosuggestions)/g' ~/.zshrc

## copy custom zshrc file to current user dir
cp .zshrc ~/

# change shell to zsh
chsh -s $(which zsh)
zsh

## activate zsh with new defaults
source ~/.zshrc
