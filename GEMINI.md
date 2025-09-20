# Project Overview

This project provides a set of scripts to automate the setup of a customized Zsh environment. It uses the "Oh My Zsh" framework and bundles a selection of popular plugins to enhance the terminal experience. The main goal is to provide a consistent, powerful, and visually appealing shell environment that can be quickly deployed on a new system.

The key technologies and components used are:
*   **Zsh:** A powerful and feature-rich shell.
*   **Oh My Zsh:** A framework for managing Zsh configuration.
*   **Agnoster Theme:** A popular and visually appealing theme for Oh My Zsh.
*   **Plugins:**
    *   `git`: Provides Git integration and aliases.
    *   `zsh-autosuggestions`: Suggests commands as you type.
    *   `zsh-syntax-highlighting`: Provides syntax highlighting for commands.
    *   `z`: Allows for quick navigation to frequently used directories.
    *   `command-not-found`: Suggests packages for commands that are not found.
    *   `cp`: Provides enhanced `cp` command functionality.
*   **eza:** A modern replacement for the `ls` command.

# Building and Running

The project is executed via the `customzsh.sh` script. There is no build process.

To run the project, execute the following commands:

```bash
chmod +x customzsh.sh
./customzsh.sh
```

The script will:
1.  Install Zsh and other required tools.
2.  Install the "eza" tool using the `install_eza.sh` script.
3.  Install "Oh My Zsh".
4.  Clone the `zsh-syntax-highlighting` and `zsh-autosuggestions` plugins.
5.  Copy the `.zshrc` file from the project directory to the user's home directory.
6.  Change the default shell to Zsh.

# Development Conventions

The project follows a simple structure:
*   `customzsh.sh`: The main script that orchestrates the setup process.
*   `install_eza.sh`: A helper script to install the "eza" tool.
*   `.zshrc`: The template for the Zsh configuration file. All customizations, such as theme, plugins, and aliases, are defined in this file.

Any changes to the Zsh configuration should be made in the `.zshrc` file within the project. The `customzsh.sh` script is responsible for deploying this configuration to the user's home directory.
