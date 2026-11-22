#!/bin/bash

# @desc: 以只读日志模式用 nvim 分页查看标准输入（按 q 退出）
# @usage: cmd | ab.pager
# @alias: np
# @tags: nvim log
function ab.pager {
  nvim -R     -c "set noswapfile"     -c "set ft=log"     -c "nnoremap q :qa!<CR>"     -
}
