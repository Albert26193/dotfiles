#!/bin/bash

function ab.ze.killall {
  zellij ls | sed 's/\x1b\[[0-9;]*m//g' | awk '{print $1}' | xargs -I {} zellij delete-session {}
}

function ab.ze.n {
  zellij -l ${HOME}/.config/zellij/layouts/01.layout.kdl
}
