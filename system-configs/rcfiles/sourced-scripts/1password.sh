#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

# TODO:
#  1. Set DEFAULT_VALUE to something read and check if it's not set and set it
#

function _check-default-vault() {
  if [[ -z "$DEFAULT_1PASS_VAULT" ]]; then
    f1pass-select-vault
    return "$?"
  fi

  return 0
}

function f1pass-select-vault() {
  local DEFAULT_1PASS_VAULT_LOCAL=
  if DEFAULT_1PASS_VAULT_LOCAL="$(op vault list | fzf --header-lines 1 --accept-nth 1)"; then
    export DEFAULT_1PASS_VAULT="${DEFAULT_1PASS_VAULT_LOCAL}"
    return 0
  else
    return 1
  fi
}

function op-reveal-secret-field() {
  if [[ -z $1 ]]; then
    echo "First Arg must be the secret field (or a list of secret fields)"
    return 1
  fi
  local FIELDS="$1"
  local ITEM=
  if _check-default-vault; then
    if ITEM="$(op item list --vault "${DEFAULT_1PASS_VAULT}" | fzf --header-lines 1 --accept-nth 1)" && [[ -n "$ITEM" ]]; then
      op item get --fields "${FIELDS}" --reveal  "${ITEM}"
    fi
  fi
}

function op-reveal-api-creds() {
  op-reveal-secret-field "credential"
}

function op-reveal-api-password() {
  op-reveal-secret-field "password"
}

function ff1pass() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

