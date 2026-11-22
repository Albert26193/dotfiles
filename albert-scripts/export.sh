#!/bin/bash

function _ab_export_source_dir {
  local target_dir="$1"
  if [[ ! -d "${target_dir}" ]]; then
    return 0
  fi

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    setopt localoptions nullglob
  fi

  local entry
  for entry in "${target_dir}"/_*.sh; do
    if [[ -f "${entry}" ]]; then
      source "${entry}"
    fi
  done

  for entry in "${target_dir}"/*.sh; do
    if [[ ! -f "${entry}" ]]; then
      continue
    fi
    case "${entry##*/}" in
      _*) continue ;;
    esac
    source "${entry}"
  done

  for entry in "${target_dir}"/*; do
    if [[ -d "${entry}" ]]; then
      _ab_export_source_dir "${entry}"
    fi
  done
}

function _ab_export_main {
  local root="${ALBERT_SCRIPTS_PATH:-${HOME}/.albert-scripts}"
  local src_root="${root}/src"

  if [[ -f "${root}/config.env" ]]; then
    source "${root}/config.env"
  fi

  if [[ -d "${src_root}/_utils" ]]; then
    _ab_export_source_dir "${src_root}/_utils"
  fi

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    setopt localoptions nullglob
  fi

  local category
  for category in "${src_root}"/*; do
    if [[ ! -d "${category}" ]]; then
      continue
    fi
    if [[ "${category##*/}" == "_utils" ]]; then
      continue
    fi
    _ab_export_source_dir "${category}"
  done
}

_ab_export_main
unset -f _ab_export_main _ab_export_source_dir
