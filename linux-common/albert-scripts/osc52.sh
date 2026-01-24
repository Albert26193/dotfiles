#!/bin/bash

# osc52 copyboard -> oc
function oc {
  input=$(cat | tee /dev/tty)
  printf "\033]52;c;$(echo -n "$input" | base64)\a" >&2
}

function oc.fc {
  fc -ln | tail -n 1 | oc
}
