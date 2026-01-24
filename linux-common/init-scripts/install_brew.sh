#!/bin/bash
# set -x

function install_brew {
  [ -d /home/linuxbrew/.linuxbrew/ ] && {
    printf "%s\n" "------------------------------"
    printf "%s\n" "brew has installed, exit."
    printf "%s\n" "------------------------------"
    return 0
  }

  # Install brew for root user
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

function install_brew_packages {
  # local brew_installer_name="linuxbrew"
  local packages=("lazygit" "neovim" "tailspin" "delta" "ccls" "dotbot" "starship" "gdb" "cgdb" "mycli" "ripgrep" "fd" "fzf" "yazi" "tmux" "git")
  printf "%s\n" "${packages[*]}"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  for package in "${packages[@]}"; do
    command -v "$package" >/dev/null 2>&1 && {
      echo "has installed $package"
      continue
    }
    # cd /home/linuxbrew && su "$brew_installer_name" -c "env PATH=/home/linuxbrew/.linuxbrew:$PATH brew install ${package}"
    bash -c "env PATH=/home/linuxbrew/.linuxbrew:$PATH brew install ${package}"
    # brew install "${package}"
  done
}

# install_brew && install_brew_packages && install_brew_target "install" "dotbot"
install_brew && install_brew_packages
