#!/bin/bash

function install_fuzzy_shell {
  # if has existence
  [ ! -z ~/.fuzzy_shell ] && {
    printf "%s\n" "---------------------------"
    printf "fuzzy shell has installed\n"
    printf "%s\n" "---------------------------"
    return 0
  }
  # clone the repo
  git clone https://github.com/Albert26193/fuzzy-shell.git
  # install on Linux
  cd fuzzy-shell && sudo bash install/install.sh
}

install_fuzzy_shell
