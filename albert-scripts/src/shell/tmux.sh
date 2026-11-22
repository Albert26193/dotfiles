#!/bin/bash

# @desc: 保存当前 tmux pane 最近 N 行输出到 ~/.tmux-log
# @usage: ab.tmux.save [lines=1000]
function ab.tmux.save {
  { command -v tmux >/dev/null; } || {
    printf "no tmux found, return 0\n"
    return 0
  }
  local tmux_log_path="${HOME}/.tmux-log"
  [ -d "${tmux_log_path}" ] || {
    printf "%s\n" "${tmux_log_path} does not exist, creating..."
    mkdir -p "${tmux_log_path}"
  }
  local line_number=1000

  if [[ -z "$1" ]]; then
    printf "default line number is %d\n" "${line_number}"
  else
    line_number="$1"
  fi

  tmux capture-pane -S -"${line_number}" &&
    tmux save-buffer "${tmux_log_path}/$(date +"%Y%m%d-%H:%M:%S").tmux.log"
}

# @desc: 用 nvim 只读打开最新一份 tmux 日志
function ab.tmux.view {
  local tmux_log_path="${HOME}/.tmux-log"
  [ -d "${tmux_log_path}" ] || {
    printf "%s\n" "${tmux_log_path} not exist, return 0"
    return 0
  }
  cd "${tmux_log_path}" &&
    nvim -R "$(ls -l -rt | grep -E "\.log$" | tail -n 1 | awk '{print $NF}')" &&
    cd -
}

# @desc: 交互确认后清理旧 tmux 日志（仅保留最新 3 份）
function ab.tmux.prune {
  (
    local tmux_log_path="${HOME}/.tmux-log"
    [ -d "${tmux_log_path}" ] || {
      printf "%s\n" "${tmux_log_path} not exist, return 0"
      return 0
    }
    cd "${tmux_log_path}" && _ab.ui.yellow "pwd: $(pwd)"
    _ab.ui.yn "prune all mtr logs?" && {
      local file_to_rm
      ls -al -t | tail -n +4 | awk '{print $NF}' | grep -E "\.log$" | while read -r file_to_rm; do
        rm "${file_to_rm}" && _ab.ui.green "rm ${file_to_rm}"
      done
    }
  )
}

# @desc: 修复指定 tmux session 内所有空闲 pane 的 VSCODE_IPC_HOOK_CLI
# @usage: ab.tmux.fix <session_id> [socket_name]
function ab.tmux.fix {
  local session_id="$1"
  local socket_name="$2"

  if [ -z "${session_id}" ]; then
    echo "Usage: tmux-session-fix <session_id> ?<socket_name>"
    return 1
  fi

  local socket_path
  if [ -n "${socket_name}" ]; then
    socket_path="/tmp/tmux-${UID}/${socket_name}"
  else
    socket_path="/tmp/tmux-${UID}/default"
  fi

  if [ "${TERM_PROGRAM}" != "vscode" ]; then
    echo "This command is only meant to be run outside of tmux, in the VS Code shell. Returning."
    return 1
  fi

  local vscode_ipc_hook_cli
  vscode_ipc_hook_cli=$(set | grep VSCODE_IPC_HOOK_CLI= | head -n1 | cut -d'=' -f2)
  if [ -z "${vscode_ipc_hook_cli}" ]; then
    echo "VSCODE_IPC_HOOK_CLI is not set. Are you running this in a VS Code terminal? Returning."
    return 1
  fi

  local cmd_vscode_ipc_hook_cli="export VSCODE_IPC_HOOK_CLI=${vscode_ipc_hook_cli}"
  echo "Command: ${cmd_vscode_ipc_hook_cli}"

  tmux -S "${socket_path}" set-environment -t "${session_id}" VSCODE_IPC_HOOK_CLI "${vscode_ipc_hook_cli}"

  local window_id pane_id pane_tty pid_count
  tmux -S "${socket_path}" list-windows -t="${session_id}" -F "#{window_id}" |
    while read -r window_id; do
      tmux -S "${socket_path}" list-panes -t="${window_id}" -F '#{pane_id} #{pane_tty}' |
        while read -r pane_id pane_tty; do
          pid_count=$(ps -t "${pane_tty}" -o pid= | wc -l)
          if [ "${pid_count}" -gt 1 ]; then
            echo "Pane ${pane_id} has more than one process running. Skipping"
            continue
          else
            echo "Executing command in socket: ${socket_path}, session: ${session_id}, window: ${window_id}, pane: ${pane_id}"
            tmux -S "${socket_path}" send-keys -t "${pane_id}" "${cmd_vscode_ipc_hook_cli}" C-m
          fi
        done
    done
}

# @desc: 立刻保存当前 tmux pane 日志并只读打开
# @usage: ab.tmux.now [lines=1000]
function ab.tmux.now {
  local line_number=1000
  if [[ -z "$1" ]]; then
    printf "default line number is %d\n" "${line_number}"
  else
    line_number="$1"
  fi
  ab.tmux.save "${line_number}" && ab.tmux.view
}

# @desc: fzf 选择并切换到目标 tmux window/session
function ab.tmux.switch {
  local session
  session=$(tmux list-windows -a | fzf | sed 's/: .*//g')
  [[ -n "${session}" ]] && tmux switch-client -t "${session}"
}
