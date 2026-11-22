#!/bin/bash

# @desc: 在预设搜索目录中模糊查找文件或目录并输出路径
# @usage: ab.fs.search [query...]
# @alias: fs
function ab.fs.search {
  local fd_command="fd"
  if command -v "fdfind" &>/dev/null; then
    fd_command="fdfind"
  fi

  if ! command -v "${fd_command}" &>/dev/null; then
    printf "error: '%s' is not installed or not in PATH.\n" "${fd_command}" >&2
    return 1
  fi

  local fs_search_dirs=()
  local dir
  for dir in "${FS_SEARCH_DIRS[@]}"; do
    dir=$(bash -c "echo ${dir}")
    if [[ -d "${dir}" ]]; then
      fs_search_dirs+=("${dir}")
    else
      printf "warning: search dir '%s' does not exist, skipped.\n" "${dir}" >&2
    fi
  done
  if [[ ${#fs_search_dirs[@]} -eq 0 ]]; then
    printf "error: no valid search directory found.\n" >&2
    return 1
  fi

  local fs_search_ignore_dirs=("${FS_SEARCH_IGNORE_DIRS[@]}")
  local fs_search_preview="${FS_SEARCH_PREVIEW}"

  local exclude_args=()
  for dir in "${fs_search_ignore_dirs[@]}"; do
    dir=$(bash -c "echo ${dir}")
    exclude_args+=("--exclude" "${dir}")
  done

  local preview_command=""
  if [[ "${fs_search_preview}" == "true" ]]; then
    preview_command="printf 'Name: \033[1;32m %s \033[0m\n' {}; if [[ -d {} ]]; then printf 'Type: \033[1;32m %s \033[0m\n' 'Dir'; tree -L 2 {}; else printf 'Type: \033[1;32m %s \033[0m\n' 'File'; head -n 50 {} | cat; fi"
  else
    preview_command="echo {};if [[ -d {} ]]; then ls -al {}; else head -n 50 {}; fi"
  fi

  local target_file
  target_file=$(
    printf "%s\n" "${fs_search_dirs[@]}" |
      xargs -I {} "${fd_command}" --hidden --no-ignore "${exclude_args[@]}" --search-path {} |
      fzf --query="$1$2$3" --ansi --preview-window 'right:40%:wrap' --preview "${preview_command}"
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

# @desc: 在预设搜索目录中模糊查找并 cd 跳转到目标目录
# @usage: ab.fs.jump [query...]
# @alias: fj
function ab.fs.jump {
  local target_file
  target_file="$(ab.fs.search "$1" "$2" "$3")"
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

# @desc: 在预设搜索目录中模糊查找文件并用编辑器打开
# @usage: ab.fs.edit [query...]
# @alias: fe
function ab.fs.edit {
  local target_file
  target_file="$(ab.fs.search "$1" "$2" "$3")"
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
