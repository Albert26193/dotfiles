#!/bin/bash

_BREW_USER="linuxbrew"
_BREW_HOME="/home/${_BREW_USER}"
_BREW_BIN="${_BREW_HOME}/.linuxbrew/bin/brew"

_COLOR_GREEN="\033[32m"
_COLOR_YELLOW="\033[33m"
_COLOR_RED="\033[31m"
_COLOR_RESET="\033[0m"

_brew_green() { printf "${_COLOR_GREEN}%s${_COLOR_RESET}\n" "$1"; }
_brew_yellow() { printf "${_COLOR_YELLOW}%s${_COLOR_RESET}\n" "$1"; }
_brew_red() { printf "${_COLOR_RED}%s${_COLOR_RESET}\n" "$1" >&2; }

function ab.brew {
  local action="$1"
  shift
  local packages=("$@")

  # --- Parameter validation ----
  [[ -n $action ]] || {
    _brew_red 'Usage: ab.brew <action> [package ...]'
    return 1
  }

  # --- 1. Ensure the user exists ----
  if ! id "$_BREW_USER" &>/dev/null; then
    _brew_red "Error: user '${_BREW_USER}' does not exist. Run ab.install.brew first."
    return 2
  fi

  # --- 2. Ensure brew is installed ----
  if [[ ! -x $_BREW_BIN ]]; then
    _brew_red "Error: brew not found at '${_BREW_BIN}'. Run ab.install.brew first."
    return 3
  fi

  # --- 3. For install action, skip already-installed packages ----
  if [[ $action == "install" && ${#packages[@]} -gt 0 ]]; then
    local to_install=()
    for pkg in "${packages[@]}"; do
      if su - "$_BREW_USER" -c "eval \"\$(${_BREW_BIN} shellenv)\" && brew list ${pkg}" &>/dev/null; then
        _brew_green "${pkg} is already installed, skipping."
      else
        to_install+=("$pkg")
      fi
    done
    [[ ${#to_install[@]} -eq 0 ]] && {
      _brew_green "All packages already installed."
      return 0
    }
    packages=("${to_install[@]}")
  fi

  # --- 4. Run brew as the target user ----
  local cmd="eval \"\$(${_BREW_BIN} shellenv)\" && brew ${action} ${packages[*]}"
  _brew_yellow "Running: brew ${action} ${packages[*]}"
  su - "$_BREW_USER" -c "$cmd"
  local ret=$?

  if [[ $ret -eq 0 ]]; then
    _brew_green "brew ${action} completed successfully."
  else
    _brew_red "brew ${action} failed (exit code: ${ret})."
  fi
  return "$ret"
}

function ab.install.brew {
  # --- Early exit if brew is already installed ----
  if [[ -x "${_BREW_BIN}" ]]; then
    _brew_green "------------------------------"
    _brew_green "brew is already installed – exiting."
    _brew_green "------------------------------"
    return 0
  fi

  # --- Ensure the linuxbrew user exists ----
  if ! id "${_BREW_USER}" &>/dev/null; then
    _brew_yellow "Creating user '${_BREW_USER}' with home '${_BREW_HOME}'..."
    useradd \
      --create-home \
      --home-dir "${_BREW_HOME}" \
      --shell /bin/bash \
      --comment "Linuxbrew package manager" \
      --groups wheel \
      "${_BREW_USER}"
  else
    _brew_green "User '${_BREW_USER}' already exists."
  fi

  # --- Install Homebrew (non-interactive) ----
  _brew_yellow "Installing Homebrew for user '${_BREW_USER}'..."
  su - "${_BREW_USER}" -c 'NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

  # --- Verify installation ----
  if [[ -x "${_BREW_BIN}" ]]; then
    _brew_green "Homebrew installed successfully."
  else
    _brew_red "Homebrew installation failed – ${_BREW_BIN} not found."
    return 1
  fi
}

function ab.brew.link {
  local brew_bin_dir="${_BREW_HOME}/.linuxbrew/bin"
  local target_dir="${HOME}/.local/bin"
  local link_bins=(
    "lazygit" "neovim" "nvim"
    "tmux" "gdb" "cgdb"
    "delta" "ccls" "starship" "mycli"
    "rg" "fd" "fzf" "yazi"
    "git" "tailspin" "tmuxp"
  )

  # --- Ensure brew is installed ----
  if [[ ! -x $_BREW_BIN ]]; then
    _brew_red "Error: brew not found at '${_BREW_BIN}'. Run ab.install.brew first."
    return 1
  fi

  # --- Ensure target directory exists ----
  mkdir -p "${target_dir}"

  local linked=0
  local skipped=0

  for bin in "${link_bins[@]}"; do
    local src="${brew_bin_dir}/${bin}"
    local dst="${target_dir}/${bin}"

    if [[ ! -e "${src}" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    if [[ -L "${dst}" && "$(readlink -f "${dst}")" == "$(readlink -f "${src}")" ]]; then
      _brew_green "${bin} already linked."
      skipped=$((skipped + 1))
      continue
    fi

    ln -sf "${src}" "${dst}"
    _brew_yellow "${bin} -> ${dst}"
    linked=$((linked + 1))
  done

  _brew_green "Done: ${linked} linked, ${skipped} skipped."
}

function ab.brew.fix {
  brew cleanup

  cd $(brew --repository)
  git checkout -- .
  git reset --hard origin/master

  cd $(brew --repository homebrew/core)
  git checkout -- .
  git reset --hard origin/master

  brew update
  brew update
}

