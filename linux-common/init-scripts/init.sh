#!/usr/bin/env bash

function init_dotbot_scripts {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  for script in ${script_dir}/install_*.sh; do
    [[ -f $script ]] || continue
    echo "Running script: $script"
    bash "$script"
  done

  # sh "${script_dir}/install_brew.sh"
}

init_dotbot_scripts
