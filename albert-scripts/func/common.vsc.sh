#!/bin/bash

# VSCode-oriented helper functions.
# Sourced by bin/vsc-task (bash, `set -e`), which then invokes "$@" — the first
# tasks.json argument is a function name here. Keep this file side-effect light:
# no set -e, no mandatory project-local source, no argv dispatch.
#
# Layout lives in tasks.json, not in per-feature functions: every branch-scoped
# location is passed in as a path template (see _vsc.dir.resolve).

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

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

# Expand a leading '@VAR' / '@VAR/sub/path' reference against the environment.
# Anything else is echoed unchanged. Idempotent, and only ever applied at the
# public function boundary — the _vsc.* helpers below take plain paths.
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

# ---------------------------------------------------------------------------
# Opening files
# ---------------------------------------------------------------------------

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

# Open an existing path in the editor. A file longer than <line_threshold>
# lines is opened in a new window instead of the current one.
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

# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

function _vsc.git.branch() {
  local proj_dir="$1"

  [[ -z "$proj_dir" ]] && {
    echo "Error: project directory is required." >&2
    return 1
  }
  [[ -d "$proj_dir" ]] || {
    echo "Error: project directory does not exist: $proj_dir" >&2
    return 1
  }

  local branch
  branch=$(git -C "$proj_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [[ -z "$branch" ]] && {
    echo "Error: not a git repository, or no branch checked out: $proj_dir" >&2
    return 1
  }

  echo "$branch"
}

# 'feat/foo' -> 'feat-foo', so a branch name is usable as one path component.
function _vsc.safe.branch() {
  local branch="$1"
  echo "${branch//\//-}"
}

# ---------------------------------------------------------------------------
# Path templates
#
# The single place where a branch-scoped location is computed. Callers pass a
# template so the directory layout is declared in tasks.json instead of being
# hard-coded once per feature. Supported placeholders:
#
#   {proj}      the project directory (argument 1, already @VAR-expanded)
#   {basename}  basename of {proj}
#   {branch}    current branch, '/' replaced by '-'
#
# A template without {branch} never shells out to git, so plain paths work
# outside a repository. Progress messages go to stderr; stdout is the result.
# ---------------------------------------------------------------------------

function _vsc.dir.resolve() {
  local proj_dir="$1"
  local template="$2"
  local mkdir_flag="${3:-}"

  [[ -z "$template" ]] && {
    echo "Error: path template is required." >&2
    return 1
  }

  local resolved="$template"

  if [[ "$resolved" == *'{proj}'* || "$resolved" == *'{basename}'* || "$resolved" == *'{branch}'* ]]; then
    [[ -z "$proj_dir" ]] && {
      echo "Error: project directory is required to resolve template: $template" >&2
      return 1
    }
    [[ -d "$proj_dir" ]] || {
      echo "Error: project directory does not exist: $proj_dir" >&2
      return 1
    }
  fi

  resolved="${resolved//\{proj\}/$proj_dir}"

  if [[ "$resolved" == *'{basename}'* ]]; then
    resolved="${resolved//\{basename\}/$(basename "$proj_dir")}"
  fi

  if [[ "$resolved" == *'{branch}'* ]]; then
    local branch safe_branch
    branch="$(_vsc.git.branch "$proj_dir")" || return 1
    safe_branch="$(_vsc.safe.branch "$branch")"
    echo "Branch: $branch -> $safe_branch" >&2
    resolved="${resolved//\{branch\}/$safe_branch}"
  fi

  if [[ "$resolved" =~ \{[a-z]+\} ]]; then
    echo "Error: unknown placeholder in template: $template" >&2
    echo "Hint: supported placeholders are {proj}, {basename}, {branch}." >&2
    return 1
  fi

  if [[ "$mkdir_flag" == "--mkdir" && ! -d "$resolved" ]]; then
    echo "Creating directory: $resolved" >&2
    mkdir -p "$resolved" || return 1
  fi

  echo "$resolved"
}

# ---------------------------------------------------------------------------
# File helpers
# ---------------------------------------------------------------------------

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

# Normalize free text into a filename-safe slug.
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

# Print the most-recently-modified file matching <pattern> under a directory,
# searched recursively. Errors if the directory is missing or has no match.
function _vsc.latest.mtime() {
  local search_dir="$1"
  local pattern="${2:-*.md}"

  [[ -z "$search_dir" ]] && {
    echo "Error: search directory is required." >&2
    return 1
  }
  [[ -d "$search_dir" ]] || {
    echo "Error: directory does not exist: $search_dir" >&2
    return 1
  }

  local latest
  latest=$(find "$search_dir" -type f -name "$pattern" -printf '%T@\t%p\n' 2>/dev/null |
    sort -nr | head -n 1 | cut -f2-)

  [[ -z "$latest" ]] && {
    echo "Error: no file matching '$pattern' under: $search_dir" >&2
    return 1
  }

  echo "$latest"
}

# ---------------------------------------------------------------------------
# Sequence engine
#
# One numbering scheme parameterized by a name format containing '{n}' (the
# sequence number) and optionally '{topic}' (a slug). The same format drives
# matching and creation:
#
#   '{n}.md'                 <- 1.md, 2.md, ...
#   'iter-{n}-{topic}.md'    <- iter-1-cache-miss.md, iter-2-retry.md, ...
# ---------------------------------------------------------------------------

# Derive a find(1) -name glob from a name format.
function _vsc.seq.glob() {
  local name_format="$1"
  local glob="${name_format//\{n\}/[0-9]*}"
  glob="${glob//\{topic\}/*}"
  echo "$glob"
}

# Echo the sequence number encoded in a file name, or fail when it does not
# match the format. '{n}' must be a run of digits; '{topic}' matches anything.
function _vsc.seq.num() {
  local name_format="$1"
  local file_name="$2"

  local prefix="${name_format%%\{n\}*}"
  local suffix="${name_format#*\{n\}}"

  [[ "$file_name" == "$prefix"* ]] || return 1
  local rest="${file_name#"$prefix"}"

  local digits="${rest%%[!0-9]*}"
  [[ -n "$digits" ]] || return 1

  local tail="${rest#"$digits"}"
  local suffix_glob="${suffix//\{topic\}/*}"
  # shellcheck disable=SC2053 # right-hand side is an intentional glob
  [[ "$tail" == $suffix_glob ]] || return 1

  echo "$((10#$digits))"
}

# Substitute {n} / {topic} into a name or header format.
function _vsc.seq.render() {
  local template="$1"
  local num="$2"
  local topic="$3"

  local rendered="${template//\{n\}/$num}"
  rendered="${rendered//\{topic\}/$topic}"
  echo "$rendered"
}

# Scan the direct children of <dir> for files matching <name_format>.
# Echoes a TAB-separated "<highest_num>\t<match_count>\t<highest_path>";
# a directory with no match yields "0\t0\t".
function _vsc.seq.scan() {
  local dir="$1"
  local name_format="$2"

  [[ "$name_format" == *'{n}'* ]] || {
    echo "Error: name format must contain '{n}': $name_format" >&2
    return 1
  }

  local glob
  glob="$(_vsc.seq.glob "$name_format")"

  local best_num=0
  local best_path=""
  local count=0
  local file_path file_name num
  while IFS= read -r file_path; do
    file_name="$(basename "$file_path")"
    num="$(_vsc.seq.num "$name_format" "$file_name")" || continue
    count=$((count + 1))
    if ((num > best_num)); then
      best_num="$num"
      best_path="$file_path"
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name "$glob" 2>/dev/null | sort)

  printf '%s\t%s\t%s\n' "$best_num" "$count" "$best_path"
}

# Shared argument parsing for vsc.open.seq / vsc.new.seq. Echoes a
# TAB-separated "<dir>\t<name_format>\t<header_format>\t<topic>".
function _vsc.seq.args() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local dir_template
  dir_template="$(vsc.expand.var "$2")" || return 1

  local name_format="${3:-}"
  [[ -z "$name_format" ]] && name_format='{n}.md'
  local header_format="${4:-}"

  local topic
  topic="$(_vsc.open.slug "${5:-}")" || return 1

  local dir
  dir="$(_vsc.dir.resolve "$proj_dir" "$dir_template" --mkdir)" || return 1

  printf '%s\t%s\t%s\t%s\n' "$dir" "$name_format" "$header_format" "$topic"
}

function _vsc.seq.usage() {
  local fn_name="$1"
  echo "Usage: $fn_name <proj_dir> <dir_template> [name_format] [header_format] [topic]" >&2
  echo "  dir_template   e.g. '{proj}/.ai_dev_talk/{branch}'" >&2
  echo "  name_format    default '{n}.md'; may use {n} and {topic}" >&2
  echo "  header_format  default none; may use {n} and {topic}" >&2
}

# ---------------------------------------------------------------------------
# Public entry points (called by name from tasks.json)
# ---------------------------------------------------------------------------

# Open one fixed file described by a path template, creating it and its parent
# directories when missing.
#   $1 project dir
#   $2 path template, e.g. '{proj}/note/{branch}/plan.md'
#   $3 optional line threshold above which a new window is used
function vsc.open.at() {
  [[ $# -ge 2 ]] && [[ -n "$2" ]] || {
    echo "Usage: vsc.open.at <proj_dir> <path_template> [line_threshold]" >&2
    return 1
  }

  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local path_template
  path_template="$(vsc.expand.var "$2")" || return 1
  local line_threshold="${3:-}"

  local file_path
  file_path="$(_vsc.dir.resolve "$proj_dir" "$path_template")" || return 1

  _vsc.open.ensure.file "$file_path" || return 1
  vsc.open.vscode "$file_path" "$line_threshold"
}

# Open the highest-numbered file in a sequence directory, creating #1 when the
# directory holds no match yet.
function vsc.open.seq() {
  [[ $# -ge 2 ]] && [[ -n "$2" ]] || {
    _vsc.seq.usage "vsc.open.seq"
    return 1
  }

  local parsed dir name_format header_format topic
  parsed="$(_vsc.seq.args "$@")" || return 1
  IFS=$'\t' read -r dir name_format header_format topic <<<"$parsed"

  local scan best_num count best_path
  scan="$(_vsc.seq.scan "$dir" "$name_format")" || return 1
  IFS=$'\t' read -r best_num count best_path <<<"$scan"

  if ((count > 0)); then
    echo "Sequence dir: $dir"
    echo "Latest of $count file(s) matching '$name_format': #$best_num $(basename "$best_path")"
    vsc.open.vscode "$best_path"
    return
  fi

  local file_name header=""
  file_name="$(_vsc.seq.render "$name_format" 1 "$topic")"
  [[ -n "$header_format" ]] && header="$(_vsc.seq.render "$header_format" 1 "$topic")"

  echo "Sequence dir: $dir"
  echo "No file matching '$name_format' yet, starting the sequence at #1."
  _vsc.open.ensure.file "$dir/$file_name" "$header" || return 1
  vsc.open.vscode "$dir/$file_name"
}

# Create and open the next file in a sequence directory.
function vsc.new.seq() {
  [[ $# -ge 2 ]] && [[ -n "$2" ]] || {
    _vsc.seq.usage "vsc.new.seq"
    return 1
  }

  local parsed dir name_format header_format topic
  parsed="$(_vsc.seq.args "$@")" || return 1
  IFS=$'\t' read -r dir name_format header_format topic <<<"$parsed"

  local scan best_num count best_path
  scan="$(_vsc.seq.scan "$dir" "$name_format")" || return 1
  IFS=$'\t' read -r best_num count best_path <<<"$scan"

  local next_num=$((best_num + 1))
  local file_name header=""
  file_name="$(_vsc.seq.render "$name_format" "$next_num" "$topic")"
  [[ -n "$header_format" ]] && header="$(_vsc.seq.render "$header_format" "$next_num" "$topic")"

  local target="$dir/$file_name"
  [[ -e "$target" ]] && {
    echo "Error: refusing to overwrite existing file: $target" >&2
    return 1
  }

  echo "Sequence dir: $dir"
  if ((count > 0)); then
    echo "Previous: #$best_num $(basename "$best_path") ($count file(s) matching '$name_format')"
  else
    echo "No file matching '$name_format' yet, starting the sequence at #$next_num."
  fi
  echo "Creating: #$next_num $file_name"

  _vsc.open.ensure.file "$target" "$header" || return 1
  vsc.open.vscode "$target"
}

# Open the most recently modified file under a directory, searched
# recursively. Never creates anything — this is a "where did I just work"
# shortcut, as opposed to the sequence openers above.
#   $1 project dir
#   $2 dir template, e.g. '{proj}/.ai_dev/{branch}'
#   $3 optional name pattern, default '*.md'
function vsc.open.latest() {
  [[ $# -ge 2 ]] && [[ -n "$2" ]] || {
    echo "Usage: vsc.open.latest <proj_dir> <dir_template> [name_pattern]" >&2
    return 1
  }

  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local dir_template
  dir_template="$(vsc.expand.var "$2")" || return 1
  local pattern="${3:-}"
  [[ -z "$pattern" ]] && pattern='*.md'

  local dir
  dir="$(_vsc.dir.resolve "$proj_dir" "$dir_template")" || return 1

  local latest
  latest="$(_vsc.latest.mtime "$dir" "$pattern")" || return 1

  echo "Search dir: $dir"
  echo "Most recently modified '$pattern': ${latest#"$dir"/}"
  vsc.open.vscode "$latest"
}

# Create the plan/truth/progress trio in a branch-scoped directory.
#   $1 project dir   $2 dir template
function vsc.touch.pptt() {
  [[ $# -ge 2 ]] && [[ -n "$2" ]] || {
    echo "Usage: vsc.touch.pptt <proj_dir> <dir_template>" >&2
    return 1
  }

  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local dir_template
  dir_template="$(vsc.expand.var "$2")" || return 1

  local target
  target="$(_vsc.dir.resolve "$proj_dir" "$dir_template" --mkdir)" || return 1

  local files=("plan.md" "truth.md" "progress.md")
  local headers=("# plan" "# truth" "# progress")
  local created=0
  local skipped=0
  local i
  for i in "${!files[@]}"; do
    local fpath="$target/${files[$i]}"
    if [[ -f "$fpath" ]]; then
      echo "  skipped: ${files[$i]} (already exists)"
      skipped=$((skipped + 1))
    else
      printf '%s\n' "${headers[$i]}" >"$fpath"
      echo "  created: ${files[$i]}"
      created=$((created + 1))
    fi
  done

  echo ""
  echo "Dir:     $target"
  echo "Created: $created, Skipped: $skipped (already existed)"
}

function vsc.get.branch() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  local branch
  branch="$(_vsc.git.branch "$proj_dir")" || return 1
  echo "$branch" | vsc.osc.copy
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
  diff_commit_hash=$(git -C "$proj_dir" merge-base "origin/$master_branch" HEAD 2>/dev/null)
  [[ -z "$diff_commit_hash" ]] && {
    echo "Error: could not compute merge-base." >&2
    return 1
  }

  echo "$diff_commit_hash" | vsc.osc.copy
}
