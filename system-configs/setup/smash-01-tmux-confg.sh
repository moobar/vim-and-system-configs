#!/bin/bash

(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi

set -e -o pipefail

PREFIX=
# I like C-g and want to always set that as my default.
MY_PREFERRED_PREFIX='set-option -g prefix C-g'
if [[ -r ~/.tmux.conf ]]; then
  # If tmux is already there, use that existing prefix
  PREFIX=$(grep -F 'set-option -g prefix' ~/.tmux.conf 2>/dev/null)
else
  PREFIX="${MY_PREFERRED_PREFIX}"
fi

cat << EOF > ~/.tmux.conf
# If you haven't already, consider changing the default prefix.
# Here are some suggestions:
# Sagar remaps caps to ctrl and uses C-g      [one handed/left hand]
# For multi hand prefix, try C-j              [opposite hands]
# For single handed prefix consider C-a       [one handed/left hand]
# C-b is the default tmux prefix

${PREFIX}

source ~/.vim/system-configs/rcfiles/tmux/tmux.conf
EOF

echo "${BASH_SOURCE[0]}: Completed tmux conf setup succesfully!"
