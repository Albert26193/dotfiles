#!/bin/bash

function source_all_scripts {
  local target_dir="$1"

  if [[ ! -d ${target_dir} ]]; then
    echo "param 1 is illegal"
  fi

  for file in "${target_dir}"/*; do
    if [[ ${file} =~ "export.sh" ]]; then
      continue
    elif [[ -f "${file}" ]] && [[ "${file}" == *.sh ]]; then
      source "${file}"
    elif [[ -d "${file}" ]]; then
      source_all_scripts "$file"
    fi
  done
}

source_all_scripts "${HOME}/.albert-scripts/network"
# source_all_scripts "${HOME}/.albert-scripts/rsync"
source_all_scripts "${HOME}/.albert-scripts/misc"
