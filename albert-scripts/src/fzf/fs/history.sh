#!/bin/bash

# @desc: 模糊检索 shell 历史命令并在确认后执行
# @alias: fh
function ab.fs.history {
  local selected_command
  selected_command=$(
    fc -ln 1 |
      awk '!seen[$0]++' |
      fzf --tac --height 40% --reverse
  )

  [[ -z "${selected_command}" ]] && return 1

  printf "%s" "you have selected: "
  _ab.ui.info "${selected_command}"

  if _ab.ui.yn "sure to execute the command?"; then
    print -s "${selected_command}"
    eval "${selected_command}"
  else
    _ab.ui.yellow "NOT execute the command"
  fi
}

# @desc: 模糊检索 shell 历史命令并直接执行（已绑定 Ctrl+R）
# @tags: keybind
function ab.fs.history.exec {
  local selected_command
  selected_command=$(
    fc -ln 1 |
      awk '!seen[$0]++' |
      fzf --tac --height 40% --reverse
  )

  [[ -z "${selected_command}" ]] && return 1

  print -s "${selected_command}"
  eval "${selected_command}"
}
