#!/bin/bash
# herdr 体验期封装（mac-common）。tmux.sh 保持不动，这里只做 herdr 对应物。
# 依赖：herdr、python3（标准库即可）、fzf（ab.herdr.move）、nvim（ab.herdr.view）

_AB_HERDR_PY="${ALBERT_SCRIPTS_PATH:-$HOME/.albert-scripts}/osx/herdr/herdr-ab.py"
_AB_HERDR_LOG="${HOME}/.herdr-log"

function _ab.herdr.check {
  command -v herdr >/dev/null || {
    printf "no herdr found, return 1\n"
    return 1
  }
}

# tmuxp load 的对应物：ab.herdr.load main（查 ~/.config/herdr/layouts/main.json）
function ab.herdr.load {
  _ab.herdr.check || return 1
  python3 "$_AB_HERDR_PY" load "${1:?usage: ab.herdr.load <layout-name|path>}"
}

# tmuxp freeze 的对应物：ab.herdr.export > ~/.config/herdr/layouts/foo.json
function ab.herdr.export {
  _ab.herdr.check || return 1
  python3 "$_AB_HERDR_PY" export "$@"
}

# tmux select-layout even-* 的对应物（已绑定 prefix+e）
function ab.herdr.equal {
  _ab.herdr.check || return 1
  python3 "$_AB_HERDR_PY" equal "$@"
}

# tmux join-pane 的对应物（已绑定 prefix+m）
function ab.herdr.move {
  _ab.herdr.check || return 1
  python3 "$_AB_HERDR_PY" move "$@"
}

# tmux kill-session -t 的对应物：关闭指定 label 的 workspace
function ab.herdr.kill {
  _ab.herdr.check || return 1
  python3 "$_AB_HERDR_PY" kill "${1:?usage: ab.herdr.kill <workspace-label>}"
}

# 直接调 socket API：ab.herdr.call layout.export '{}'
function ab.herdr.call {
  _ab.herdr.check || return 1
  python3 "$_AB_HERDR_PY" call "$@"
}

# ab.tmux.save 的对应物：保存当前 pane 最近 N 行（默认 1000）
function ab.herdr.save {
  _ab.herdr.check || return 1
  [[ -n "$HERDR_PANE_ID" ]] || {
    printf "not inside a herdr pane (HERDR_PANE_ID empty)\n"
    return 1
  }
  local line_number="${1:-1000}"
  mkdir -p "$_AB_HERDR_LOG"
  local out="${_AB_HERDR_LOG}/$(date +"%Y%m%d-%H:%M:%S").herdr.log"
  herdr pane read "$HERDR_PANE_ID" --source recent --lines "$line_number" >"$out" &&
    printf "saved %s lines -> %s\n" "$line_number" "$out"
}

# ab.tmux.view 的对应物：只读打开最新一份
function ab.herdr.view {
  local latest
  latest=$(ls -t "$_AB_HERDR_LOG"/*.herdr.log 2>/dev/null | head -n 1)
  [[ -n "$latest" ]] || {
    printf "no log under %s\n" "$_AB_HERDR_LOG"
    return 0
  }
  nvim -R "$latest"
}

# ab.tmux.now 的对应物
function ab.herdr.now {
  ab.herdr.save "${1:-1000}" && ab.herdr.view
}

# ab.tmux.prune 的对应物：确认后只保留最新 3 份
ab.herdr.prune() (
  source "${ALBERT_SCRIPTS_PATH:-$HOME/.albert-scripts}/utils/utils.sh"
  [[ -d "$_AB_HERDR_LOG" ]] || return 0
  yn_prompt "prune herdr logs (keep newest 3)?" || return 0
  ls -t "$_AB_HERDR_LOG"/*.herdr.log 2>/dev/null | tail -n +4 | while read -r f; do
    rm "$f" && print_green_line "rm $f"
  done
)
