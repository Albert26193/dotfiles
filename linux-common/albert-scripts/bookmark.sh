#!/bin/bash

# ab.bookmark
function ab.bm {
  local search_query="$1"
  local jump_list=(
    "${HOME}/.tmux-log"
    "${HOME}/.gdb/logs"
    "/data/workspace2/"
  )

  local selected_path
  if [[ -n "$search_query" ]]; then
    selected_path=$(printf '%s\n' "${jump_list[@]}" | fzf --query="$search_query" --preview='tree -L 1 {}' --preview-window=right:50%)
  else
    selected_path=$(printf '%s\n' "${jump_list[@]}" | fzf --preview='tree -L 1 {}' --preview-window=right:50%)
  fi
  
  if [[ -n "$selected_path" && -d "$selected_path" ]]; then
    cd "$selected_path"
    echo "Jumped to: $selected_path"
  else
    echo "No valid directory selected or cancelled."
  fi
}

