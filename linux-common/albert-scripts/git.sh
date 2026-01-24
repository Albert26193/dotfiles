#!/bin/bash

function git.branch {
  git rev-parse --abbrev-ref HEAD
}

function git.path {
  cd "$(git rev-parse --show-toplevel)"
}
