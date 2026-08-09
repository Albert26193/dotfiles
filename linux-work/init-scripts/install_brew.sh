#!/bin/bash
# set -x

BREW_USER="linuxbrew"
BREW_HOME="/home/linuxbrew"
BREW_SHELLENV='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'

function is_in_container {
  [ -f /.dockerenv ] || grep -qsE '(docker|containerd|lxc)' /proc/1/cgroup 2>/dev/null
}

function ensure_brew_user {
  if id "${BREW_USER}" &>/dev/null; then
    echo "User '${BREW_USER}' already exists."
    return 0
  fi

  echo "Creating user '${BREW_USER}'..."
  useradd --system --create-home --home-dir "${BREW_HOME}" --shell /bin/bash "${BREW_USER}"
  chmod 755 "${BREW_HOME}"
}

function run_as_brew_user {
  if [ "$(id -u)" -eq 0 ] && ! is_in_container; then
    su - "${BREW_USER}" -c "${BREW_SHELLENV} && $*"
  else
    eval "${BREW_SHELLENV}" && eval "$@"
  fi
}

function install_brew {
  [ -x "${BREW_HOME}/.linuxbrew/bin/brew" ] && {
    printf "%s\n" "------------------------------"
    printf "%s\n" "brew has installed, exit."
    printf "%s\n" "------------------------------"
    return 0
  }

  if [ "$(id -u)" -eq 0 ] && ! is_in_container; then
    ensure_brew_user
    su - "${BREW_USER}" -c 'NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  else
    NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

function install_brew_packages {
  local packages=("lazygit" "neovim" "tailspin" "delta" "ccls" "dotbot" "starship" "gdb" "cgdb" "mycli" "ripgrep" "fd" "fzf" "yazi" "tmux" "git" "jq" "duf" "zoxide" "starship" "tmuxp")
  printf "%s\n" "${packages[*]}"

  # 一次性获取所有已安装的包
  local installed
  installed=$(run_as_brew_user "brew list --formula -1" 2>/dev/null)

  # 收集需要安装的包
  local to_install=()
  for package in "${packages[@]}"; do
    if echo "${installed}" | grep -qx "${package}"; then
      echo "has installed ${package}"
    else
      to_install+=("${package}")
    fi
  done

  # 一次性安装所有缺失的包
  if [ ${#to_install[@]} -gt 0 ]; then
    echo "Installing: ${to_install[*]}"
    run_as_brew_user "brew install ${to_install[*]}"
  fi
}

install_brew && install_brew_packages
