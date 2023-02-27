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
  bash "${SRC_DIR}/install-minimal.sh"

  # shellcheck disable=SC1090
  for extra in "${SRC_DIR}/setup-minimal/extra-"*; do
    if ! bash "${extra}"; then
      echo "Failed on [${extra}]"
      echo "Time to manually debug!"
      exit 1
    fi
  done
  echo "Completed all extra setup"
)

