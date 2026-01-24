#!/bin/bash

# save tmux
ab.tmux.save() {
  { command -v tmux >/dev/null; } || {
    printf "no tmux found, return 0\n"
    return 0
  }
  local tmux_log_path="${HOME}/.tmux-log"
  [ -d "$tmux_log_path" ] || {
    printf "%s\n" "$tmux_log_path does not exist, creating..."
    mkdir -p "$tmux_log_path"
  }
  local line_number=1000

  if [[ -z "$1" ]]; then
    printf "default line number is %d\n" "$line_number"
  else
    line_number="$1"
  fi

  tmux capture-pane -S -"$line_number" &&
    tmux save-buffer "${tmux_log_path}/$(date +"%Y%m%d-%H:%M:%S").tmux.log"
}

function ab.tmux.view {
  # check path
  local tmux_log_path="${HOME}/.tmux-log"
  [ -d "$tmux_log_path" ] || {
    printf "%s\n" "$tmux_log_path not exist, return 0"
    return 0
  }
  # view tmux log
  cd "${tmux_log_path}" &&
    nvim -R $(ls -l -rt | grep -E "\.log$" | tail -n 1 | awk '{print $NF}') &&
    cd -
}

ab.tmux.prune() (
  # source utils
  source "${ALBERT_SCRIPTS_PATH}/utils.sh"
  # check path
  local tmux_log_path="${HOME}/.tmux-log"
  [ -d "$tmux_log_path" ] || {
    printf "%s\n" "$tmux_log_path not exist, return 0"
    return 0
  }
  cd "$tmux_log_path" && print_yellow_line "pwd: $(pwd)"
  # yn prompt
  yn_prompt "prune all mtr logs?" && {
    ls -al -t | tail -n +4 | awk '{print $NF}' | grep -E ".log$" | while read -r file_to_rm; do
      rm "$file_to_rm" && print_green_line "rm $file_to_rm"
    done
  }
)

# form github
# https://github.com/microsoft/vscode-remote-release/issues/2763
# https://github.com/microsoft/vscode-remote-release/issues/2763#issuecomment-2227170390
ab.tmux.fix() {
  local session_id=$1
  local socket_name="$2"

  if [ -z "${session_id}" ]; then
    echo "Usage: tmux-session-fix <session_id> ?<socket_name>"
    return 1
  fi

  if [ -n "${socket_name}" ]; then
    local socket_path="/tmp/tmux-${UID}/${socket_name}"
  else
    local socket_path="/tmp/tmux-${UID}/default"
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

  cmd_vscode_ipc_hook_cli="export VSCODE_IPC_HOOK_CLI=${vscode_ipc_hook_cli}"
  echo "Command: ${cmd_vscode_ipc_hook_cli}"

  # Set tmux environment variable for new panes
  tmux -S "${socket_path}" set-environment -t "${session_id}" VSCODE_IPC_HOOK_CLI "${vscode_ipc_hook_cli}"

  # Update all panes that only have one process running
  tmux -S "${socket_path}" list-windows -t="${session_id}" -F "#{window_id}" |
    while read -r window_id; do
      tmux -S "${socket_path}" list-panes -t="${window_id}" -F '#{pane_id} #{pane_tty}' |
        while read -r pane_id pane_tty; do
          local pid_count
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

# check tmux buffer now
function ab.tmux.now {
  local line_number=1000
  if [[ -z "$1" ]]; then
    printf "default line number is %d\n" "$line_number"
  else
    line_number="$1"
  fi
  ab.tmux.save "$line_number" && ab.tmux.view
}
