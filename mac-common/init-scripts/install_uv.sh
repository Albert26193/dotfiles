#!/bin/bash

function install_uv {
  [ -z ${HOME}/.local/bin/uv ] || {
    printf "%s\n" "uv has installed, return 0"
    return 0
  }

  # install to ~/.local/bin
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

function install_uv_packages {
  nv tool install dotbot
}

install_uv
