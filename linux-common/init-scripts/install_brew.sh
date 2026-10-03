#!/bin/bash
# set -x

BREW_USER="linuxbrew"
BREW_HOME="/home/linuxbrew"
BREW_SHELLENV='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Brewfile"

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

# 从 Brewfile 读取指定类型（brew / cask）的包名
function read_brewfile {
  local kind="$1"
  sed -nE "s/^[[:space:]]*${kind}[[:space:]]+\"([^\"]+)\".*/\1/p" "${BREWFILE}"
}

# Brewfile 由当前用户读取后把包名交给 brew 用户安装，root 场景下 brew 用户无需读取仓库文件
function install_brew_kind {
  local kind="$1"
  local list_flag="--formula"
  local install_flag=""
  [ "${kind}" = "cask" ] && list_flag="--cask" && install_flag="--cask"

  local packages
  mapfile -t packages < <(read_brewfile "${kind}")
  [ ${#packages[@]} -gt 0 ] || return 0
  printf "%s\n" "${packages[*]}"

  # 一次性获取所有已安装的包
  local installed
  installed=$(run_as_brew_user "brew list ${list_flag} -1" 2>/dev/null)

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
    run_as_brew_user "brew install ${install_flag} ${to_install[*]}"
  fi
}

function install_brew_packages {
  [ -f "${BREWFILE}" ] || {
    echo "Brewfile not found: ${BREWFILE}"
    return 1
  }

  install_brew_kind brew && install_brew_kind cask
}

install_brew && install_brew_packages
