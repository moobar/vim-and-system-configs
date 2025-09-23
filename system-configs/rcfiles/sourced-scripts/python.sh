#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function venv-find-from-pwd() {
  find $(pwd) -name 'activate' -maxdepth 3 | grep '/bin/activate$'
}

# shellcheck disable=SC1090
## [venv-create]
#  Create a new venv
function venv-create() {
  local VENV_DIR="$(pwd)/.venv"
  if [[ -n $1 ]]; then
    VENV_DIR="$1"
  fi

  local VENV=
  # VENV="$(find . -name activate | grep -F '/bin/activate')"
  VENV="$(venv-find-from-pwd)"

  if [[ $(wc -l <<< "${VENV}") -gt 1 ]]; then
    echo "Already a venv here, skipping"
    return 1
  else
    echo "Creating a venv here in: ${VENV_DIR}"
    echo "Enter to continue,  CTRL-C to cancel"
    read -r _
    python3 -m venv "${VENV_DIR}"
    source "$(find . -name activate | grep -F '/bin/activate')"
  fi
}

# shellcheck disable=SC1090
## [venv-activate]
#  Finds a venv and activates it
function venv-activate() {
  local VENV=
  #if ! VENV="$(find . -name activate | grep -F '/bin/activate')"; then
  if ! VENV="$(venv-find-from-pwd)"; then
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

# shellcheck disable=SC1090
## [venv-vscode]
#  Finds a venv and prints helpful commands to remember how to set it for VSCode
function venv-vscode() {
  local VENV=
  if ! VENV="$(find "$(pwd)" -name activate | grep -F '/bin/activate')"; then
    echo "No virtual env found."
    return 1
  fi

  if [[ $(wc -l <<< "${VENV}") -gt 1 ]]; then
    echo "Choose VENV"
    VENV="$(echo "${VENV}" | sort -u | fzf)"
  fi

  VENV="$(sed 's/\/activate$/\/python3/' <<< "${VENV}")"

  echo "Set the Python interpreter in VS Code."
  echo "You need to explicitly copy the path, not select it from the file picker or it follows the symlink"
  echo ""
  echo "CMD+SHIFT+P -> Python: Select Interpreter"
  echo "Use this path:"
  echo "${VENV}"
}

function venv-activate-in-tmux() {
  if ! am-i-in-tmux; then
    # Do nothing
    return 0
  fi
  local TMUX_SESSION_NAME=
  local VENV=

  if ! TMUX_SESSION_NAME="$(tmux display-message -p '#S')"; then
    # Can't get the session name, do nothing
    return 0
  fi

  if [[ "$TMUX_SESSION_NAME" == "py-"* ]]; then
    if VENV="$(venv-find-from-pwd)" && [[ -n "$VENV" ]]; then
      if ! venv-activate; then
        echo "Tried to activate a venv and failed."
      fi
    fi
  fi
}

function ffpython() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

