#!/bin/bash

# Copy a demo config from func/ into the current project.
# Non-destructive: refuses to overwrite an existing target unless -f/--force.
#   $1: source json under func/
#   $2: destination path relative to $PWD
function _ab.load.copy {
  local src_name="$1"
  local dst_rel="$2"
  local force="$3"

  local root="${ALBERT_SCRIPTS_PATH:-$HOME/.albert-scripts}"
  local src="${root}/func/${src_name}"
  local dst="${PWD}/${dst_rel}"

  if [[ ! -f "$src" ]]; then
    echo "source not found: $src" >&2
    return 1
  fi

  if [[ -e "$dst" && "$force" != "1" ]]; then
    echo "target exists: $dst" >&2
    echo "pass -f / --force to overwrite" >&2
    return 1
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "wrote: $dst"
}

# Parse a leading -f/--force flag, return 1 in the named var when present.
function _ab.load.force {
  case "$1" in
    -f | --force) return 0 ;;
    *) return 1 ;;
  esac
}

# ab.load.vsc_task -> .vscode/tasks.json
function ab.load.vsc_task {
  local force=0
  _ab.load.force "$1" && force=1
  _ab.load.copy "demo.vsc.json" ".vscode/tasks.json" "$force"
}

# ab.load.claude -> .claude/settings.json
function ab.load.claude {
  local force=0
  _ab.load.force "$1" && force=1
  _ab.load.copy "demo.claude.json" ".claude/settings.json" "$force"
}
