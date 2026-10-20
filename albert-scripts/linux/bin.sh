#!/bin/bash

###################################################
# description: print every directory in PATH, one per line
#       echo: PATH directory
#      return: 0
###################################################
function _ab.link.bin.paths {
  printf '%s\n' "$PATH" | tr ':' '\n'
}

###################################################
# description: scan PATH and print executables as TSV
#          $1: directory to exclude (the link target dir)
#       echo: name<TAB>path_order<TAB>path
#      return: 0
###################################################
function _ab.link.bin.scan {
  local exclude_real
  exclude_real=$(readlink -f "$1" 2>/dev/null || printf '%s' "$1")

  # zsh errors on empty globs unless nullglob is on; keep it local to this function
  [[ -n "${ZSH_VERSION:-}" ]] && setopt localoptions nullglob

  local seen_dirs=":"
  local index=0
  local dir dir_real entry name

  while IFS= read -r dir; do
    [[ -n "$dir" && -d "$dir" ]] || continue

    dir_real=$(readlink -f "$dir" 2>/dev/null || printf '%s' "$dir")
    [[ "$dir_real" == "$exclude_real" ]] && continue
    case "$seen_dirs" in
      *":$dir_real:"*) continue ;;
    esac
    seen_dirs="${seen_dirs}${dir_real}:"

    for entry in "${dir%/}"/*; do
      # -f follows symlinks, so broken links and directories are skipped
      [[ -f "$entry" && -x "$entry" ]] || continue
      name="${entry##*/}"
      printf '%s\t%d\t%s\n' "$name" "$index" "$entry"
    done

    index=$((index + 1))
  done < <(_ab.link.bin.paths)

  return 0
}

###################################################
# description: interactively link a binary into ~/.local/bin to raise its PATH priority
#       flow: fzf select command -> fzf select location -> ln -sfn
#      return: 0: linked / already linked | 1: error / aborted
###################################################
function ab.link.bin {
  local target_dir="${HOME}/.local/bin"
  local target_real
  target_real=$(readlink -f "$target_dir" 2>/dev/null || printf '%s' "$target_dir")

  [[ -n "${ZSH_VERSION:-}" ]] && setopt localoptions nullglob

  # --- pre-flight checks ----
  if ! command -v fzf &>/dev/null; then
    printf 'error: fzf is not installed or not in PATH.\n' >&2
    return 1
  fi

  local scan_file
  scan_file=$(mktemp) || {
    printf 'error: cannot create temporary file.\n' >&2
    return 1
  }

  _ab.link.bin.scan "$target_dir" | sort -t $'\t' -k1,1 -k2,2n >"$scan_file"

  # --- step 1: pick a command name ---
  local candidates
  candidates=$(awk -F'\t' '
    $1 != prev {
      if (prev != "") printf "%s\t%d\t%s\n", prev, count, first
      prev = $1; count = 0; first = $3
    }
    { count++ }
    END { if (prev != "") printf "%s\t%d\t%s\n", prev, count, first }
  ' "$scan_file")

  if [[ -z "$candidates" ]]; then
    rm -f "$scan_file"
    printf 'error: no executable found in PATH.\n' >&2
    return 1
  fi

  local selection
  selection=$(printf '%s\n' "$candidates" |
    fzf --height=70% --delimiter=$'\t' --with-nth=1,2,3 \
      --header 'select command: name / count / first location')
  if [[ -z "$selection" ]]; then
    rm -f "$scan_file"
    printf 'aborted.\n'
    return 1
  fi

  local bin_name="${selection%%$'\t'*}"
  local dst="${target_dir}/${bin_name}"

  # --- step 2: pick one of its locations (already in PATH order) ---
  local locations
  locations=$(awk -F'\t' -v name="$bin_name" '$1 == name { print $3 }' "$scan_file")
  rm -f "$scan_file"

  local header="select location for '${bin_name}' (PATH order)"
  if [[ -L "$dst" ]]; then
    header="${header}; current ${dst} -> $(readlink "$dst")"
  fi

  local bin_path
  bin_path=$(printf '%s\n' "$locations" | fzf --height=40% --header "$header")
  if [[ -z "$bin_path" ]]; then
    printf 'aborted.\n'
    return 1
  fi

  # --- warn when the source already wins, or ~/.local/bin is not in PATH ---
  local src_real
  src_real=$(readlink -f "${bin_path%/*}" 2>/dev/null || printf '%s' "${bin_path%/*}")
  local local_bin_index=-1
  local src_index=-1
  local i=0 dir dir_real
  while IFS= read -r dir; do
    dir_real=$(readlink -f "$dir" 2>/dev/null || printf '%s' "$dir")
    if [[ "$dir_real" == "$target_real" && $local_bin_index -lt 0 ]]; then
      local_bin_index=$i
    fi
    if [[ "$dir_real" == "$src_real" && $src_index -lt 0 ]]; then
      src_index=$i
    fi
    i=$((i + 1))
  done < <(_ab.link.bin.paths)

  if [[ $local_bin_index -lt 0 ]]; then
    printf 'warning: %s is not in PATH; the link will not take effect.\n' "$target_dir" >&2
  elif [[ $src_index -ge 0 && $src_index -lt $local_bin_index ]]; then
    printf 'warning: %s already resolves before %s; the link will not change resolution.\n' \
      "${bin_path%/*}" "$target_dir" >&2
  fi

  # --- refuse to overwrite real files; confirm before replacing other links ---
  local need_confirm=0
  if [[ -L "$dst" ]]; then
    local dst_real new_real
    dst_real=$(readlink -f "$dst" 2>/dev/null)
    new_real=$(readlink -f "$bin_path" 2>/dev/null)
    if [[ -n "$dst_real" && "$dst_real" == "$new_real" ]]; then
      printf 'already linked: %s -> %s\n' "$dst" "$bin_path"
      return 0
    fi
    printf 'replace: %s\n  old -> %s\n  new -> %s\n' "$dst" "$(readlink "$dst")" "$bin_path"
    need_confirm=1
  elif [[ -e "$dst" ]]; then
    printf 'error: %s exists and is not a symlink, refusing to overwrite.\n' "$dst" >&2
    return 1
  fi

  # --- warn about names owned by a repo local-bin tree ---
  local repo_root managed=""
  repo_root=$(dirname "$(readlink -f "${ALBERT_SCRIPTS_PATH:-$HOME/.albert-scripts}" 2>/dev/null)")
  local candidate
  for candidate in "${repo_root}"/*/local-bin/"${bin_name}"; do
    if [[ -e "$candidate" ]]; then
      managed="$candidate"
      break
    fi
  done
  if [[ -n "$managed" ]]; then
    printf 'warning: %s is managed by dotbot (%s); the next `make link` will restore it.\n' \
      "$bin_name" "$managed" >&2
    need_confirm=1
  fi

  if [[ $need_confirm -eq 1 ]]; then
    printf 'continue? [y/N] '
    local answer=""
    read -r answer
    case "$answer" in
      [yY]*) ;;
      *)
        printf 'aborted.\n'
        return 1
        ;;
    esac
  fi

  mkdir -p "$target_dir"
  ln -sfn "$bin_path" "$dst" || return 1
  { rehash 2>/dev/null || hash -r; } 2>/dev/null

  printf 'linked: %s -> %s\n' "$dst" "$bin_path"
  local resolved
  resolved=$(command -v "$bin_name" 2>/dev/null)
  [[ -n "$resolved" ]] && printf 'resolved: %s\n' "$resolved"

  return 0
}
