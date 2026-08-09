#!/bin/bash
# claude-save.sh
# 两种模式(自包含单文件):
#   (默认)  Stop hook —— 读 stdin JSON,把同一 session 的完整对话(user+assistant)
#           增量追加写入 <out>/<git_branch>/N.md
#   --next  翻篇 —— 把当前 session 的后续对话切到下一个 N.md。只挪动 .state 的游标与
#           落点,不写 markdown;真正的写入仍由默认模式(Stop hook)完成。
#           通常这样手动触发:  !bash ~/.albert-scripts/func/claude-save.sh --next
#
# ===== .state 契约(每个 output_dir / git 分支一份)=====
#   SESSION=<session_id>   当前正在写入的 session
#   FILE=<n>               当前目标文件号 -> <n>.md
#   COUNT=<n>              已写入的消息条数;指向整个 session transcript 的游标
#   ROUND=<n>              该文件内的追加批次计数(--- ROUND n --- 标题)
# 关键不变量:COUNT 是"整段 transcript 的游标"。换 session 时 transcript 也换,归零
# 安全;但同一 session 内翻篇必须保持 COUNT 连续,否则会把已写历史重灌进新文件。
set -euo pipefail

# ============================================================
# 参数解析:--out-dir <绝对路径>(可选);--next 切换到翻篇模式
# ============================================================
parse_args() {
    out_dir=""
    mode="save"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --out-dir)
                out_dir="$2"
                shift 2
                ;;
            --next)
                mode="next"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ -n "$out_dir" && "$out_dir" != /* ]]; then
        echo "claude-save.sh: --out-dir must be an absolute path: $out_dir" >&2
        exit 1
    fi
}

# ============================================================
# 公共:分支解析 / 输出目录 / .state 读写 / 最大文件号
# ============================================================

# 依赖 $proj_dir;设置 $git_branch。detached HEAD -> detached-<short>;非 git -> no-git
resolve_git_branch() {
    git_branch=$(git -C "$proj_dir" branch --show-current 2>/dev/null || true)
    if [[ -z "$git_branch" ]]; then
        local commit
        commit=$(git -C "$proj_dir" rev-parse --short HEAD 2>/dev/null || true)
        git_branch=${commit:+detached-$commit}
    fi
    git_branch=${git_branch:-no-git}
}

# 依赖 $proj_dir / $out_dir;解析分支后设置 $output_dir 并 mkdir -p
build_output_dir() {
    resolve_git_branch
    if [[ -n "$out_dir" ]]; then
        output_dir="$out_dir/$git_branch"
    else
        output_dir="$proj_dir/.ai_dev_chat/$git_branch"
    fi
    mkdir -p "$output_dir"
}

# 依赖 $output_dir;读取 .state 到
# $state_file / $current_session / $current_file / $written_count / $round
read_state() {
    state_file="$output_dir/.state"
    current_session=""
    current_file=""
    written_count=0
    round=0

    if [[ -f "$state_file" ]]; then
        current_session=$(grep '^SESSION=' "$state_file" | cut -d= -f2-)
        current_file=$(grep '^FILE=' "$state_file" | cut -d= -f2-)
        written_count=$(grep '^COUNT=' "$state_file" | cut -d= -f2-)
        written_count=${written_count:-0}
        round=$(grep '^ROUND=' "$state_file" | cut -d= -f2-)
        round=${round:-0}
    fi
}

# 依赖 $state_file / $session_id / $current_file / $round;COUNT 由参数 $1 给定
write_state() {
    local count="$1"

    cat > "$state_file" <<EOF
SESSION=$session_id
FILE=$current_file
COUNT=$count
ROUND=$round
EOF
}

# 依赖 $output_dir;回显目录内最大的 N.md 号(无匹配则空)
max_md_number() {
    ls -1 "$output_dir" 2>/dev/null \
        | grep -E '^[0-9]+\.md$' \
        | sed 's/\.md$//' \
        | sort -n \
        | tail -1 || true
}

# ============================================================
# 默认模式(Stop hook)专用
# ============================================================
read_hook_input() {
    input=$(cat)
    transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
    session_id=$(echo "$input" | jq -r '.session_id // empty')
}

validate_hook_input() {
    [[ -z "$transcript_path" || ! -f "$transcript_path" ]] && exit 0
    [[ -z "$session_id" ]] && exit 0
    return 0
}

wait_for_transcript_flush() {
    # 等待 transcript flush(Stop hook 触发时当前 response 可能尚未写入 JSONL)
    # 等文件稳定(100ms 内没有新写入即认为 flush 完毕)
    prev_size=0
    for _ in 1 2 3 4 5; do
        cur_size=$(stat -c%s "$transcript_path" 2>/dev/null || echo 0)
        [[ "$cur_size" -gt 0 && "$cur_size" == "$prev_size" ]] && break
        prev_size=$cur_size
        sleep 0.2
    done
}

# 项目根目录 + 输出目录(hook 从 JSON 的 .cwd 拿项目根)
prepare_output_dir_from_hook() {
    proj_dir=$(echo "$input" | jq -r '.cwd // empty')
    if [[ -z "$proj_dir" ]]; then
        proj_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi

    build_output_dir
}

# ===== 只读一次 transcript =====
# user.message.content 是字符串;assistant.message.content 是数组
load_transcript_entries() {
    all_entries=$(jq -rs '
  [.[] | select(.type == "user" or .type == "assistant")
       | {
           role: .type,
           text: (
             if .type == "user" then
               (.message.content | if type == "string" then .
                else ([.[]? | select(.type == "text") | .text] | join("\n")) end)
             else
               ([.message.content[]? | select(.type == "text") | .text] | join("\n"))
             end
           )
         }
       | select(.text != "")
  ]
' "$transcript_path" 2>/dev/null) || exit 0

    total_count=$(echo "$all_entries" | jq 'length')
    [[ "$total_count" -le 0 ]] && exit 0
    return 0
}

# ===== 判断是否新 session =====
prepare_target_file() {
    if [[ "$session_id" != "$current_session" ]]; then
        local last next
        last=$(max_md_number)
        next=$(( ${last:-0} + 1 ))
        current_file="$next"
        written_count=0
        round=0
    fi

    target="$output_dir/${current_file}.md"
}

# ===== 没有新消息则跳过 =====
skip_if_no_new_messages() {
    if [[ "$total_count" -le "$written_count" ]]; then
        if [[ "$session_id" != "$current_session" ]]; then
            write_state "$written_count"
        fi
        exit 0
    fi
    return 0
}

# ===== 格式化新增消息 =====
format_new_content() {
    new_content=$(echo "$all_entries" | jq -r --argjson skip "$written_count" '
  .[$skip:][] |
  if .role == "user" then
    "## User\n\n" + .text
  else
    "\n## Assistant\n\n" + .text
  end
')

    [[ -z "$new_content" ]] && exit 0
    return 0
}

# ===== 追加写入 =====
append_new_content() {
    round=$(( round + 1 ))
    local header="--- ROUND $round ---"

    if [[ -s "$target" ]]; then
        printf '\n\n%s\n\n%s\n' "$header" "$new_content" >> "$target"
    else
        printf '%s\n\n%s\n' "$header" "$new_content" > "$target"
    fi
}

save_main() {
    read_hook_input
    validate_hook_input
    wait_for_transcript_flush
    prepare_output_dir_from_hook
    load_transcript_entries
    read_state
    prepare_target_file
    skip_if_no_new_messages
    format_new_content
    append_new_content
    write_state "$total_count"
}

# ============================================================
# 翻篇模式(--next)专用
# ============================================================

# 若命令行未显式给 --out-dir,则从本项目/全局 Claude settings 里 Stop hook 的命令
# 中继承 --out-dir,保证翻篇与 hook 落到同一个 output_dir(见脚本顶部说明的原理)。
# 依赖 $proj_dir;可能设置 $out_dir。
inherit_out_dir() {
    [[ -n "$out_dir" ]] && return

    local s
    for s in "$proj_dir/.claude/settings.local.json" \
             "$proj_dir/.claude/settings.json" \
             "$HOME/.claude/settings.json"; do
        [[ -f "$s" ]] || continue
        out_dir=$(jq -r '.hooks.Stop[]?.hooks[]?.command // empty' "$s" 2>/dev/null \
                  | grep -oE -- '--out-dir[ =][^ "]+' \
                  | sed -E 's/--out-dir[ =]//' \
                  | head -1 || true)
        [[ -n "$out_dir" ]] && break
    done
    # 仍为空 -> build_output_dir 回退默认 $proj_dir/.ai_dev_chat(与 hook 默认一致)
    # 显式 return 0:上面的 `&& break` 在未命中时会让函数返回 1,触发 set -e 误杀
    return 0
}

rotate_to_next() {
    # 守卫:无 .state 说明本分支还没被存档过,翻篇无从谈起
    if [[ ! -f "$state_file" ]]; then
        echo "claude-save --next: 该分支尚无 .state($output_dir),还没保存过对话,无需翻篇" >&2
        exit 0
    fi
    # 守卫:.state 残缺(缺 SESSION/FILE)时不动手,交给下一次 Stop hook 自愈
    if [[ -z "$current_session" || -z "$current_file" ]]; then
        echo "claude-save --next: .state 不完整,跳过翻篇" >&2
        exit 0
    fi

    local last next
    last=$(max_md_number)
    next=$(( ${last:-0} + 1 ))

    # 关键三步:SESSION 保持不变、COUNT 保持不变(游标连续)、FILE 前进、ROUND 归零
    session_id="$current_session"
    current_file="$next"
    round=0
    write_state "$written_count"

    # 预建空文件占号,防止此后新 session 靠 max_md_number 抢到同一个号造成冲突
    : > "$output_dir/${next}.md"

    echo "claude-save --next: 已翻篇 -> ${next}.md(分支 $git_branch,游标 COUNT=$written_count 保持)"
}

next_main() {
    proj_dir="$PWD"
    inherit_out_dir
    build_output_dir
    read_state
    rotate_to_next
}

# ============================================================
main() {
    parse_args "$@"
    if [[ "$mode" == "next" ]]; then
        next_main
    else
        save_main
    fi
}

main "$@"

exit 0
