#!/bin/bash

export ALBERT_SCRIPTS_PATH="${HOME}/.albert-scripts"

function source_all_scripts {
  local target_dir="$1"

  if [[ ! -d ${target_dir} ]]; then
    echo "param 1 is illegal"
  fi

  for file in "${target_dir}"/*; do
    if [[ ${file} =~ "export.sh" || ${file} =~ "utils.sh" ]]; then
      continue
    elif [[ -f "${file}" ]] && [[ "${file}" == *.sh ]]; then
      source "${file}"
    elif [[ -d "${file}" ]]; then
      source_all_scripts "$file"
    fi
  done
}

source_all_scripts "${HOME}/.albert-scripts"
