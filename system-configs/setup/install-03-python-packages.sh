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
# Install python3 packages via pip {{{1
# ============================================================================

echo "python, install mypy and black for formatting"
echo "Also installing generally useful packages like pyyaml and requests"
(
  echo "NO PYTHON PACAKGES INSTALLED. Brew is weird now and they really don't want you installing packages"
  echo "Their guidance generally is 'Use a venv'"
  # TODO: This whole thing is a lil borked now with homebrew and system-packages
  # python3 -m pip install --upgrade pip
  # python3 -m pip install pybind11
  # python3 -m pip install pynvim
  # python3 -m pip install mypy black pytype
  # python3 -m pip install sortedcontainers                                                                                                                                                                                                                                             37                                                                                                                                                                                                                                                                                         38   # Other package                                                                                                                                                                                                                                                                       39   # python3 -m pip install pyyaml
  # python3 -m pip install 'httpx[http2,cli]'
)


# }}}}
# ============================================================================

echo "${BASH_SOURCE[0]}: Completed installation succesfully!"
