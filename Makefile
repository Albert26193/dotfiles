# ==============================================================================
# dotfiles 构建入口（最小集：init / link / help）
#
# 按「中大型工程下的 Makefile 编写」三段式切分：
#   Variables(Part 1)  - 路径、参数、默认值
#   Defines(Part 2)    - 可复用的 shell 流程
#   Targets(Part 3)    - 用户可执行入口
#
# DIR 必须显式指定、无默认值，未指定或目录不存在时直接报错退出：
#   make init DIR=mac-common    执行该树 init-scripts/init.sh（安装工具/依赖）
#   make link DIR=mac-common    通过 dotbot 执行该树 dotbot.yaml（建立配置 symlink）
#   make help                   打印用法
# ==============================================================================

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# ------------------------------------------------------------------------------
# Variables(Part 1)
# ------------------------------------------------------------------------------

# 锚点：无论从哪个 cwd 调用都能定位仓库根
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJ_DIR    := $(shell dirname "$(MKFILE_PATH)")

# 目标树，必须由命令行显式指定（默认空，未指定时在 defines 里校验报错）
# 取值：mac-common / mac-work / linux-common / linux-work
DIR :=

# ------------------------------------------------------------------------------
# Defines(Part 2)
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Macro: require_dir
# Description: 校验 DIR 变量 —— 必须非空，且对应目录存在于仓库内，否则报错退出。
# Global Dependencies: $(DIR), $(PROJ_DIR)
# ------------------------------------------------------------------------------
define require_dir
	@test -n "$(DIR)" || { echo "error: 必须显式指定 DIR，如 make init DIR=mac-common"; exit 1; }
	@test -d "$(PROJ_DIR)/$(DIR)" || { echo "error: 目录 $(PROJ_DIR)/$(DIR) 不存在（DIR 取 mac-common/mac-work/linux-common/linux-work）"; exit 1; }
endef

# ------------------------------------------------------------------------------
# Targets(Part 3)
# ------------------------------------------------------------------------------

default: help
.PHONY: default

help: ## 打印用法
	@printf 'dotfiles 入口 —— 所有操作需显式指定目标树 DIR：\n'
	@printf '  树 = mac-common | mac-work | linux-common | linux-work\n\n'
	@printf '用法：make <target> DIR=<树>\n\n'
	@printf 'Targets:\n'
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_.\/%-]+:.*##/ {printf "  \033[32m%-10s\033[0m %s\n", $$1, $$2}' "$(MKFILE_PATH)"
	@printf '\nDIR 必填且无默认值，未指定或目录不存在即报错。\n'
.PHONY: help

init: ## 执行对应树的 init.sh（安装工具/依赖）
	$(call require_dir)
	@bash "$(PROJ_DIR)/$(DIR)/init-scripts/init.sh"
.PHONY: init

link: ## 通过 dotbot 建立对应树 symlink
	$(call require_dir)
	@dotbot -c "$(PROJ_DIR)/$(DIR)/dotbot.yaml"
.PHONY: link

brew: ## eval $(brew shellenv) 并验证 brew 可用
	@eval "$$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew --version
.PHONY: brew
