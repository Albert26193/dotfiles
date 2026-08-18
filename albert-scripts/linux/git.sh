#!/bin/bash

function ab.git.branch {
  git rev-parse --abbrev-ref HEAD
}

function ab.git.path {
  cd "$(git rev-parse --show-toplevel)"
}

function ab.git.all.branch {
  git for-each-ref --format='%(authorname) %09 %(refname)' refs/remotes | fzf
}

# 把一段 commit 写成 format-patch 文件（含起点）。
#   ab.git.patch.gen 65126d1                 → 65126d1^..65126d1
#   ab.git.patch.gen 65126d1 068ea9f         → 65126d1^..068ea9f
#   ab.git.patch.gen acba707..068ea9f -o /tmp/patches
function ab.git.patch.gen {
  if [ $# -lt 1 ]; then
    echo "usage: ab.git.patch.gen <commit> [<end>] [format-patch-args...]" >&2
    echo "   or: ab.git.patch.gen <base>..<tip> [format-patch-args...]" >&2
    return 2
  fi
  local range
  if [[ "$1" == *..* ]]; then
    range=$1
    shift
  elif [ $# -ge 2 ] && [[ "$2" != -* ]]; then
    range="${1}^..${2}"
    shift 2
  else
    range="${1}^..${1}"
    shift
  fi
  git format-patch "$range" "$@"
}

# 比两串补丁（range-diff），不是比两棵树（git diff）。
#   ab.git.patch.diff 65126d1 faaf042
#   ab.git.patch.diff acba707..068ea9f d56c4c4..0625070
function ab.git.patch.diff {
  if [ $# -ne 2 ]; then
    echo "usage: ab.git.patch.diff <old> <new>" >&2
    echo "   or: ab.git.patch.diff <old-base>..<old-tip> <new-base>..<new-tip>" >&2
    return 2
  fi
  local left=$1 right=$2
  if [[ "$left" == *..* || "$right" == *..* ]]; then
    if [[ "$left" != *..* || "$right" != *..* ]]; then
      echo "ab.git.patch.diff: both sides must be ranges (a..b) or both commits" >&2
      return 2
    fi
    git range-diff "$left" "$right"
    return
  fi
  git range-diff "${left}^..${left}" "${right}^..${right}"
}

# 补丁指纹。两边 hash 一样 = 同一份改动（忽略行号）。
#   ab.git.patch.id 65126d1
#   ab.git.patch.id 65126d1 faaf042
#   ab.git.patch.id 0001-*.patch
function ab.git.patch.id {
  if [ $# -lt 1 ]; then
    echo "usage: ab.git.patch.id <commit|file.patch> [<commit|file.patch> ...]" >&2
    return 2
  fi
  local spec
  for spec in "$@"; do
    printf '%s  ' "$spec"
    if [ -f "$spec" ]; then
      git patch-id --stable < "$spec"
    else
      git show --format= "$spec" | git patch-id --stable
    fi
  done
}
