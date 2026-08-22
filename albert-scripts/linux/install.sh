#!/bin/bash

# 安装并固定 Python 3.13 为默认版本（通过 uv）。
function ab.install.py {
  uv python install 3.13 --default
  uv python pin --global 3.13
  export UV_PYTHON=3.13
}
