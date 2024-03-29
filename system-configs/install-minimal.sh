#!/bin/bash
# vim: set foldmethod=marker foldlevel=0 nomodeline:

# ============================================================================
# Don't source script {{{1
# ============================================================================

(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi

# }}}}
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

set -e -o pipefail

(
  SRC_DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"

  touch ~/.disable_upgrades
  # shellcheck disable=SC1090
  for setup in "${SRC_DIR}/setup-minimal/setup-"*; do
    if ! bash "${setup}"; then
      echo "Failed on [${setup}]"
      echo "Time to manually debug!"
      exit 1
    fi
  done
  echo "Completed all rcfiles setup"

  # shellcheck disable=SC1090
  for install in "${SRC_DIR}/setup-minimal/install-"*; do
    if ! bash "${install}"; then
      echo "Failed on [${install}]"
      echo "Time to manually debug!"
      exit 1
    fi
  done
  echo "Completed all installation scripts"
)

