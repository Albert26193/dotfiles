#!/bin/bash

# @desc: 输出当前 Git 仓库所在分支名
function ab.git.branch {
  git rev-parse --abbrev-ref HEAD
}

# @desc: 跳转到当前 Git 仓库根目录
function ab.git.path {
  cd "$(git rev-parse --show-toplevel)"
}

# @desc: fzf 检索本地与远程 Git 分支并复制到剪贴板
function ab.git.all.branch {
  local selected branch

  # 本地分支 + 远程分支一起列出来
  selected=$(
    {
      # 本地分支
      git for-each-ref --format='local	%(authorname)	%(refname:short)' refs/heads
      # 远程分支
      git for-each-ref --format='remote	%(authorname)	%(refname:short)' refs/remotes
    } | fzf --delimiter=$'\t' --with-nth=1,2,3 \
      --preview 'git log -1 --color=always {3}'
  )

  [[ -z "$selected" ]] && return

  # 取第三列（分支名）
  branch=$(echo "$selected" | awk -F'\t' '{print $3}')

  # 如果是远程分支（带 origin/ 等前缀），去掉前缀
  if [[ "$branch" == */* ]]; then
    branch="${branch#*/}"
  fi

  echo "$branch"

  # 复制到剪贴板（OSC 52）
  printf "\033]52;c;$(echo -n "$branch" | base64)\a" >&2
}

# @desc: 将单个或区间 commit 导出为 git format-patch 补丁文件
# @usage: ab.git.patch.gen <commit> [<end>] [format-patch-args...]
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

# @desc: 用 git range-diff 对比两组 commit 补丁差异
# @usage: ab.git.patch.diff <old> <new>
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

# @desc: 计算 commit 或 .patch 文件的稳定补丁指纹（git patch-id）
# @usage: ab.git.patch.id <commit|file.patch> [...]
function ab.git.patch.id {
  if [ $# -lt 1 ]; then
    echo "usage: ab.git.patch.id <commit|file.patch> [<commit|file.patch> ...]" >&2
    return 2
  fi
  local spec
  for spec in "$@"; do
    printf '%s  ' "$spec"
    if [ -f "$spec" ]; then
      git patch-id --stable <"$spec"
    else
      git show --format= "$spec" | git patch-id --stable
    fi
  done
}
