#!/bin/bash

function np {
  nvim -R \
    -c "set noswapfile" \
    -c "set ft=log" \
    -c "nnoremap q :qa!<CR>" \
    -
}
