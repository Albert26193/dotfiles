#!/bin/bash

# @desc: 在当前目录树下模糊查找文件或目录并输出路径
# @usage: ab.fs.current.search [query...]
function ab.fs.current.search {
  local fd_command="fd"
  if command -v "fdfind" &>/dev/null; then
    fd_command="fdfind"
  fi

  local preview_command=""
  if [[ "${FS_SEARCH_PREVIEW}" == "true" ]]; then
    preview_command="printf 'Name: \033[1;32m %s \033[0m\n' {}; if [[ -d {} ]]; then printf 'Type: \033[1;32m %s \033[0m\n' 'Dir'; tree -L 2 {}; else printf 'Type: \033[1;32m %s \033[0m\n' 'File'; head -n 50 {} | cat; fi"
  else
    preview_command="echo {};if [[ -d {} ]]; then ls -al {}; else head -n 50 {}; fi"
  fi

  local target_file
  target_file=$(
    "${fd_command}" --hidden --no-ignore . |
      fzf --query="$*" --ansi --preview-window 'right:40%:wrap' --preview "${preview_command}"
  )

  if [[ -z "${target_file}" ]]; then
    echo ""
    echo "exit fuzzy search ..." >&2
    return 1
  else
    echo "${target_file}"
  fi
  return 0
}

# @desc: 在当前目录树下模糊查找并 cd 跳转到目标目录
# @usage: ab.fs.current.jump [query...]
function ab.fs.current.jump {
  local target_file
  target_file="$(ab.fs.current.search "$@")"
  if [[ -d "${target_file}" ]]; then
    cd "${target_file}" && _ab.fs.show
  elif [[ -f "${target_file}" ]]; then
    local father_dir
    father_dir=$(dirname "${target_file}")
    cd "${father_dir}" && _ab.fs.show
  else
    return 1
  fi
  return 0
}

# @desc: 在当前目录树下模糊查找文件并用编辑器打开
# @usage: ab.fs.current.edit [query...]
function ab.fs.current.edit {
  local target_file
  target_file="$(ab.fs.current.search "$@")"
  if [[ -z "${target_file}" ]]; then
    return 1
  fi

  local editor="${FS_EDITOR}"
  if [[ -z "${editor}" ]]; then
    printf "%s" "env 'FS_EDITOR' is empty, please check it."
    return 1
  fi
  if ! command -v "${editor}" &>/dev/null; then
    printf "%s" "${editor} is NOT executable, please check it."
    return 1
  fi

  if [[ "${FS_EDIT_CD}" == "true" ]]; then
    local father_dir
    local base_name
    father_dir=$(dirname "${target_file}")
    base_name=$(basename "${target_file}")
    cd "${father_dir}" && "${editor}" "${base_name}"
  else
    "${editor}" "${target_file}"
  fi
  return $?
}
