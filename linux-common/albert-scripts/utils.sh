#!/bin/bash

###################################################
# description: make output colorful
#          $1: input content
#      return: nothing
###################################################
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_WHITE="\033[97m"
COLOR_GRAY="\033[90m"
COLOR_RESET="\033[0m"
BACKGROUND_YELLOW="\033[43m"
BACKGROUND_RED="\033[41m"
BACKGROUND_GREEN="\033[42m"
COLOR_BLACK="\033[1;30m"

print_red_line() { printf "${COLOR_RED}%s${COLOR_RESET}\n" "$1"; }
print_green_line() { printf "${COLOR_GREEN}%s${COLOR_RESET}\n" "$1"; }
print_yellow_line() { printf "${COLOR_YELLOW}%s${COLOR_RESET}\n" "$1"; }
print_blue_line() { printf "${COLOR_BLUE}%s${COLOR_RESET}\n" "$1"; }
print_magenta_line() { printf "${COLOR_MAGENTA}%s${COLOR_RESET}\n" "$1"; }
print_cyan_line() { printf "${COLOR_CYAN}%s${COLOR_RESET}\n" "$1"; }
print_gray_line() { printf "${COLOR_WHITE}%s${COLOR_RESET}\n" "$1"; }
print_white_line() { printf "${COLOR_WHITE}%s${COLOR_RESET}\n" "$1"; }

print_red() { printf "${COLOR_RED}%s${COLOR_RESET} " "$1"; }
print_green() { printf "${COLOR_GREEN}%s${COLOR_RESET} " "$1"; }
print_yellow() { printf "${COLOR_YELLOW}%s${COLOR_RESET} " "$1"; }
print_blue() { printf "${COLOR_BLUE}%s${COLOR_RESET} " "$1"; }
print_magenta() { printf "${COLOR_MAGENTA}%s${COLOR_RESET} " "$1"; }
print_cyan() { printf "${COLOR_CYAN}%s${COLOR_RESET} " "$1"; }
print_gray() { printf "${COLOR_WHITE}%s${COLOR_RESET} " "$1"; }
print_white() { printf "${COLOR_WHITE}%s${COLOR_RESET} " "$1"; }

print_warning_line() { printf "${BACKGROUND_YELLOW}${COLOR_BLACK}%s${COLOR_RESET}\n" "$1"; }
print_error_line() { printf "${BACKGROUND_RED}${COLOR_BLACK}%s${COLOR_RESET}\n" "$1"; }
print_info_line() { printf "${BACKGROUND_GREEN}${COLOR_BLACK}%s${COLOR_RESET}\n" "$1"; }

print_warning() { printf "${BACKGROUND_YELLOW}${COLOR_BLACK}%s${COLOR_RESET}" "$1"; }
print_error() { printf "${BACKGROUND_RED}${COLOR_BLACK}%s${COLOR_RESET}" "$1"; }
print_info() { printf "${BACKGROUND_GREEN}${COLOR_BLACK}%s${COLOR_RESET}" "$1"; }

###################################################
# description: give colorful yn_prompt
#          $1: custom prompt to print
#      return: 0: yes | 1: no
###################################################
function yn_prompt {
  local yn_input=""
  while true; do
    printf "$1 ${COLOR_CYAN}[y/n]: ${COLOR_RESET}"
    read yn_input
    case "${yn_input}" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *) print_red_line "Please answer yes[y] or no[n]." ;;
    esac
  done
}

###################################################
# description: print step information
#          $1: current step description
#      return: nothing
###################################################
function print_step {
  local current_step=$1
  print_green_line "========================================="
  print_green_line "================= STEP ${current_step} ================"
  print_green_line "========================================="
}

###################################################
# description: get git root path
#      return: git root path
###################################################
function get_gitroot {
  local git_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "${git_root}" ]]; then
    print_error_line "Error: git root not found, please run this script in your lso git repo."
    return 1
  fi

  echo "${git_root}"
  return 0
}
