#!/bin/bash

# VSCode-oriented helper functions.
# This file is sourced by ~/.albert-scripts/export.sh, so keep it side-effect
# light: no set -e, no mandatory project-local source, no argv dispatch.

function _vsc.source.env.file() {
  local env_file="$1"

  [[ -n "$env_file" && -f "$env_file" ]] || return 1

  local env_real
  env_real="$(readlink -f "$env_file" 2>/dev/null || printf '%s' "$env_file")"
  case ":${_VSC_ENV_SOURCED_FILES:-}:" in
    *":$env_real:"*) return 0 ;;
  esac

  source "$env_real"
  _VSC_ENV_SOURCED_FILES="${_VSC_ENV_SOURCED_FILES:+$_VSC_ENV_SOURCED_FILES:}$env_real"
}

function vsc.load.env() {
  local context_dir="${1:-$PWD}"
  local albert_path="${ALBERT_SCRIPTS_PATH:-$HOME/.albert-scripts}"
  local env_file

  for env_file in \
    "${ALBERT_VSC_ENV_FILE:-}" \
    "$albert_path/vsc.env" \
    "$context_dir/tdsql-dev-utils/scripts/export.env"; do
    _vsc.source.env.file "$env_file" || true
  done

  local git_root
  git_root="$(git -C "$context_dir" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$git_root" ]]; then
    _vsc.source.env.file "$git_root/tdsql-dev-utils/scripts/export.env" || true
  fi

  return 0
}

function vsc.osc.copy() {
  local input
  input=$(cat | tee /dev/tty)
  printf "\033]52;c;$(echo -n "$input" | base64)\a" >&2
}

function vsc.expand.var() {
  local input="$1"
  [[ -z "$input" ]] && return 1

  if [[ "$input" != @* ]]; then
    echo "$input"
    return 0
  fi

  local rest="${input#@}"
  local var_name="${rest%%/*}"
  local sub_path="${rest#*/}"
  if [[ "$sub_path" == "$rest" ]]; then
    sub_path=""
  fi

  local value="${!var_name:-}"
  if [[ -z "$value" ]]; then
    vsc.load.env "$PWD"
    value="${!var_name:-}"
  fi
  if [[ -z "$value" ]]; then
    echo "Error: variable '$var_name' is not set or empty." >&2
    return 1
  fi

  if [[ -n "$sub_path" ]]; then
    echo "$value/$sub_path"
  else
    echo "$value"
  fi
}

function vsc.find.code.cmd() {
  local candidates=("code" "code-insiders" "buddycn")
  local cmd
  for cmd in "${candidates[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "$cmd"
      return 0
    fi
  done
  echo "Error: none of 'code', 'code-insiders', 'buddycn' found." >&2
  return 1
}

function vsc.open.vscode() {
  local file_path
  file_path="$(vsc.expand.var "$1")" || return 1
  local line_threshold="$2"

  [[ -z "$file_path" ]] && {
    echo "Error: file path is required." >&2
    return 1
  }

  local code_cmd
  code_cmd="$(vsc.find.code.cmd)" || return 1

  local use_new_window=false
  if [[ -n "$line_threshold" && -f "$file_path" ]]; then
    local line_count
    line_count="$(wc -l <"$file_path" 2>/dev/null)"
    line_count="${line_count//[[:space:]]/}"
    if [[ -n "$line_count" ]] && ((line_count > line_threshold)); then
      use_new_window=true
    fi
  fi

  if [[ "$use_new_window" == true ]]; then
    echo "Opening (new window, ${line_count} lines): $file_path"
    $code_cmd -n "$file_path"
  else
    echo "Opening: $file_path"
    $code_cmd "$file_path"
  fi
}

function vsc.find() {
  local find_range
  find_range="$(vsc.expand.var "$1")" || return 1
  local worker_dir="${2:-}"

  if [[ $worker_dir =~ ^[0-9]+$ ]]; then
    echo "get worker dir: $worker_dir"
  else
    worker_dir=""
  fi

  local full_range_to_find="$find_range/$worker_dir"
  local file_to_find="$3"
  local line_threshold="$4"
  local file_path
  file_path=$(find "$full_range_to_find" -type f -name "$file_to_find" 2>/dev/null | sort | head -n 1)

  [[ -z "$file_path" ]] && {
    echo "Error: no file found" >&2
    return 1
  }

  vsc.open.vscode "$file_path" "$line_threshold"
}

function vsc.pick.fzf() {
  command -v fzf >/dev/null 2>&1 || {
    echo "Error: fzf is required for vsc.pick.fzf." >&2
    return 1
  }
  local fd_cmd
  fd_cmd="$(command -v fd || command -v fdfind)" || {
    echo "Error: fd is required for vsc.pick.fzf." >&2
    return 1
  }

  local root_dir
  root_dir="$(vsc.expand.var "$1")" || return 1
  [[ -z "$root_dir" ]] && {
    echo "Error: root dir is required." >&2
    return 1
  }

  # Always-on excludes for heavy dirs; caller patterns ($2) are appended.
  local default_excludes=".git,node_modules,bld,build,dist,out,target,__pycache__,.venv,.cache"
  local exclude_patterns="$default_excludes${2:+,$2}"
  local fd_args=(--type f --hidden --no-ignore --follow)
  local exclude_pattern_list=()
  local exclude_pattern
  IFS=',' read -ra exclude_pattern_list <<<"$exclude_patterns"
  for exclude_pattern in "${exclude_pattern_list[@]}"; do
    exclude_pattern="${exclude_pattern#"${exclude_pattern%%[![:space:]]*}"}"
    exclude_pattern="${exclude_pattern%"${exclude_pattern##*[![:space:]]}"}"
    [[ -n "$exclude_pattern" ]] && fd_args+=(--exclude "$exclude_pattern")
  done

  local file_path
  file_path=$("$fd_cmd" "${fd_args[@]}" . "$root_dir" 2>/dev/null | fzf --prompt="Pick file > " --scheme=path || true)

  [[ -z "$file_path" ]] && {
    echo "No file selected."
    return 0
  }

  vsc.open.vscode "$file_path"
}

function _vsc.git.branch() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  [[ -z "$proj_dir" ]] && {
    echo "Error: project directory is required." >&2
    return 1
  }
  [[ -d "$proj_dir" ]] || {
    echo "Error: project directory does not exist: $proj_dir" >&2
    return 1
  }

  local branch
  branch=$(cd "$proj_dir" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [[ -z "$branch" ]] && {
    echo "Error: could not get branch name from: $proj_dir" >&2
    return 1
  }

  echo "$branch"
}

function _vsc.safe.branch() {
  local branch="$1"
  echo "${branch//\//-}"
}

function _vsc.open.ensure.file() {
  local file_path="${1:-}"
  local header="${2:-}"

  [[ -z "$file_path" ]] && {
    echo "Error: file path is required." >&2
    return 1
  }

  local parent_dir
  parent_dir="$(dirname "$file_path")"
  if [[ ! -d "$parent_dir" ]]; then
    echo "Creating directory: $parent_dir"
    mkdir -p "$parent_dir"
  fi

  if [[ -e "$file_path" && ! -f "$file_path" ]]; then
    echo "Error: target exists but is not a file: $file_path" >&2
    return 1
  fi

  if [[ ! -e "$file_path" ]]; then
    if [[ -n "$header" ]]; then
      printf '%s\n\n' "$header" >"$file_path"
    else
      : >"$file_path"
    fi
    echo "Created file: $file_path"
  fi
}

function _vsc.open.slug() {
  local topic="${1:-draft}"

  topic=$(echo "$topic" |
    tr '[:upper:]' '[:lower:]' |
    tr ' _' '-' |
    sed 's/[^a-z0-9-]//g')

  if [[ -z "$topic" ]]; then
    topic="draft"
  fi

  echo "$topic"
}

function _vsc.open.file() {
  [[ $# -ge 1 ]] || {
    echo "Error: file path is required." >&2
    return 1
  }

  local file_path
  file_path="$(vsc.expand.var "$1")" || return 1
  local line_threshold="${2:-}"

  _vsc.open.ensure.file "$file_path" || return 1
  vsc.open.vscode "$file_path" "$line_threshold"
}

function _vsc.open.issue() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local note_dir
  note_dir="$(vsc.expand.var "$2")" || return 1
  local file_name="${3:-}"

  [[ -z "$note_dir" ]] && {
    echo "Error: note directory is required." >&2
    return 1
  }
  [[ -z "$file_name" ]] && {
    echo "Error: file name is required." >&2
    return 1
  }

  local branch
  branch="$(_vsc.git.branch "$proj_dir")" || return 1
  local safe_branch
  safe_branch="$(_vsc.safe.branch "$branch")"
  local full_path="$note_dir/$safe_branch/$file_name"

  echo "Opening issue file for branch '$branch' ($safe_branch)..."
  _vsc.open.ensure.file "$full_path" || return 1
  vsc.open.vscode "$full_path"
}

function _vsc.iter.dir() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local note_dir
  note_dir="$(vsc.expand.var "$2")" || return 1

  [[ -z "$note_dir" ]] && {
    echo "Error: note directory is required." >&2
    return 1
  }

  local branch
  branch="$(_vsc.git.branch "$proj_dir")" || return 1
  local safe_branch
  safe_branch="$(_vsc.safe.branch "$branch")"
  local iters_dir="$note_dir/$safe_branch/iters"

  if [[ ! -d "$iters_dir" ]]; then
    echo "Creating iter directory: $iters_dir" >&2
    mkdir -p "$iters_dir"
  fi

  echo "$iters_dir"
}

function _vsc.iter.latest.path() {
  local iters_dir="$1"
  ls -v "$iters_dir"/iter-[0-9]*-*.md 2>/dev/null | tail -n 1
}

function _vsc.iter.next.num() {
  local iters_dir="$1"
  local latest
  latest="$(_vsc.iter.latest.path "$iters_dir")"

  local next_num=1
  if [[ -n "$latest" ]]; then
    local latest_name
    latest_name="$(basename "$latest")"
    latest_name="${latest_name#iter-}"
    latest_name="${latest_name%%-*}"
    next_num="$latest_name"
    ((next_num++))
  fi

  echo "$next_num"
}

function _vsc.open.iter() {
  local iters_dir
  iters_dir="$(_vsc.iter.dir "$1" "$2")" || return 1

  local latest
  latest="$(_vsc.iter.latest.path "$iters_dir")"

  if [[ -z "$latest" ]]; then
    local topic
    topic="$(_vsc.open.slug "${3:-}")" || return 1
    latest="$iters_dir/iter-1-${topic}.md"
    _vsc.open.ensure.file "$latest" "# iter-1: $topic" || return 1
  fi

  echo "Latest iter: $(basename "$latest")"
  vsc.open.vscode "$latest"
}

function _vsc.new.iter() {
  local iters_dir
  iters_dir="$(_vsc.iter.dir "$1" "$2")" || return 1

  local topic
  topic="$(_vsc.open.slug "${3:-}")" || return 1

  local next_num
  next_num="$(_vsc.iter.next.num "$iters_dir")" || return 1

  local target_file="$iters_dir/iter-${next_num}-${topic}.md"
  echo "Creating iter file: $target_file"
  _vsc.open.ensure.file "$target_file" "# iter-$next_num: $topic" || return 1

  vsc.open.vscode "$target_file"
}

function _vsc.chat.dir() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  [[ -z "$proj_dir" ]] && {
    echo "Error: project directory is required." >&2
    return 1
  }
  [[ -d "$proj_dir" ]] || {
    echo "Error: project directory does not exist: $proj_dir" >&2
    return 1
  }

  local branch
  branch="$(_vsc.git.branch "$proj_dir")" || return 1
  local safe_branch
  safe_branch="$(_vsc.safe.branch "$branch")"
  local chat_dir="$proj_dir/.ai_dev_chat/$safe_branch"
  if [[ ! -d "$chat_dir" ]]; then
    echo "Creating chat directory: $chat_dir" >&2
    mkdir -p "$chat_dir"
  fi

  echo "$chat_dir"
}

function _vsc.chat.latest.name() {
  local chat_dir="$1"

  ls -1 "$chat_dir" 2>/dev/null |
    grep -E '^[0-9]+\.md$' |
    sort -n |
    tail -n 1
}

function _vsc.open.chat() {
  local chat_dir
  chat_dir="$(_vsc.chat.dir "$1")" || return 1

  local latest
  latest="$(_vsc.chat.latest.name "$chat_dir")"

  local target_file
  if [[ -z "$latest" ]]; then
    target_file="$chat_dir/1.md"
    echo "No chat files found, creating: $target_file"
    : >"$target_file"
  else
    target_file="$chat_dir/$latest"
  fi

  vsc.open.vscode "$target_file"
}

function _vsc.new.chat() {
  local chat_dir
  chat_dir="$(_vsc.chat.dir "$1")" || return 1

  local latest
  latest="$(_vsc.chat.latest.name "$chat_dir")"

  local next_num=1
  if [[ -n "$latest" ]]; then
    next_num="${latest%.md}"
    ((next_num++))
  fi

  local target_file="$chat_dir/$next_num.md"
  echo "Creating chat file: $target_file"
  : >"$target_file"

  vsc.open.vscode "$target_file"
}

function _vsc.talk.dir() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  local talk_dir
  talk_dir="$(_vsc.branch.subdir "$proj_dir" ".ai_dev_talk")" || return 1
  if [[ ! -d "$talk_dir" ]]; then
    echo "Creating talk directory: $talk_dir" >&2
    mkdir -p "$talk_dir"
  fi

  echo "$talk_dir"
}

function _vsc.open.talk() {
  local talk_dir
  talk_dir="$(_vsc.talk.dir "$1")" || return 1

  local latest
  latest="$(_vsc.chat.latest.name "$talk_dir")"

  local target_file
  if [[ -z "$latest" ]]; then
    target_file="$talk_dir/1.md"
    echo "No talk files found, creating: $target_file"
    : >"$target_file"
  else
    target_file="$talk_dir/$latest"
  fi

  vsc.open.vscode "$target_file"
}

function _vsc.new.talk() {
  local talk_dir
  talk_dir="$(_vsc.talk.dir "$1")" || return 1

  local latest
  latest="$(_vsc.chat.latest.name "$talk_dir")"

  local next_num=1
  if [[ -n "$latest" ]]; then
    next_num="${latest%.md}"
    ((next_num++))
  fi

  local target_file="$talk_dir/$next_num.md"
  echo "Creating talk file: $target_file"
  : >"$target_file"

  vsc.open.vscode "$target_file"
}

# Echo <proj_dir>/<sub>/<safe_branch> for the current branch, without creating
# anything. Read-only helper shared by the vsc.ai.* openers.
function _vsc.branch.subdir() {
  local proj_dir="$1"
  local sub="$2"

  [[ -z "$proj_dir" ]] && {
    echo "Error: project directory is required." >&2
    return 1
  }
  [[ -d "$proj_dir" ]] || {
    echo "Error: project directory does not exist: $proj_dir" >&2
    return 1
  }
  [[ -z "$sub" ]] && {
    echo "Error: subdirectory name is required." >&2
    return 1
  }

  local branch
  branch="$(_vsc.git.branch "$proj_dir")" || return 1
  local safe_branch
  safe_branch="$(_vsc.safe.branch "$branch")"
  echo "$proj_dir/$sub/$safe_branch"
}

# Print the most-recently-modified (by mtime) markdown file under a directory,
# searched recursively. Errors if the directory is missing or holds no *.md.
function _vsc.latest.md() {
  local search_dir="$1"

  [[ -z "$search_dir" ]] && {
    echo "Error: search directory is required." >&2
    return 1
  }
  [[ -d "$search_dir" ]] || {
    echo "Error: directory does not exist: $search_dir" >&2
    return 1
  }

  local latest
  latest=$(find "$search_dir" -type f -name '*.md' -printf '%T@\t%p\n' 2>/dev/null |
    sort -nr | head -n 1 | cut -f2-)

  [[ -z "$latest" ]] && {
    echo "Error: no markdown files found under: $search_dir" >&2
    return 1
  }

  echo "$latest"
}

# Open the latest-modified markdown under .ai_dev/<branch> for the project.
function vsc.ai.dev() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  local dev_dir
  dev_dir="$(_vsc.branch.subdir "$proj_dir" ".ai_dev")" || return 1

  local latest
  latest="$(_vsc.latest.md "$dev_dir")" || return 1

  echo "Latest .ai_dev markdown: $(basename "$latest")"
  vsc.open.vscode "$latest"
}

# Open the latest-modified markdown under .ai_dev_chat/<branch> for the project.
function vsc.ai.chat() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  local chat_dir
  chat_dir="$(_vsc.branch.subdir "$proj_dir" ".ai_dev_chat")" || return 1

  local latest
  latest="$(_vsc.latest.md "$chat_dir")" || return 1

  echo "Latest .ai_dev_chat markdown: $(basename "$latest")"
  vsc.open.vscode "$latest"
}

function vsc.open() {
  [[ $# -ge 1 ]] || {
    echo "Error: open target is required." >&2
    echo "Usage: vsc.open <file|issue|iter|chat|talk> ..." >&2
    return 1
  }

  local kind="$1"
  shift

  case "$kind" in
    file | path | vscode)
      _vsc.open.file "$@"
      ;;
    issue)
      _vsc.open.issue "$@"
      ;;
    iter)
      _vsc.open.iter "$@"
      ;;
    chat)
      _vsc.open.chat "$@"
      ;;
    talk)
      _vsc.open.talk "$@"
      ;;
    *)
      _vsc.open.file "$kind" "$@"
      ;;
  esac
}

function vsc.open.iter() {
  vsc.open iter "$@"
}

function vsc.new.iter() {
  _vsc.new.iter "$@"
}

function vsc.open.chat() {
  vsc.open chat "$@"
}

function vsc.new.chat() {
  _vsc.new.chat "$@"
}

function vsc.open.talk() {
  vsc.open talk "$@"
}

function vsc.new.talk() {
  _vsc.new.talk "$@"
}

function vsc.open.issue() {
  vsc.open issue "$@"
}

function vsc.get.branch() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  local branch
  branch="$(_vsc.git.branch "$proj_dir")" || return 1
  echo "$branch" | vsc.osc.copy
}

function vsc.touch.pptt() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local note_dir
  note_dir="$(vsc.expand.var "$2")" || return 1

  [[ -z "$proj_dir" ]] && {
    echo "Error: project directory is required." >&2
    return 1
  }
  [[ -z "$note_dir" ]] && {
    echo "Error: note directory is required." >&2
    return 1
  }
  [[ -d "$proj_dir" ]] || {
    echo "Error: project directory does not exist: $proj_dir" >&2
    return 1
  }

  local branch
  branch="$(_vsc.git.branch "$proj_dir")" || return 1
  local safe_branch
  safe_branch="$(_vsc.safe.branch "$branch")"
  local target="$note_dir/$safe_branch"
  if [[ ! -d "$target" ]]; then
    echo "Creating branch directory: $target"
    mkdir -p "$target"
  fi

  local files=("plan.md" "truth.md" "progress.md")
  local headers=("# plan" "# truth" "# progress")
  local created=0
  local skipped=0
  local i
  for i in "${!files[@]}"; do
    local fpath="$target/${files[$i]}"
    if [[ -f "$fpath" ]]; then
      echo "  skipped: ${files[$i]} (already exists)"
      ((skipped++)) || true
    else
      printf '%s\n' "${headers[$i]}" >"$fpath"
      echo "  created: ${files[$i]}"
      ((created++)) || true
    fi
  done

  echo ""
  echo "Branch:  $branch ($safe_branch)"
  echo "Dir:     $target"
  echo "Created: $created, Skipped: $skipped (already existed)"
}

function vsc.get.mergebase() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local master_branch
  master_branch="$(vsc.expand.var "$2")" || return 1

  [[ -z "$proj_dir" ]] && {
    echo "Error: project directory is required." >&2
    return 1
  }
  [[ -z "$master_branch" ]] && {
    echo "Error: master branch name is required." >&2
    return 1
  }
  [[ -d "$proj_dir" ]] || {
    echo "Error: project directory does not exist: $proj_dir" >&2
    return 1
  }

  local diff_commit_hash
  diff_commit_hash=$(cd "$proj_dir" && git merge-base "origin/$master_branch" HEAD 2>/dev/null)
  [[ -z "$diff_commit_hash" ]] && {
    echo "Error: could not compute merge-base." >&2
    return 1
  }

  echo "$diff_commit_hash" | vsc.osc.copy
}
