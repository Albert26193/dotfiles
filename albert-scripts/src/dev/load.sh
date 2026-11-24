#!/bin/bash

function _ab.load.copy {
  local src_name="$1"
  local dst_rel="$2"
  local force="$3"

  local root="${ALBERT_SCRIPTS_PATH:-${HOME}/.albert-scripts}"
  local src="${root}/assets/${src_name}"
  local dst="${PWD}/${dst_rel}"

  if [[ ! -f "${src}" ]]; then
    echo "source not found: ${src}" >&2
    return 1
  fi

  if [[ -e "${dst}" && "${force}" != "1" ]]; then
    echo "target exists: ${dst}" >&2
    echo "pass -f / --force to overwrite" >&2
    return 1
  fi

  mkdir -p "$(dirname "${dst}")"
  cp "${src}" "${dst}"
  echo "wrote: ${dst}"
}

function _ab.load.force {
  case "$1" in
    -f | --force) return 0 ;;
    *) return 1 ;;
  esac
}

# @desc: 从模板写入 .vscode/tasks.json 到当前项目
# @usage: ab.load.vsc_task [-f|--force]
function ab.load.vsc_task {
  local force=0
  _ab.load.force "$1" && force=1
  _ab.load.copy "demo.vsc.json" ".vscode/tasks.json" "${force}"
}

# @desc: 从模板写入 .claude/settings.json 到当前项目
# @usage: ab.load.claude [-f|--force]
function ab.load.claude {
  local force=0
  _ab.load.force "$1" && force=1
  _ab.load.copy "demo.claude.json" ".claude/settings.json" "${force}"
}

# @desc: 向当前项目 .ignore 幂等追加反忽略规则（!note/、!.ai_dev 等）
function ab.load.ignore {
  local dst="${PWD}/.ignore"
  local rules=(
    '!note/'
    '!.ai_dev'
  )
  local rule

  for rule in "${rules[@]}"; do
    if [[ -f "${dst}" ]] && grep -qxF "${rule}" "${dst}"; then
      echo "exists: ${rule} in ${dst}"
      continue
    fi

    if [[ -s "${dst}" && -n "$(tail -c1 "${dst}")" ]]; then
      echo >>"${dst}"
    fi
    echo "${rule}" >>"${dst}"
    echo "wrote: ${rule} -> ${dst}"
  done
}
