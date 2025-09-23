#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

# Useful: https://kind.sigs.k8s.io/docs/user/quick-start/

function llmi() {
  local TEXT=
  if [[ $# -eq 0 ]] && test -t 0; then
    echo "Chat, CTRL-D to end and send"
    echo "----------------------------"
    TEXT="$(cat)"
    echo ""

    echo "Sending to model: ${TEXT:0:20}..."
    echo ""

    llm prompt -u "${TEXT}"

  else
    command llm "$@"
  fi
}

function ffllm() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

