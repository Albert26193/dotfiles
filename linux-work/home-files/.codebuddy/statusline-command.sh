#!/bin/bash
# CodeBuddy statusLine command. Reads CodeBuddy JSON from stdin and prints one concise line.

set -f
input=$(cat)

if [ -z "$input" ]; then
  printf "CodeBuddy"
  exit 0
fi

# Colors, matching the concise style of /root/.claude-internal/statusline.sh
blue='\033[38;2;102;204;255m'
yellow='\033[38;2;220;220;0m'
cyan='\033[0;38;2;225;225;225m'
green='\033[38;2;0;205;95m'
red='\033[38;2;255;85;85m'
dim='\033[2m'
reset='\033[0m'
sep=" ${dim}│${reset} "

json() {
  printf '%s' "$input" | jq -r "$1" 2>/dev/null
}

format_tokens() {
  local num="$1"
  [ -z "$num" ] || [ "$num" = "null" ] && return
  awk -v n="$num" 'BEGIN {
    if (n !~ /^[0-9]+([.][0-9]+)?$/) { printf "%s", n; exit }
    if (n >= 1000000) printf "%.1fm", n / 1000000
    else if (n >= 1000) printf "%.0fk", n / 1000
    else printf "%.0f", n
  }'
}

format_pct() {
  local num="$1"
  [ -z "$num" ] || [ "$num" = "null" ] && return
  awk -v n="$num" 'BEGIN { if (n ~ /^[0-9]+([.][0-9]+)?$/) printf "%.0f", n }'
}

model_name=$(json '.model.display_name // .model.id // "CodeBuddy"')
[ -z "$model_name" ] || [ "$model_name" = "null" ] && model_name="CodeBuddy"

cwd=$(json '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd=$(pwd)
case "$cwd" in
  "$HOME") display_pwd="~" ;;
  "$HOME"/*) display_pwd="~${cwd#$HOME}" ;;
  *) display_pwd="$cwd" ;;
esac

ctx_size=$(json '.context_window.context_window_size // .context_window.size // .contextWindow.size // .model.context_window // empty')
ctx_pct=$(json '.context_window.used_percentage // .contextWindow.used_percentage // empty')
ctx_pct_fmt=$(format_pct "$ctx_pct")

if [ -z "$ctx_pct_fmt" ]; then
  current_tokens=$(json '([.context_window.current_usage.input_tokens, .context_window.current_usage.cache_creation_input_tokens, .context_window.current_usage.cache_read_input_tokens, .context_window.current_usage.output_tokens] | map(. // 0) | add) // empty')
  if [ -n "$current_tokens" ] && [ -n "$ctx_size" ] && [ "$ctx_size" != "null" ]; then
    ctx_pct_fmt=$(awk -v cur="$current_tokens" -v size="$ctx_size" 'BEGIN { if (size > 0) printf "%.0f", cur * 100 / size }')
  fi
fi

ctx_size_fmt=$(format_tokens "$ctx_size")
if [ -n "$ctx_pct_fmt" ]; then
  ctx_display="ctx ${ctx_pct_fmt}%"
  [ -n "$ctx_size_fmt" ] && ctx_display="${ctx_display}/${ctx_size_fmt}"
elif [ -n "$ctx_size_fmt" ]; then
  ctx_display="ctx ${ctx_size_fmt}"
else
  ctx_display="ctx n/a"
fi

git_branch="-"
git_dirty=""
if GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || GIT_OPTIONAL_LOCKS=0 git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_branch="$branch"
    if GIT_OPTIONAL_LOCKS=0 git -C "$cwd" status --porcelain 2>/dev/null | grep -q .; then
      git_dirty="*"
    fi
  fi
fi

line="${cyan} ${model_name}${reset}"
line+="${sep}${yellow}${ctx_display}${reset}"
line+="${sep}${blue}${display_pwd}${reset}"
line+="${sep}${green}git ${git_branch}"
[ -n "$git_dirty" ] && line+="${red}${git_dirty}${green}"
line+="${reset}"

printf "%b" "$line"
