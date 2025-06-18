#!/bin/bash

## install required toolchain
sudo apt install -y zsh zsh-doc git curl

## install eza (modern ls replacement)
if ! sudo apt install -y eza 2>/dev/null; then
    echo "eza not found in default repositories, adding eza repository..."
    # Add eza repository and install
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo tee /etc/apt/keyrings/gierens.asc > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/gierens.asc] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.asc /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
fi

## get oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

## get zsh plugins

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

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
