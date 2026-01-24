#!/bin/bash

function install_uv {
  [ ! -f ${HOME}/.local/bin/uv ] || {
    printf "%s\n" "----------------------------"
    printf "%s\n" "uv has installed, return 0"
    printf "%s\n" "----------------------------"
    return 0
  }

  # install to ~/.local/bin
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

# function install_uv_packages {
#   nv tool install dotbot
#   nv tool install mycli
# }

install_uv
