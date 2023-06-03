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

# ============================================================================
# Helper Functions {{{1
# ============================================================================
function countdown() {
  local SECONDS=
  if [[ -z $1 ]]; then
    SECONDS=$1
  else
    SECONDS=5
  fi
  for i in $(seq "${SECONDS}" 1); do
    echo "${i}..."
    sleep 1
  done
}

# }}}}
# ============================================================================
# Update vim-plug and vim-coc plugings {{{1
# ============================================================================

## NOTE
## This install script only will update the primary ~/.vim / vim installation.
## It doesn't update anything relative to the git repo

##
echo "Updating vim plugins, and then installing a bunch of coc packages, \
  and tree-sitter packages (for better syntax highlighting)"
countdown 5

(

  export NVM_DIR=~/.nvm
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  rm -rf ~/.vim/plugged/*
  rm -rf ~/.config/coc

  # If we are in screen, let's set the color for a better vim UI experience
  if [[ -n $STY ]]; then
    export TERM=screen-256color
  fi
  nvim +PlugUpgrade +PlugClean +PlugInstall +PlugUpdate +qall

  SRC_DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
  nvim -S "${SRC_DIR}/vimscript-add-treesitter-modules.vim"
  nvim -S "${SRC_DIR}/vimscript-add-coc-plugin-modules.vim"
)


# }}}}
# ============================================================================
# Manually set up java lsp (jdtls) {{{1
# ============================================================================

# Set up jdtls for coc-java
(
  mkdir -p ~/.config/coc/extensions/coc-java-data
  cd ~/.config/coc/extensions/coc-java-data || exit 1
  rm -rf -- *
  wget https://download.eclipse.org/jdtls/milestones/1.9.0/jdt-language-server-1.9.0-202203031534.tar.gz
  mkdir -p server
  cd server || exit 1
  tar -xvzf ../jdt-language-server-1.9.0-202203031534.tar.gz
)

# }}}}
# ============================================================================

echo "${BASH_SOURCE[0]}: Completed installation succesfully!"
