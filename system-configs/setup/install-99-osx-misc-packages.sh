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
# Exit script if not OSX {{{1
# ============================================================================

## Only run this script when on OSX
if [[ $(uname -s) != "Darwin" ]]; then
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

# }}}}
# ============================================================================
# Install additional casks/programs that aren't limited to CLI {{{1
# ============================================================================

echo "Installing additional casks, amethyst is probably the most controversial one"
echo "You may want to purge Amethyst if the tiling is annoying"
countdown 5

brew install --cask amethyst || true
brew install --cask burp-suite || true
brew install --cask caffeine || true
brew install --cask google-chrome || true
brew install --cask rectangle || true
brew install --cask visual-studio-code || true
brew install --cask wireshark || true
brew install --cask notion || true
brew install --cask vpn-by-google-one || true

# }}}}
# ============================================================================

echo "${BASH_SOURCE[0]}: Completed installation succesfully!"
