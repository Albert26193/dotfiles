#!/bin/bash

# install nvm and init
function install_nvm {
  [ -d $HOME/.nvm ] && {
    printf "%s\n" "--------------------------------"
    printf "%s\n" "nvm has installed, return 0"
    printf "%s\n" "--------------------------------"
    return 0
  }
  # Download and install nvmercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  # in lieu of restarting the shell
  \. "$HOME/.nvm/nvm.sh"
  # Download and install Node.js:
  nvm install 22
  # Verify the Node.js version:
  node -v     # Should print "v22.17.1".
  nvm current # Should print "v22.17.1".
  # Verify npm version:
  npm -v # Should print "10.9.2".
  # use 22
  nvm use 22
  # uninstall 16
  nvm uninstall 16
  # default 22
  nvm alias default 22
}

install_nvm
