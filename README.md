# Dotfiles

This repository contains my personal dotfiles, managed by [Dotbot](https://github.com/anishathalye/dotbot), to set up a comfortable and efficient development environment on Linux and macOS.

## 1. Usage Guide

To install the configuration on a new machine, follow these steps:

### Prerequisites

Ensure you have `git` installed.

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/wangxinyu/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

    *Note: It is recommended to clone into `~/dotfiles` or a similar path.*

2.  **Run the install script:**

    This project uses a modular structure. You typically run the initialization script corresponding to your operating system or environment.

    *   **Linux (Common):**
        ```bash
        ./linux-common/init-scripts/init.sh
        ```

    *   **macOS (Common):**
        ```bash
        ./mac-common/init-scripts/init.sh
        ```

    This script will:
    *   Initialize submodules (if any).
    *   Install necessary dependencies (like Homebrew, oh-my-zsh, etc.) via helper scripts.
    *   Use Dotbot to symlink configuration files from the repo to your home directory.

### Update

To update your dotfiles with the latest changes from the repository:

```bash
cd ~/dotfiles
git pull
./linux-common/init-scripts/init.sh  # Or the appropriate script for your OS
```

## 2. Configuration Overview

The project is organized into several directories to separate configurations for different environments:

*   **`linux-common/`**: Configuration files common to Linux environments.
    *   `dotbot.yaml`: The Dotbot configuration file defining symlinks and shell commands.
    *   `init-scripts/`: Scripts for bootstrapping the environment (installing tools, etc.).
    *   `albert-scripts/`: Custom shell scripts.
    *   `config/`: Configuration files for various tools (mapped to `~/.config`).
    *   `home/`: Dotfiles to be placed directly in the home directory (e.g., `.bashrc`, `.zshrc`).
*   **`mac-common/`**: Similar structure, tailored for macOS.
*   **`nvim/`**: Neovim configurations.
    *   `nvchad/`: Configurations based on NvChad.
    *   `dojo/`: A custom Neovim configuration.
    *   `kick-start/`: A minimal starter configuration.

## 3. Neovim Plugins

Here is a list of some key plugins used in the `nvchad` and `dojo` configurations:

| Plugin | Description |
| :--- | :--- |
| **stevearc/conform.nvim** | Lightweight yet powerful formatter plugin. |
| **ojroques/nvim-osc52** | Copy text to the system clipboard using the OSC 52 escape sequence (useful over SSH). |
| **neovim/nvim-lspconfig** | Quickstart configs for Nvim LSP. |
| **nvim-treesitter/nvim-treesitter** | Nvim Treesitter configurations and abstraction layer. |
| **HiPhish/rainbow-delimiters.nvim** | Rainbow parentheses for Neovim using Tree-sitter. |
| **fei6409/log-highlight.nvim** | Highlighting for log files. |
| **hrsh7th/nvim-cmp** | A completion plugin for neovim written in Lua. |
| **Lokaltog/vim-easymotion** | Vim motions on speed! |
| **Bekaboo/dropbar.nvim** | A polished, IDE-like winbar for Neovim. |
| **lukas-reineke/indent-blankline.nvim** | Indent guides for Neovim. |
| **rainbowhxch/accelerated-jk.nvim** | Accelerate up/down movement. |
| **hat0uma/csvview.nvim** | A high-performance CSV file viewer. |
| **MeanderingProgrammer/render-markdown.nvim** | Plugin to render markdown in Neovim. |
| **mikavilpas/yazi.nvim** | Neovim plugin for the Yazi terminal file manager. |
| **tomasky/bookmarks.nvim** | Bookmarks plugin for Neovim. |
| **folke/snacks.nvim** | A collection of QoL plugins for Neovim. |
| **NickvanDyke/opencode.nvim** | AI coding assistant integration. |

## 4. Dotbot Init Scripts

The initialization scripts located in `init-scripts/` directories (e.g., `linux-common/init-scripts/`) automate the setup process.

*   **`init.sh`**: The main entry point. It iterates through other `install_*.sh` scripts in the directory and executes them. It orchestrates the entire bootstrapping process.
*   **`install_brew.sh`**: Installs Homebrew (if missing) and bundles packages listed in `Brewfile` or an internal array. It handles essential tools like `git`, `fzf`, `ripgrep`, `neovim`, etc.
*   **`install_omz_plugins.sh`**: Sets up Oh My Zsh and installs specified plugins (like `zsh-autosuggestions`, `zsh-syntax-highlighting`).
*   **`install_nvm.sh`**: Installs NVM (Node Version Manager) for managing Node.js versions.
*   **`install_tpm.sh`**: Installs Tmux Plugin Manager.
*   **`install_uv.sh`**: Installs `uv`, an extremely fast Python package installer and resolver.
*   **`install_fuzzy.sh`**: Scripts related to setting up fuzzy finding tools.

These scripts ensure that not only are your config files linked, but the necessary tools and environments they rely on are also present and correctly configured.
