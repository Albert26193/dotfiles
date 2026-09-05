#!/bin/bash

function init_dotbot_scripts {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  for script in ${script_dir}/install_*.sh; do
    [[ -f $script ]] || continue
    echo "Running script: $script"
    bash "$script"
  done

}

init_dotbot_scripts
