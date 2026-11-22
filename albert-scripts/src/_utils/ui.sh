#!/bin/bash

function _ab.ui.green {
  printf '\033[32m%s\033[0m\n' "$1"
}

function _ab.ui.yellow {
  printf '\033[33m%s\033[0m\n' "$1"
}

function _ab.ui.red {
  printf '\033[31m%s\033[0m\n' "$1" >&2
}

function _ab.ui.info {
  printf '\033[42m\033[1;30m%s\033[0m\n' "$1"
}

function _ab.ui.warn {
  printf '\033[43m\033[1;30m%s\033[0m\n' "$1"
}

function _ab.ui.error {
  printf '\033[41m\033[1;30m%s\033[0m\n' "$1" >&2
}

function _ab.ui.yn {
  local prompt="$1"
  local yn_input=""
  while true; do
    printf '%s \033[36m[y/n]: \033[0m' "${prompt}"
    read -r yn_input
    case "${yn_input}" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) _ab.ui.red "Please answer yes[y] or no[n]." ;;
    esac
  done
}
