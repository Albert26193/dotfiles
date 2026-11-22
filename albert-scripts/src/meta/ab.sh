#!/bin/bash

function _ab.ab.index {
  local src_root="$1"
  local files=() file
  while IFS= read -r file; do
    [[ -n "${file}" ]] && files+=("${file}")
  done < <(find "${src_root}" -type f -name '*.sh' | LC_ALL=C sort)
  [[ ${#files[@]} -eq 0 ]] && return 0

  awk -v root="${src_root}" '
    FNR == 1 {
      rel = substr(FILENAME, length(root) + 2)
      split(rel, p, "/"); cat = p[1]
      desc = usage = tags = ""
    }
    /^[ \t]*#[ \t]*@desc:/  { sub(/^[ \t]*#[ \t]*@desc:[ \t]*/,  ""); desc = $0; next }
    /^[ \t]*#[ \t]*@usage:/ { sub(/^[ \t]*#[ \t]*@usage:[ \t]*/, ""); usage = $0; next }
    /^[ \t]*#[ \t]*@tags:/  { sub(/^[ \t]*#[ \t]*@tags:[ \t]*/,  ""); tags = $0; next }
    /^[ \t]*#/              { next }
    /^function[ \t]+[a-zA-Z0-9._-]+[ \t]*\{/ {
      name = $2
      if (cat != "_utils" && name !~ /^_/ && name != "ab") {
        has_args = (index(usage, name " ") == 1) ? "1" : "0"
        tags_col = (tags != "" ? " \033[2m[" tags "]\033[0m" : "")
        display = sprintf("\033[36m%-22s\033[0m  \033[33m%-7s\033[0m %s%s",
          name, "[" cat "]", desc, tags_col)
        printf "%s\t%s\t%d\t%s\t%s\n", name, rel, FNR, has_args, display
      }
      desc = usage = tags = ""
      next
    }
    { desc = usage = tags = "" }
  ' "${files[@]}"
}

function _ab.ab.preview {
  local src_root="$1" rel_path="$2" target_line="$3" fn_name="$4"
  local full_path="${src_root}/${rel_path}"
  [[ -f "${full_path}" ]] || { printf 'File not found: %s\n' "${full_path}"; return 1; }

  local meta
  meta=$(awk -v target_line="${target_line}" -v fn_name="${fn_name}" '
    found { if ($0 == "}") { bend = NR; exit }; next }
    /^[ \t]*#/ && !/^#!/ {
      if (!cstart) cstart = NR
      if (/^[ \t]*#[ \t]*@desc:/)  { sub(/^[ \t]*#[ \t]*@desc:[ \t]*/,  ""); desc = $0 }
      if (/^[ \t]*#[ \t]*@usage:/) { sub(/^[ \t]*#[ \t]*@usage:[ \t]*/, ""); usage = $0 }
      if (/^[ \t]*#[ \t]*@tags:/)  { sub(/^[ \t]*#[ \t]*@tags:[ \t]*/,  ""); tags = $0 }
      next
    }
    /^function[ \t]+[a-zA-Z0-9._-]+[ \t]*\{/ && $2 == fn_name && (!target_line || NR == target_line) {
      bstart = (cstart ? cstart : NR); fline = NR; found = 1; next
    }
    { cstart = 0; desc = usage = tags = "" }
    END {
      if (!found) exit 1
      if (!bend) bend = NR
      printf "%d\t%d\t%d\t%s\t%s\t%s\n", bstart, fline, bend, desc, usage, tags
    }
  ' "${full_path}") || { printf 'Function not found: %s in %s\n' "${fn_name}" "${rel_path}"; return 1; }

  local bstart fline bend desc usage tags
  IFS=$'\t' read -r bstart fline bend desc usage tags <<<"${meta}"

  printf '\033[1;36m%s\033[0m  \033[33m[%s]\033[0m\n' "${fn_name}" "${rel_path%%/*}"
  [[ -n "${desc}" ]]  && printf '%s\n' "${desc}"
  [[ -n "${usage}" ]] && printf '\033[2musage:\033[0m %s\n' "${usage}"
  [[ -n "${tags}" ]]  && printf '\033[2mtags :\033[0m %s\n' "${tags}"
  printf '\033[2mfile : src/%s:%s\033[0m\n' "${rel_path}" "${fline}"
  printf '\033[2m────────────────────────────────────────────────────────\033[0m\n'

  local bat_cmd=""
  command -v bat &>/dev/null && bat_cmd="bat"
  [[ -z "${bat_cmd}" ]] && command -v batcat &>/dev/null && bat_cmd="batcat"

  if [[ -n "${bat_cmd}" ]]; then
    "${bat_cmd}" --color=always --style=numbers --language=bash \
      --line-range="${bstart}:${bend}" --highlight-line="${fline}" "${full_path}"
  else
    awk -v s="${bstart}" -v e="${bend}" 'NR >= s && NR <= e { printf "%4d │ %s\n", NR, $0 }' "${full_path}"
  fi
}

# @desc: fzf 检索 albert-scripts 全部命令（Enter 放命令行 / Ctrl-X 执行 / Ctrl-E 编辑源码）
# @usage: ab [query]
# @tags: picker search
function ab {
  command -v fzf &>/dev/null || { _ab.ui.red "error: 'fzf' is not installed or not in PATH."; return 1; }

  local src_root="${ALBERT_SCRIPTS_PATH:-${HOME}/.albert-scripts}/src"
  local self_file="${src_root}/meta/ab.sh"
  local selection

  selection=$(
    _ab.ab.index "${src_root}" |
      fzf --ansi --delimiter=$'\t' --with-nth=5 --query="$*" \
        --height=70% --layout=reverse --border --prompt="ab> " \
        --header="Enter: 放命令行 | Ctrl-X: 立即执行 | Ctrl-E: 编辑源码" \
        --expect=ctrl-e,ctrl-x --preview-window="right:50%:wrap" \
        --preview "bash -c 'source \"\$1\" && _ab.ab.preview \"\$2\" \"\$3\" \"\$4\" \"\$5\"' _ '${self_file}' '${src_root}' {2} {3} {1}"
  ) || return 0

  local key="${selection%%$'\n'*}"
  local picked="${selection#*$'\n'}"
  [[ -z "${picked}" || "${picked}" == "${selection}" ]] && return 0

  local cmd rel_path line has_args _rest
  IFS=$'\t' read -r cmd rel_path line has_args _rest <<<"${picked}"
  [[ -z "${cmd}" ]] && return 0

  case "${key}" in
    ctrl-e) "${FS_EDITOR:-nvim}" "+${line}" "${src_root}/${rel_path}" ;;
    ctrl-x)
      [[ -n "${ZSH_VERSION:-}" ]] && print -s "${cmd}"
      eval "${cmd}"
      ;;
    *)
      local suffix=""
      [[ "${has_args}" == "1" ]] && suffix=" "
      if [[ -n "${ZSH_VERSION:-}" ]]; then
        print -z "${cmd}${suffix}"
      else
        printf '%s\n' "${cmd}"
      fi
      ;;
  esac
}

# @desc: 校验 albert-scripts 路由命名、函数写法、元注释与零 alias 规范
# @tags: lint check
function ab.lint {
  local src_root="${ALBERT_SCRIPTS_PATH:-${HOME}/.albert-scripts}/src"
  local files=() file
  while IFS= read -r file; do
    [[ -n "${file}" ]] && files+=("${file}")
  done < <(find "${src_root}" -type f -name '*.sh' | LC_ALL=C sort)
  [[ ${#files[@]} -eq 0 ]] && { _ab.ui.red "ab.lint FAILED: no .sh files under ${src_root}"; return 1; }

  awk -v root="${src_root}" -v q="'" '
    FNR == 1 {
      rel = substr(FILENAME, length(root) + 2)
      split(rel, p, "/"); cat = p[1]; dom = p[2]; sub(/\.sh$/, "", dom)
      expected = (cat == "_utils" ? "_ab." : "ab." dom)
      desc = ""
    }
    /^[ \t]*alias[ \t]+/         { err[++ec] = rel ":" FNR ": alias is not allowed inside src/ (put in .zsh.alias)" }
    /^[ \t]*#[ \t]*@desc:/       { sub(/^[ \t]*#[ \t]*@desc:[ \t]*/, ""); desc = $0; next }
    /^[ \t]*#/                   { next }
    /^[a-zA-Z0-9._-]+[ \t]*\(\)/ { err[++ec] = rel ":" FNR ": non-canonical syntax " q $0 q " (use " q "function name {" q ")"; desc = ""; next }
    /^function[ \t]+[a-zA-Z0-9._-]+[ \t]*\{/ {
      name = $2; loc = rel ":" FNR; is_priv = (name ~ /^_/)
      if (name in seen) err[++ec] = loc ": duplicate function " q name q " (first seen at " seen[name] ")"
      else seen[name] = loc

      if (cat == "_utils") {
        priv++
        if (index(name, "_ab.") != 1) err[++ec] = loc ": _utils function " q name q " must start with " q "_ab." q
      } else if (rel == "meta/ab.sh") {
        if (is_priv) {
          priv++
          if (index(name, "_ab.ab.") != 1) err[++ec] = loc ": private " q name q " must start with " q "_ab.ab." q
        } else {
          pub++
          if (name != "ab" && name != "ab.lint") err[++ec] = loc ": meta/ab.sh may only export " q "ab" q " or " q "ab.lint" q
          if (desc == "") err[++ec] = loc ": public " q name q " is missing " q "# @desc:" q
        }
      } else if (is_priv) {
        priv++
        if (index(name, "_" expected ".") != 1) err[++ec] = loc ": private " q name q " violates route " q "_" expected ".*" q
      } else {
        pub++
        if (name != expected && index(name, expected ".") != 1) err[++ec] = loc ": public " q name q " violates route " q expected "[.*]" q
        if (desc == "") err[++ec] = loc ": public " q name q " is missing " q "# @desc:" q
      }
      desc = ""; next
    }
    { desc = "" }
    END {
      if (ec > 0) {
        printf "ab.lint FAILED (%d error(s)):\n", ec > "/dev/stderr"
        for (i = 1; i <= ec; i++) printf "  - %s\n", err[i] > "/dev/stderr"
        exit 1
      }
      printf "ab.lint OK: %d public, %d private, 0 violations.\n", pub, priv
    }
  ' "${files[@]}"
}
