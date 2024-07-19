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
# Install node and global node packages {{{1
# ============================================================================

echo "Installing node via nvm, yarn and bash lsp"
countdown 5
(
  export NVM_DIR=~/.nvm
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  # Use nvm to install node
  nvm install node

  # Now that npm is installed, let's install some things we need
  npm install -g yarn
  npm install -g bash-language-server
  npm install -g neovim
)

# }}}}
# ============================================================================
# Install gcloud components {{{1
# ============================================================================

echo "Install gcloud components like kubectl, auth and a few others"
countdown 5
(
  gcloud components install --quiet \
    gke-gcloud-auth-plugin kubectl log-streaming terraform-tools alpha beta \
    docker-credential-gcr pkg
)

# }}}}
# ============================================================================

echo "${BASH_SOURCE[0]}: Completed installation succesfully!"
