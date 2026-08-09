# Dotfiles

This repository contains my personal dotfiles, managed by [Dotbot](https://github.com/anishathalye/dotbot), to set up a comfortable and efficient development environment on Linux and macOS.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Dotbot Usage](#dotbot-usage)
3. [Configuration Overview](#configuration-overview)
4. [Albert Scripts](#albert-scripts)
5. [Neovim Plugins](#neovim-plugins)
6. [Init Scripts](#init-scripts)

---

## Quick Start

### Prerequisites

Ensure you have `git` installed.

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/wangxinyu/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

   *Note: It is recommended to clone into `~/dotfiles` or a similar path.*

2. **Run the install script:**

   This project uses a modular structure. Run the initialization script for your OS:

   - **Linux (Common):**
     ```bash
     ./linux-common/init-scripts/init.sh
     ```

   - **macOS (Common):**
     ```bash
     ./mac-common/init-scripts/init.sh
     ```

   This script will:
   - Initialize submodules (if any).
   - Install necessary dependencies (Homebrew, oh-my-zsh, etc.).
   - Use Dotbot to symlink configuration files.

### Update

To update your dotfiles:

```bash
cd ~/dotfiles
git pull
./linux-common/init-scripts/init.sh  # Or the appropriate script for your OS
```

---

## Dotbot Usage

This project uses [Dotbot](https://github.com/anishathalye/dotbot) to manage symlinks. Install it first:

```bash
# Via Homebrew
brew install dotbot

# Or via uv
uv tool install dotbot
```

### Available Configurations

| Config | Path | Purpose |
|--------|------|---------|
| Linux Common | `linux-common/dotbot.yaml` | Common Linux setup |
| Linux Work | `linux-work/dotbot.yaml` | Work-specific Linux setup |
| macOS Common | `mac-common/dotbot.yaml` | Common macOS setup |
| macOS Work | `mac-work/dotbot.yaml` | Work-specific macOS setup |

### Linking Specific Environment

To link files for a specific environment:

```bash
cd ~/dotfiles

# Linux Common
dotbot -c linux-common/dotbot.yaml

# macOS Common
dotbot -c mac-common/dotbot.yaml

# Work-specific setups
dotbot -c linux-work/dotbot.yaml
dotbot -c mac-work/dotbot.yaml
```

---

## Configuration Overview

The project is organized into directories for different environments:

| Directory | Purpose |
|-----------|---------|
| `linux-common/` | Configuration files common to Linux environments |
| `mac-common/` | Similar structure, tailored for macOS |
| `mac-work/` | Work-specific macOS configurations |
| `albert-scripts/` | Custom shell utilities and tools |
| `nvim/` | Neovim configurations |

### Directory Structure

```
dotfiles/
├── linux-common/
│   ├── dotbot.yaml          # Dotbot configuration
│   ├── init-scripts/        # Bootstrap scripts
│   ├── config/              # ~/.config/ files
│   └── home/                # Home directory dotfiles
├── mac-common/
│   └── (similar structure)
├── albert-scripts/          # Custom utilities
└── nvim/                    # Neovim configs
    ├── nvchad/
    ├── dojo/
    └── kick-start/
```

---

## Albert Scripts

`albert-scripts/` is a collection of custom shell utilities that enhance the command-line experience. These scripts are automatically sourced when the shell starts.

### Available Tools

#### Fuzzy Search (`fzf/`)

Fuzzy file finding powered by `fzf` and `fd`.

| Function | Alias | Description |
|----------|-------|-------------|
| `ab.fs.search` | `fs` | Search files in configured directories |
| `ab.fs.jump` | `fj` | Jump to a directory via fuzzy search |
| `ab.fs.edit` | `fe` | Edit files via fuzzy search |
| `ab.fs.history` | `fh` | Fuzzy search command history |
| `ab.fs.history.exec` | - | Execute command from history (bound to `Ctrl+R`) |
| `ab.fs.current.search` | `cs` | Search files in current directory only |
| `ab.fs.current.jump` | `cj` | Jump in current directory |
| `ab.fs.current.edit` | `ce` | Edit files in current directory |

**Keybinding:**
- `Ctrl+R` - Interactive fuzzy history search

**Configuration:**
Set these environment variables in `~/.albert-scripts/config.env`:

```bash
# Directories to search
export FS_SEARCH_DIRS=("$HOME/projects" "$HOME/docs")

# Directories to ignore
export FS_SEARCH_IGNORE_DIRS=(node_modules .git target)

# Preview setting (true/false)
export FS_SEARCH_PREVIEW=true

# Default editor
export FS_EDITOR=nvim
```

#### Utilities (`utils/`)

Colorful output functions for shell scripts.

```bash
# Print colored lines
print_red_line "Error message"
print_green_line "Success message"
print_yellow_line "Warning message"
print_blue_line "Info message"

# Print without newline
print_cyan "Loading..."

# Highlighted messages
print_warning_line "This is a warning"
print_error_line "This is an error"
print_info_line "This is info"
```

#### Platform-Specific Scripts

- `osx/` - macOS-specific utilities
- `linux/` - Linux-specific utilities
- `osx-snip/` - macOS snippet tools

---

## Neovim Plugins

Key plugins used in the `nvchad` and `dojo` configurations:

| Plugin | Description |
|--------|-------------|
| **stevearc/conform.nvim** | Lightweight yet powerful formatter plugin. |
| **ojroques/nvim-osc52** | Copy text to system clipboard via OSC 52 (useful over SSH). |
| **neovim/nvim-lspconfig** | Quickstart configs for Nvim LSP. |
| **nvim-treesitter/nvim-treesitter** | Nvim Treesitter configurations. |
| **HiPhish/rainbow-delimiters.nvim** | Rainbow parentheses using Tree-sitter. |
| **fei6409/log-highlight.nvim** | Log file syntax highlighting. |
| **hrsh7th/nvim-cmp** | Completion plugin written in Lua. |
| **Lokaltog/vim-easymotion** | Vim motions on speed. |
| **Bekaboo/dropbar.nvim** | IDE-like winbar. |
| **lukas-reineke/indent-blankline.nvim** | Indent guides. |
| **rainbowhxch/accelerated-jk.nvim** | Accelerated up/down movement. |
| **hat0uma/csvview.nvim** | High-performance CSV viewer. |
| **MeanderingProgrammer/render-markdown.nvim** | Markdown rendering. |
| **mikavilpas/yazi.nvim** | Yazi file manager integration. |
| **tomasky/bookmarks.nvim** | Bookmarks plugin. |
| **folke/snacks.nvim** | Collection of QoL plugins. |
| **NickvanDyke/opencode.nvim** | AI coding assistant integration. |

---

## Init Scripts

Located in `init-scripts/` directories, these automate the setup:

| Script | Purpose |
|--------|---------|
| `init.sh` | Main entry point - runs all install scripts |
| `install_brew.sh` | Installs Homebrew and packages |
| `install_omz_plugins.sh` | Sets up Oh My Zsh and plugins |
| `install_nvm.sh` | Installs Node Version Manager |
| `install_tpm.sh` | Installs Tmux Plugin Manager |
| `install_uv.sh` | Installs `uv` (Python package manager) |
| `install_fuzzy.sh` | Sets up fuzzy finding tools |

---

## License

MIT License - Feel free to use and modify as needed.
