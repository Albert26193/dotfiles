#!/bin/bash

# @desc: 通过 uv 安装并全局固定 Python 3.13
# @tags: python uv
function ab.install.py {
  uv python install 3.13 --default
  uv python pin --global 3.13
  export UV_PYTHON=3.13
}

# @desc: 创建 linuxbrew 用户并无交互安装 Linuxbrew
# @tags: brew linuxbrew
function ab.install.brew {
  local brew_user="linuxbrew"
  local brew_home="/home/${brew_user}"
  local brew_bin="${brew_home}/.linuxbrew/bin/brew"

  if [[ -x "${brew_bin}" ]]; then
    _ab.ui.green "------------------------------"
    _ab.ui.green "brew is already installed – exiting."
    _ab.ui.green "------------------------------"
    return 0
  fi

  if ! id "${brew_user}" &>/dev/null; then
    _ab.ui.yellow "Creating user '${brew_user}' with home '${brew_home}'..."
    useradd       --create-home       --home-dir "${brew_home}"       --shell /bin/bash       --comment "Linuxbrew package manager"       "${brew_user}"
  else
    _ab.ui.green "User '${brew_user}' already exists."
  fi

  _ab.ui.yellow "Installing Homebrew for user '${brew_user}'..."
  su - "${brew_user}" -c 'NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

  if [[ -x "${brew_bin}" ]]; then
    _ab.ui.green "Homebrew installed successfully."
  else
    _ab.ui.red "Homebrew installation failed – ${brew_bin} not found."
    return 1
  fi
}
