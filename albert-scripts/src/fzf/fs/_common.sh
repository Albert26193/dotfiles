#!/bin/bash

function _ab.fs.show {
  local current_path
  current_path=$(pwd)
  local normal_file_num
  normal_file_num=$(ls -al | tail -n +4 | grep "^-" | wc -l | tr -d ' ')
  local dir_file_num
  dir_file_num=$(ls -al | tail -n +4 | grep "^d" | wc -l | tr -d ' ')
  local total_num=$((normal_file_num + dir_file_num))

  printf "\033[1;30m\033[44mjump to: \033[1;30m\033[42m%s\033[0m\n" "${current_path}"
  printf "\033[1;30m\033[44mfile count: \033[1;30m\033[42m%s\033[0m\n" "${total_num}"
  printf "\n"

  if [[ ${total_num} -le 35 ]]; then
    ls -al --color=always | tail -n +2
  elif [[ ${total_num} -ge 101 ]]; then
    echo "files in current directory is more than 100"
  else
    ls -a
  fi
  return 0
}
