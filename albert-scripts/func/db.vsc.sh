#!/bin/bash

# Database-project VSCode helpers. Depends on common.vsc.sh.

function vsc.mtr.pair() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1
  local current_file
  current_file="$(vsc.expand.var "$2")" || return 1

  [[ -z "$proj_dir" ]] && {
    echo "Error: project directory is required." >&2
    return 1
  }
  [[ -z "$current_file" ]] && {
    echo "Error: current file path is required." >&2
    return 1
  }
  [[ -d "$proj_dir" ]] || {
    echo "Error: project directory does not exist: $proj_dir" >&2
    return 1
  }
  [[ -f "$current_file" ]] || {
    echo "Error: current file does not exist: $current_file" >&2
    return 1
  }

  local proj_real
  proj_real="$(readlink -f "$proj_dir" 2>/dev/null)" || return 1
  local current_real
  current_real="$(readlink -f "$current_file" 2>/dev/null)" || return 1
  local mysql_test_dir="$proj_real/mysql-test"

  [[ "$current_real" == "$mysql_test_dir/"* ]] || {
    echo "Error: current file is not under mysql-test: $current_file" >&2
    return 1
  }

  local rel_path="${current_real#"$mysql_test_dir/"}"
  local pair_rel
  if [[ "$rel_path" == t/*.test ]]; then
    pair_rel="r/${rel_path#t/}"
    pair_rel="${pair_rel%.test}.result"
  elif [[ "$rel_path" == */t/*.test ]]; then
    pair_rel="${rel_path/\/t\//\/r\/}"
    pair_rel="${pair_rel%.test}.result"
  elif [[ "$rel_path" == r/*.result ]]; then
    pair_rel="t/${rel_path#r/}"
    pair_rel="${pair_rel%.result}.test"
  elif [[ "$rel_path" == */r/*.result ]]; then
    pair_rel="${rel_path/\/r\//\/t\/}"
    pair_rel="${pair_rel%.result}.test"
  else
    echo "Error: current file is not an MTR .test/.result pair: $current_file" >&2
    return 1
  fi

  local pair_path="$mysql_test_dir/$pair_rel"
  [[ -f "$pair_path" ]] || {
    echo "Error: paired MTR file does not exist: $pair_path" >&2
    return 1
  }

  vsc.open.vscode "$pair_path"
}

function vsc.view.mtrlog() {
  [[ -z "$1" ]] && {
    echo "Error: log directory is required." >&2
    echo "Usage: vsc.view.mtrlog <log_dir> [glob_pattern]" >&2
    return 1
  }

  local log_dir
  log_dir="$(vsc.expand.var "$1")" || return 1

  [[ -d "$log_dir" ]] || {
    echo "Error: log directory does not exist: $log_dir" >&2
    return 1
  }

  local glob_pat="${2:-*.mtr.*.log}"
  local last_log_file
  last_log_file=$(ls -t "$log_dir"/$glob_pat 2>/dev/null | head -n 1)

  [[ -z "$last_log_file" ]] && {
    echo "Error: no '$glob_pat' files found in: $log_dir" >&2
    return 1
  }

  vsc.open.vscode "$last_log_file"
}

function _vsc.ai.mtr.dir() {
  _vsc.dir.resolve "$1" '{proj}/.ai_dev/{branch}/mtr'
}

function _vsc.ai.mtr.latest_ts() {
  local mtr_dir="$1"
  [[ -d "$mtr_dir" ]] || {
    echo "Error: mtr directory does not exist: $mtr_dir" >&2
    return 1
  }

  if [[ -L "$mtr_dir/var" ]]; then
    local var_real
    var_real=$(readlink -f "$mtr_dir/var" 2>/dev/null)
    if [[ -n "$var_real" && -d "$var_real" ]]; then
      dirname "$var_real"
      return 0
    fi
  fi

  local ts
  ts=$(find "$mtr_dir" -mindepth 1 -maxdepth 1 -type d \
    -regextype posix-extended \
    -regex '.*/[0-9]{8}_[0-9]{2}_[0-9]{2}_[0-9]{2}$' 2>/dev/null |
    sort | tail -n 1)
  [[ -n "$ts" ]] && {
    echo "$ts"
    return 0
  }

  echo "Error: no run timestamp found under: $mtr_dir" >&2
  echo "Hint: run MTR at least once so .ai_dev/<branch>/mtr/<ts>/ exists." >&2
  return 1
}

function vsc.ai.mtr.txt() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  local mtr_dir
  mtr_dir="$(_vsc.ai.mtr.dir "$proj_dir")" || return 1

  local mtr_txt="$mtr_dir/mtr.txt"
  [[ -f "$mtr_txt" ]] || {
    echo "Error: mtr.txt does not exist: $mtr_txt" >&2
    echo "Hint: run mtr_write_cases.sh to create it." >&2
    return 1
  }

  vsc.open.vscode "$mtr_txt"
}

function vsc.ai.mtr.var() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  local mtr_dir
  mtr_dir="$(_vsc.ai.mtr.dir "$proj_dir")" || return 1

  local ts_dir
  ts_dir="$(_vsc.ai.mtr.latest_ts "$mtr_dir")" || return 1

  local err_file
  err_file=$(find "$ts_dir" -type f -name 'mysqld.1.1.err' 2>/dev/null | sort | head -n 1)

  [[ -z "$err_file" ]] && {
    echo "Error: no mysqld.1.1.err found under: $ts_dir" >&2
    return 1
  }

  vsc.open.vscode "$err_file" 80000
}

function vsc.ai.mtr.log() {
  local proj_dir
  proj_dir="$(vsc.expand.var "$1")" || return 1

  local mtr_dir
  mtr_dir="$(_vsc.ai.mtr.dir "$proj_dir")" || return 1

  local ts_dir
  ts_dir="$(_vsc.ai.mtr.latest_ts "$mtr_dir")" || return 1

  local run_log="$ts_dir/mtr_run.log"
  [[ -f "$run_log" ]] || {
    echo "Error: mtr_run.log does not exist: $run_log" >&2
    return 1
  }

  vsc.open.vscode "$run_log"
}
