#!/bin/bash

(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi

set -e -o pipefail

PREFIX=
# C-g is really convenient for one handed prefix (with CAPS -> CTRL)
PREFERRED_PREFIX='set-option -g prefix C-g'

``
SECONDARY_PREFIX='set-option -g prefix C-f'
if [[ -r ~/.tmux.conf ]]; then
  # If tmux is already there, use that existing prefix
  PREFIX=$(grep -F 'set-option -g prefix' ~/.tmux.conf 2>/dev/null)
elif [[ "$OS_NAME" == "Darwin" ]]; then
  PREFIX="${PREFERRED_PREFIX}"
else 
  PREFIX="${SECONDARY_PREFIX}"
fi

cat << EOF > ~/.tmux.conf
# For main/physical computer, use C-g as prefix
# For VPS/Secondary (tmux within tmux), use C-f as prefix

${PREFIX}

source ~/.vim/system-configs/rcfiles/tmux/tmux.conf
EOF

echo "${BASH_SOURCE[0]}: Completed tmux conf setup succesfully!"
