#!/bin/bash

function ab.git.branch {
  git rev-parse --abbrev-ref HEAD
}

function ab.git.path {
  cd "$(git rev-parse --show-toplevel)"
}

function ab.git.all.branch {
  git for-each-ref --format='%(authorname) %09 %(refname)' refs/remotes | fzf
}
