#!/bin/bash

# cgdb attach --> ca
# ab.cgdb.attach
ab.ca() {
  local query_param="$1"
  local debugger_path="/home/linuxbrew/.linuxbrew/bin/gdb"
  local gdb_log_path="${HOME}/.gdb/logs"
  mkdir -p "$gdb_log_path"

  pid=$(ps -ef | grep -E 'mysqld|sqlengine' | fzf --query "$query_param" | awk '{print $2}')
  [[ -z $pid ]] && return
  echo "attach pid: $pid"

  local logfile="$gdb_log_path/$(date +%F).log"

  #  -ex "set logging off" \
  #  -ex "set logging file $logfile" \
  #  -ex "set logging on" \
  #  -ex "set trace-commands off" \
  #  -ex "set trace-commands on" \
  cgdb \
    -d "$debugger_path" \
    -ex "printf \"---------- CGDB  $(date '+%F %T') -------\n\"" \
    -ex "attach $pid"
}

ab.gdb.log() {
  local gdb_log_path="${HOME}/.gdb/logs"
  cd "$gdb_log_path" && nvim -R $(ls -l -rt | grep -E ".log$" | tail -n 1 | awk '{print $NF}')
}
