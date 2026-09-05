#!/bin/bash
# set -x

NIX_INSTALL_URL="https://nixos.org/nix/install"
NIX_PROFILE_SCRIPT="${HOME}/.nix-profile/etc/profile.d/nix.sh"
NIX_CONF_FILE="${XDG_CONFIG_HOME:-${HOME}/.config}/nix/nix.conf"

function ensure_nix_conf {
  [ -f "${NIX_CONF_FILE}" ] && return 0

  # 以 root 做单用户安装时没有 nixbld 构建用户组，容器里也拿不到 sandbox，
  # 这两项不关掉安装会直接失败
  mkdir -p "$(dirname "${NIX_CONF_FILE}")"
  cat >"${NIX_CONF_FILE}" <<'EOF'
build-users-group =
sandbox = false
EOF
}

function install_nix {
  [ -f "${NIX_PROFILE_SCRIPT}" ] && {
    printf "%s\n" "------------------------------"
    printf "%s\n" "nix has installed, exit."
    printf "%s\n" "------------------------------"
    return 0
  }

  ensure_nix_conf

  # --no-daemon：单用户模式，不依赖 systemd
  # NIX_INSTALLER_NO_MODIFY_PROFILE：禁止安装脚本改写 ~/.zshrc 等存量文件
  NIX_INSTALLER_NO_MODIFY_PROFILE=1 \
    sh <(curl -fsSL "${NIX_INSTALL_URL}") --no-daemon
}

install_nix
