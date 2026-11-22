#!/bin/bash

# @desc: 用 nvim 编辑 ~/.vscode-server/server-env-setup
function ab.env.vsc {
  nvim "${HOME}/.vscode-server/server-env-setup"
}

# @desc: 用 nvim 编辑 ~/.cursor-server/server-env-setup
function ab.env.cursor {
  nvim "${HOME}/.cursor-server/server-env-setup"
}
