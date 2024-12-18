#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

# shellcheck disable=SC1090
## [venv-create]
#  Create a new venv
function venv-create() {
  local VENV=
  VENV="$(find . -name activate | grep -F '/bin/activate')"

  if [[ $(wc -l <<< "${VENV}") -gt 1 ]]; then
    echo "Already a venv here, skipping"
    return 1
  else
    echo "Creating a venv here in: $(pwd)"
    echo "Enter to continue,  CTRL-C to cancel"
    read -r _
    python3 -m venv .
    source "$(find . -name activate | grep -F '/bin/activate')"
  fi
}

# shellcheck disable=SC1090
## [venv-active]
#  Finds a venv and activates it
function venv-activate() {
  local VENV=
  if ! VENV="$(find . -name activate | grep -F '/bin/activate')"; then
    echo "No virtual env found."
    return 1
  fi

  if [[ $(wc -l <<< "${VENV}") -gt 1 ]]; then
    source "$(echo "${VENV}" | sort -u | fzf)"
  else
    source "${VENV}"
  fi
}

## [venv-deactivate]
#  Because I always forget... and I'm like: how do I deactivate this
function venv-deactivate() {
  if [[ -n $VIRTUAL_ENV ]]; then
    echo "Just type [deactivate] next time"
    echo "Deactivating"
    deactivate
  else
    echo "Not in a venv"
  fi

}

function ffpython() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

