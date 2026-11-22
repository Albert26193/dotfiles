#!/bin/bash

# @desc: 切换 ~/.plain_ops/mirror/codex/config.toml 顶部的模型与 provider 配置
# @usage: ab.codex [off|<query>]
# @tags: ai codex
function ab.codex {
    local mirror_dir="${HOME}/.plain_ops/mirror/codex"
    local main_cfg="${mirror_dir}/config.toml"
    local picked

    if [[ "${1:-}" == "off" ]]; then
        picked="openai.config.toml"
    else
        picked="$(
            find "${mirror_dir}" -maxdepth 1 -name '*.config.toml' -exec basename {} \; | sort |
                fzf --query="$*" --height 40% --reverse \
                    --preview "cat '${mirror_dir}/{}'"
        )" || return 1
        [[ -z "${picked}" ]] && return 1
    fi

    local tmp="${main_cfg}.tmp.$$"
    (
        umask 077
        {
            cat "${mirror_dir}/${picked}"
            printf '\n'
            sed -n '/^# --- shared ---$/,$p' "${main_cfg}"
        } >"${tmp}" && mv "${tmp}" "${main_cfg}"
    ) || { rm -f "${tmp}"; return 1; }

    codex app-server --print-startup-config >/dev/null || return 1
    printf "switched ~/.codex/config.toml -> %s\n" "${picked}"
    sed -n '1,/^# --- shared ---$/{ /^# --- shared ---$/d; /./p; }' "${main_cfg}"
}
