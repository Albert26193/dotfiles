#!/bin/bash

# @desc: 以 linuxbrew 用户身份执行 brew 子命令（install 自动跳过已装包）
# @usage: ab.brew <action> [package ...]
function ab.brew {
  local brew_user="linuxbrew"
  local brew_bin="/home/${brew_user}/.linuxbrew/bin/brew"
  local action="$1"
  shift
  local packages=("$@")

  [[ -n "${action}" ]] || {
    _ab.ui.red 'Usage: ab.brew <action> [package ...]'
    return 1
  }

  if ! id "${brew_user}" &>/dev/null; then
    _ab.ui.red "Error: user '${brew_user}' does not exist. Run ab.install.brew first."
    return 2
  fi

  if [[ ! -x "${brew_bin}" ]]; then
    _ab.ui.red "Error: brew not found at '${brew_bin}'. Run ab.install.brew first."
    return 3
  fi

  if [[ "${action}" == "install" && ${#packages[@]} -gt 0 ]]; then
    local to_install=()
    local pkg
    for pkg in "${packages[@]}"; do
      if su - "${brew_user}" -c "eval \"\$(${brew_bin} shellenv)\" && brew list ${pkg}" &>/dev/null; then
        _ab.ui.green "${pkg} is already installed, skipping."
      else
        to_install+=("${pkg}")
      fi
    done
    [[ ${#to_install[@]} -eq 0 ]] && {
      _ab.ui.green "All packages already installed."
      return 0
    }
    packages=("${to_install[@]}")
  fi

  local cmd="eval \"\$(${brew_bin} shellenv)\" && brew ${action} ${packages[*]}"
  _ab.ui.yellow "Running: brew ${action} ${packages[*]}"
  su - "${brew_user}" -c "${cmd}"
  local ret=$?

  if [[ ${ret} -eq 0 ]]; then
    _ab.ui.green "brew ${action} completed successfully."
  else
    _ab.ui.red "brew ${action} failed (exit code: ${ret})."
  fi
  return "${ret}"
}

# @desc: 将 linuxbrew 常用工具批量软链到 ~/.local/bin
function ab.brew.link {
  local brew_home="/home/linuxbrew"
  local brew_bin_dir="${brew_home}/.linuxbrew/bin"
  local brew_bin="${brew_bin_dir}/brew"
  local target_dir="${HOME}/.local/bin"
  local link_bins=(
    "lazygit" "neovim" "nvim"
    "tmux" "gdb" "cgdb"
    "delta" "ccls" "starship" "mycli"
    "rg" "fd" "fzf" "yazi"
    "git" "tailspin" "tmuxp"
  )

  if [[ ! -x "${brew_bin}" ]]; then
    _ab.ui.red "Error: brew not found at '${brew_bin}'. Run ab.install.brew first."
    return 1
  fi

  mkdir -p "${target_dir}"

  local linked=0
  local skipped=0
  local bin src dst

  for bin in "${link_bins[@]}"; do
    src="${brew_bin_dir}/${bin}"
    dst="${target_dir}/${bin}"

    if [[ ! -e "${src}" ]]; then
      skipped=$((skipped + 1))
      continue
    fi

    if [[ -L "${dst}" && "$(readlink -f "${dst}")" == "$(readlink -f "${src}")" ]]; then
      _ab.ui.green "${bin} already linked."
      skipped=$((skipped + 1))
      continue
    fi

    ln -sf "${src}" "${dst}"
    _ab.ui.yellow "${bin} -> ${dst}"
    linked=$((linked + 1))
  done

  _ab.ui.green "Done: ${linked} linked, ${skipped} skipped."
}

# @desc: 清理并重置 Homebrew 仓库后更新
function ab.brew.fix {
  brew cleanup

  cd "$(brew --repository)" || return 1
  git checkout -- .
  git reset --hard origin/master

  cd "$(brew --repository homebrew/core)" || return 1
  git checkout -- .
  git reset --hard origin/master

  brew update
  brew update
}
