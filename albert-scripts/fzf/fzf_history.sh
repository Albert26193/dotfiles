#!/bin/bash

###################################################
# description: fuzzy history search
#       input: none
#      return: matched command in history
###################################################
function ab.fs.history {
    # use fc -ln to get history, -n removes line numbers
    # awk dedup: keep only the first occurrence (i.e., the latest)
    local selected_command=$(
        fc -ln 1 |
        awk '!seen[$0]++' |
        fzf --tac --height 40% --reverse
    )

    # if user did not select anything, return directly
    [[ -z "${selected_command}" ]] && return 1

    printf "%s" "you have selected: "
    ab.fs.print_info_line "${selected_command}"

    if ab.fs.yn_prompt "sure to execute the command?"; then
        # add to zsh history, then execute
        print -s "${selected_command}"
        eval "${selected_command}"
    else
        printf "${FS_COLOR_YELLOW}%s${FS_COLOR_RESET}\n" "NOT execute the command"
    fi
}

###################################################
# description: fuzzy history search (direct execute for keybind)
#       input: none
#      return: matched command in history
###################################################
function ab.fs.history.exec {
    local selected_command=$(
        fc -ln 1 |
        awk '!seen[$0]++' |
        fzf --tac --height 40% --reverse
    )

    [[ -z "${selected_command}" ]] && return 1

    # add to history and execute
    print -s "${selected_command}"
    eval "${selected_command}"
}

###################################################
# description: source execute files
#       input: none
#      return: 0: success | 1: fail
###################################################
function ab.fs.pre_source {
    # source utils.sh
    local fs_root="${HOME}/.fuzzy_shell"
    local util_file_path="${fs_root}/scripts/utils.sh"

    if [[ ! -f "${util_file_path}" ]]; then
        printf "%s\n" "${util_file_path} do not exist. Install fuzzy-shell first."
        printf "%s\n" "Exit Now..."
        return 1
    else
        source "${util_file_path}"
    fi
    return 0
}

###################################################
# description: give colorful yn_prompt
#          $1: custom prompt to print
#      return: 0: yes | 1: no
###################################################
function ab.fs.yn_prompt {
    local fs_color_cyan="\033[36m"
    local fs_color_reset="\033[0m"
    local yn_input=""
    while true; do
        printf "$1 ${fs_color_cyan}[y/n]: ${fs_color_reset}"
        read yn_input
        case "${yn_input}" in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) print_red_line "Please answer yes[y] or no[n]." ;;
        esac
    done
}

###################################################
# description: print information
#          $1: information to print
#      return: 0: yes
###################################################
function ab.fs.print_info_line {
    local fs_background_green="\033[42m"
    local fs_color_black="\033[1;30m"
    local fs_color_reset="\033[0m"
    printf "${fs_background_green}${fs_color_black}%s${fs_color_reset}\n" "$1"
    return 0
}
