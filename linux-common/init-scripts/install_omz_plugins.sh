#!/bin/bash

UTILS_COLOR_GREEN="\033[32m"
UTILS_COLOR_YELLOW="\033[33m"
UTILS_COLOR_RESET="\033[0m"

utils_print_green_line() { printf "${UTILS_COLOR_GREEN}%s${UTILS_COLOR_RESET}\n" "$1"; }
utils_print_yellow_line() { printf "${UTILS_COLOR_YELLOW}%s${UTILS_COLOR_RESET}\n" "$1"; }

# check and install oh-my-zsh
function check_install_oh_my_zsh {
  local oh_my_zsh_target_dir="${HOME}/.oh-my-zsh"
  if [ -d "${oh_my_zsh_target_dir}" ]; then
    utils_print_green_line "oh-my-zsh is already installed."
  else
    utils_print_yellow_line "oh-my-zsh is not installed. Installing..."
    bash -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null
  fi

  return 0
}

# check and install oh-my-zsh-plugins
function check_install_oh_my_zsh_plugins {
  local oh_my_zsh_dir="${HOME}/.oh-my-zsh"
  local oh_my_zsh_plugins_dir="${HOME}/.oh-my-zsh/custom/plugins"
  if [[ ! -d "${oh_my_zsh_dir}" ]]; then
    utils_print_yellow_line "oh-my-zsh plugins directory has broken, exit now..."
    return 1
  fi

  plugin_names=(
    "zsh-syntax-highlighting"
    "zsh-vi-mode"
    "zsh-autosuggestions"
  )
  plugin_urls=(
    "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    "https://github.com/jeffreytse/zsh-vi-mode.git"
    "https://github.com/zsh-users/zsh-autosuggestions.git"
  )

  for i in $(seq 0 $((${#plugin_names[@]} - 1))); do
    plugin="${plugin_names[$i]}"
    url="${plugin_urls[$i]}"
    if [[ ! -d "${oh_my_zsh_plugins_dir}/${plugin}" ]]; then
      utils_print_yellow_line "${plugin} is not installed. Installing..."
      git clone "${url}" "${oh_my_zsh_plugins_dir}/${plugin}"
    else
      printf "%s" "${plugin} "
      utils_print_green_line "is already installed."
    fi
  done

  return 0
}

{ command -v zsh >/dev/null; } || {
  echo "has not zsh installed"
  exit 1
} &&
  check_install_oh_my_zsh &&
  check_install_oh_my_zsh_plugins
