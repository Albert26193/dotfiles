#!/bin/bash

# @desc: 通过 OSC 52 将标准输入写入本地剪贴板（同时回显到终端）
# @usage: cmd | ab.clip
# @tags: clipboard osc52
function ab.clip {
  local input
  input=$(cat | tee /dev/tty)
  printf "\033]52;c;$(printf '%s' "${input}" | base64)\a" >&2
}

# @desc: 复制上一条 shell 历史命令到剪贴板
# @tags: clipboard osc52
function ab.clip.last {
  fc -ln | tail -n 1 | ab.clip
}
