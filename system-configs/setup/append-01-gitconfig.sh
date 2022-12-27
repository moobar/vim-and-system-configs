#!/bin/bash

(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi

set -e -o pipefail

cat << EOF >> ~/.gitconfig

[include]
  path = ~/.vim/system-configs/git-configs/gitconfig

EOF

echo "${BASH_SOURCE[0]}: Completed github append succesfully!"
