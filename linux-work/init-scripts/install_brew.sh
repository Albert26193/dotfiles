#!/bin/bash
# set -x

BREW_USER="linuxbrew"
BREW_HOME="/home/linuxbrew"
BREW_BIN="${BREW_HOME}/.linuxbrew/bin/brew"
BREWFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Brewfile"

# root 直接执行特权操作，非 root 经 sudo 执行（最小容器可能没有 sudo）
SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

# brew 一律以 brew 用户执行，执行前加载 shellenv
function run_as_brew_user {
  ${SUDO} su - "${BREW_USER}" -c "eval \"\$(${BREW_BIN} shellenv)\" && $*"
}

# 幂等：缺用户则创建，home 属主不对则修正
function ensure_brew_user {
  if ! id "${BREW_USER}" &>/dev/null; then
    echo "Creating user '${BREW_USER}'..."
    ${SUDO} useradd --create-home --home-dir "${BREW_HOME}" --shell /bin/bash "${BREW_USER}" || return 1
  fi

  [ -d "${BREW_HOME}" ] || ${SUDO} mkdir -p "${BREW_HOME}"

  if [ -n "$(${SUDO} find "${BREW_HOME}" \( ! -user "${BREW_USER}" -o ! -group "${BREW_USER}" \) -print -quit)" ]; then
    echo "Fixing ownership of ${BREW_HOME}..."
    ${SUDO} chown -R "${BREW_USER}:${BREW_USER}" "${BREW_HOME}"
  fi

  ${SUDO} chmod 755 "${BREW_HOME}"
}

function install_brew {
  [ -x "${BREW_BIN}" ] && {
    printf "%s\n" "------------------------------"
    printf "%s\n" "brew has installed, exit."
    printf "%s\n" "------------------------------"
    return 0
  }

  ${SUDO} su - "${BREW_USER}" -c 'NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
}

# brew 用户可能读不到仓库文件（如 /root 下），Brewfile 经 stdin 传入
function install_brew_packages {
  [ -f "${BREWFILE}" ] || {
    echo "Brewfile not found: ${BREWFILE}"
    return 1
  }

  run_as_brew_user "brew bundle --file=-" <"${BREWFILE}"
}

ensure_brew_user && install_brew && install_brew_packages
