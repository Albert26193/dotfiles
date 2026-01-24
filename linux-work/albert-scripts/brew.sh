#!/bin/bash

function ab.brew {
  local brew_user="linuxbrew"          # Target user that owns brew
  local brew_home="/home/${brew_user}" # Target home directory
  local action="$1"                    # brew action (install, upgrade, …)
  local package="$2"                   # package name

  # --- Parameter validation ----
  [[ -n $action && -n $package ]] || {
    printf 'Usage: ab.brew <action> <package>\n' >&2
    return 1
  }

  # --- 1. Ensure the user exists ----
  if ! id "$brew_user" &>/dev/null; then
    printf 'Error: user "%s" does not exist.\n' "$brew_user" >&2
    return 2
  fi

  # --- 2. Ensure the home directory exists ----
  if [[ ! -d $brew_home ]]; then
    printf 'Error: home directory "%s" not found.\n' "$brew_home" >&2
    return 3
  fi

  # --- 3. Run brew as the target user ----
  cd "$brew_home" || return
  su "$brew_user" \
    -c "env PATH=$brew_home/.linuxbrew/bin:$PATH brew $action $package"
  local ret=$?
  cd - >/dev/null || true
  return "$ret"
}

function ab.install.brew {
  local brew_user="linuxbrew"
  local brew_home="/home/${brew_user}"

  # --- Early exit if brew is already installed -----------------------------
  if [[ -d "${brew_home}/.linuxbrew" ]]; then
    printf -- "------------------------------\n"
    printf "brew is already installed – exiting.\n"
    printf -- "------------------------------\n"
    return 0
  fi

  # --- Ensure the linuxbrew user exists -------------------------------------
  if ! id "${brew_user}" &>/dev/null; then
    printf "Creating user '%s' with home '%s'...\n" "${brew_user}" "${brew_home}"

    # Create the user with its own home directory and bash shell
    useradd \
      --create-home \
      --home-dir "${brew_home}" \
      --shell /bin/bash \
      --comment "Linuxbrew package manager" \
      --groups wheel \
      "${brew_user}"
  fi

  # --- Install Homebrew (non-interactive) ------------------------------------
  printf "Installing Homebrew for user '%s'...\n" "${brew_user}"
  su - "${brew_user}" -c 'NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
}
