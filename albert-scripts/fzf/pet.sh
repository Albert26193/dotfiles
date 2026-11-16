#!/bin/bash

###################################################
# description: pet snippet selector - pick a snippet and put it on the prompt
#       input: $1: pet subcommand (new/edit/list/exec/clip/sync/configure) | otherwise query prefix
#        echo: selected command (non-zsh only, zsh pushes it to the prompt)
#      return: 0: success | 1: fail or aborted
###################################################
function ab.pet {
    # pre-flight checks
    if ! command -v "pet" &>/dev/null; then
        printf "error: 'pet' is not installed or not in PATH.\n" >&2
        return 1
    fi

    # forward pet subcommands as is
    case "${1:-}" in
    new | edit | list | exec | clip | sync | configure | version | help)
        pet "$@"
        return $?
        ;;
    esac

    # no subcommand: fuzzy select with the given prefix as initial query
    local selected_command=$(pet search --query "$*")

    if [[ -z "${selected_command}" ]]; then
        printf "exit snippet select ...\n" >&2
        return 1
    fi

    # zsh: push to the prompt buffer, edit or run it yourself
    # bash: no buffer stack, just print
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        print -z "${selected_command}"
    else
        printf "%s\n" "${selected_command}"
    fi

    return 0
}
