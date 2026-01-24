function install_tpm {
  local tpm_path="$HOME/.tmux/plugins/tpm"
  [[ -d $tpm_path && -d $tpm_path/.git ]] && {
    printf "%s\n" "has installed tpm, return 0..."
    return 0
  }

  git clone https://github.com/tmux-plugins/tpm "$tpm_path"
}

install_tpm
