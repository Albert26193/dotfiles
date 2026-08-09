#!/usr/bin/env bash
# Copy the current Claude Code session resume command (or ID) to the system
# clipboard via OSC52. Works over SSH, in tmux, and in most modern terminals.
#
# Usage:
#   copy-session-id.sh [--id]          copy just the UUID
#   copy-session-id.sh --resume        copy "claude --resume <id>" (default)
#
# Intended as a SessionStart hook:
#   "command": "bash $HOME/.claude/scripts/copy-session-id.sh"

set -uo pipefail

#-----------------------------------------
# overview: print the OSC52 escape sequence to stdout
# @param: text to place on the clipboard
# @output: OSC52 escape sequence printed to stdout
#-----------------------------------------
function emit_osc52 {
  local text="$1"
  local b64
  b64="$(printf '%s' "${text}" | base64 -w0)"

  local osc52_seq
  osc52_seq="$(printf '\033]52;c;%s\a' "${b64}")"

  # tmux needs the sequence wrapped so it passes through to the outer terminal
  if [[ -n "${TMUX:-}" ]]; then
    printf '\033Ptmux;\033%s\033\\' "${osc52_seq}"
  else
    printf '%s' "${osc52_seq}"
  fi
}

#-----------------------------------------
# overview: try to discover the session ID from CLAUDE_SESSION_ID env var
#           or by finding the session file matching our PID. Returns empty
#           string if neither works.
# @output: session UUID string, or empty
#-----------------------------------------
function discover_session_id {
  # env var — set during resume, and sometimes during startup
  if [[ -n "${CLAUDE_SESSION_ID:-}" ]]; then
    printf '%s' "${CLAUDE_SESSION_ID}"
    return 0
  fi

  # fallback: walk up the process tree looking for a session file
  # named <pid>.json in ~/.claude/sessions/
  local pid="${PPID}"
  for i in {1..5}; do
    if [[ -f "${HOME}/.claude/sessions/${pid}.json" ]]; then
      python3 -c "import json,sys; print(json.load(open('${HOME}/.claude/sessions/${pid}.json'))['sessionId'])" 2>/dev/null
      return 0
    fi
    pid="$(ps -o ppid= -p "${pid}" 2>/dev/null | tr -d ' ')"
    [[ -z "${pid}" ]] && break
  done
  return 1
}

#-----------------------------------------
function main {
  local mode="resume"  # resume | id
  local session_id=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)    mode="id"; shift ;;
      --resume) mode="resume"; shift ;;
      *) session_id="$1"; shift ;;
    esac
  done

  # explicit arg takes priority, then auto-discover
  if [[ -z "${session_id}" ]]; then
    session_id="$(discover_session_id)"
  fi

  if [[ -z "${session_id}" ]]; then
    # session file not ready yet (e.g. SessionStart:startup) — not an error
    exit 0
  fi

  local text
  if [[ "${mode}" == "resume" ]]; then
    text="claude --resume ${session_id}"
  else
    text="${session_id}"
  fi

  emit_osc52 "${text}"
}

main "$@"
