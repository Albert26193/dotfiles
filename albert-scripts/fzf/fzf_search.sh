#!/bin/bash

###################################################
# description: fuzzy search
#       input: $1: search keyword 1
#       input: $2: search keyword 2
#       input: $3: search keyword 3
#        echo: matched file(search result)
#      return: 0: success | 1: fail
###################################################
function ab.fs.search {
    local fd_command="fd"

    # alias wont work, if fdfind exits , should use it
    if command -v "fdfind" &>/dev/null; then
        fd_command="fdfind"
    fi

    # pre-flight checks
    if ! command -v "${fd_command}" &>/dev/null; then
        printf "error: '%s' is not installed or not in PATH.\n" "${fd_command}" >&2
        return 1
    fi

    # load to local variable, filter out non-existent dirs
    local fs_search_dirs=()
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
    local fs_search_ignore_dirs=(${FS_SEARCH_IGNORE_DIRS[@]})
    local fs_search_preview=${FS_SEARCH_PREVIEW}
    local fs_editor=${FS_EDITOR}

    # exclude dirs
    local exclude_args=()
    for dir in "${fs_search_ignore_dirs[@]}"; do
        dir=$(bash -c "echo ${dir}")
        exclude_args+=("--exclude" ${dir})
    done

    local preview_command=""
    if [[ "${fs_search_preview}" == "true" ]]; then
        preview_command="printf 'Name: \033[1;32m %s \033[0m\n' {}; if [[ -d {} ]]; then printf 'Type: \033[1;32m %s \033[0m\n' 'Dir'; tree -L 2 {}; else printf 'Type: \033[1;32m %s \033[0m\n' 'File'; head -n 50 {} | cat; fi"
    else
        preview_command="echo {};if [[ -d {} ]]; then ls -al {}; else head -n 50 {}; fi"
    fi

    local target_file=$(
        printf "%s\n" "${fs_search_dirs[@]}" |
            xargs -I {} ${fd_command} --hidden --no-ignore ${exclude_args[@]} --search-path {} |
            fzf --query="$1$2$3" --ansi --preview-window 'right:40%:wrap' --preview "$preview_command"
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

###################################################
# description: jump to dir by fuzzy search result
#       input: $1: search keyword 1
#       input: $2: search keyword 2
#       input: $3: search keyword 3
#      return: 0: success | 1: fail
###################################################
function ab.fs.jump {
    local target_file="$(ab.fs.search $1 $2 $3)"
    if [[ -d "${target_file}" ]]; then
        cd "${target_file}" && ab.fs.show
    elif [[ -f "${target_file}" ]]; then
        local father_dir=$(dirname "${target_file}")
        cd "${father_dir}" && ab.fs.show
    else
        return 1
    fi
    return 0
}

###################################################
# description: edit file by fuzzy search result
#       input: $1: search keyword 1
#       input: $2: search keyword 2
#       input: $3: search keyword 3
#      return: 0: success | 1: fail
###################################################
function ab.fs.edit {
    local target_file="$(ab.fs.search $1 $2 $3)"

    if [[ -z "${target_file}" ]]; then
        return 1
    fi

    local editor=${FS_EDITOR}
    if [[ -z "${editor}" ]]; then
        printf "%s" "env 'FS_EDITOR' is empty, please check it."
        return 1
    fi
    if ! command -v ${editor} &>/dev/null; then
        printf "%s" "${editor} is NOT executable, please check it."
        return 1
    fi

    if [[ "${FS_EDIT_CD}" == "true" ]]; then
        local father_dir=$(dirname "${target_file}")
        local base_name=$(basename "${target_file}")
        cd "${father_dir}" && ${editor} "${base_name}"
    else
        ${editor} "${target_file}"
    fi

    return $?
}

###################################################
# description: show files in current directory
#       input: none
#      return: 0: success | 1: fail
###################################################
function ab.fs.show {
    local currentPath=$(pwd)
    local normalFileNum=$(ls -al | tail -n +4 | grep "^-" | wc -l | tr -d ' ')
    local dirFileNum=$(ls -al | tail -n +4 | grep "^d" | wc -l | tr -d ' ')
    local totalNum=$((${normalFileNum} + ${dirFileNum}))

    printf "\033[1;30m\033[44mjump to: \033[1;30m\033[42m%s\033[0m\n" "${currentPath}"
    printf "\033[1;30m\033[44mfile count: \033[1;30m\033[42m%s\033[0m\n" "${totalNum}"
    printf "\n"

    if [[ ${totalNum} -le 35 ]]; then
        ls -al --color=always | tail -n +2
    elif [[ ${totalNum} -ge 101 ]]; then
        echo "files in current directory is more than 100"
    else
        ls -a
    fi
    return 0
}
