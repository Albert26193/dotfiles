#!/bin/bash

# @desc: fzf 选择 mysqld/sqlengine 进程并用 cgdb attach 调试
# @usage: ab.gdb.attach [query]
# @alias: ab.ca
function ab.gdb.attach {
  local query_param="$1"
  local debugger_path="/home/linuxbrew/.linuxbrew/bin/gdb"
  local gdb_log_path="${HOME}/.gdb/logs"
  mkdir -p "${gdb_log_path}"

  local pid
  pid=$(ps -ef | grep -E 'mysqld|sqlengine' | fzf --query "${query_param}" | awk '{print $2}')
  [[ -z "${pid}" ]] && return
  echo "attach pid: ${pid}"

  cgdb     -d "${debugger_path}"     -ex "printf \"---------- CGDB  $(date '+%F %T') -------\n\""     -ex "attach ${pid}"
}

# @desc: 用 nvim 只读打开 ~/.gdb/logs 下最新一份 GDB 日志
function ab.gdb.log {
  local gdb_log_path="${HOME}/.gdb/logs"
  cd "${gdb_log_path}" && nvim -R "$(ls -l -rt | grep -E "\.log$" | tail -n 1 | awk '{print $NF}')"
}
