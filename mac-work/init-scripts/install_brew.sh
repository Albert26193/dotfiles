#!/bin/bash

function install_brew {
  [ -d /opt/homebrew/bin/ ] && {
    printf "%s\n" "------------------------------"
    printf "%s\n" "brew has installed, exit."
    printf "%s\n" "------------------------------"
    return 0
  }

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_brew
