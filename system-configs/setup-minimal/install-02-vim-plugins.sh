#!/bin/bash
# vim: set foldmethod=marker foldlevel=0 nomodeline:

# ============================================================================
# Don't source script and set -e -o pipefail {{{1
# ============================================================================

(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi

set -e -o pipefail

# }}}}
# ============================================================================

# shellcheck disable=SC1090
DISABLE_UPGRADES=True source ~/.bashrc

# }}}}
# ============================================================================
# Update vim-plug plugings {{{1
# ============================================================================

## NOTE
## This install script only will update the primary ~/.vim / vim installation.
## It doesn't update anything relative to the git repo

##
echo "Updating vim plugins and tree-sitter packages (for better syntax highlighting)"

(

  rm -rf ~/.vim/plugged/*
  rm -rf ~/.config/coc

  # If we are in screen, let's set the color for a better vim UI experience
  if [[ -n $STY ]]; then
    export TERM=screen-256color
  fi
  vim +PlugUpgrade +PlugClean +PlugInstall +PlugUpdate +qall

  SRC_DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
  if type node 2>/dev/null >/dev/null; then
    vim -S "${SRC_DIR}/vimscript-add-treesitter-modules.vim"
  fi
)

echo "${BASH_SOURCE[0]}: Completed installation succesfully!"

