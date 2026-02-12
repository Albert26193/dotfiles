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
  local packages=("lazygit" "neovim" "tailspin" "delta" "ccls" "dotbot" "starship" "gdb" "cgdb" "mycli" "ripgrep" "fd" "fzf" "yazi" "tmux" "git" "zoxide")
  printf "%s\n" "${packages[*]}"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  # 一次性获取所有已安装的 brew 包列表，避免循环中重复调用
  local installed
  installed=$(brew list --formula -1)

  for package in "${packages[@]}"; do
    if echo "$installed" | grep -qx "$package"; then
      echo "has installed $package"
      continue
    fi
    bash -c "env PATH=/home/linuxbrew/.linuxbrew:$PATH brew install ${package}"
  done
}

# install_brew && install_brew_packages && install_brew_target "install" "dotbot"
install_brew && install_brew_packages
