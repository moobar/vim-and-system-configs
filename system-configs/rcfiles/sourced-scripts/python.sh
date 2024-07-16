#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

# shellcheck disable=SC1090
function venv-activate() {
  local VENV=
  VENV="$(find . -name activate | grep -F '/bin/activate')"

  if [[ $(wc -l <<< "${VENV}") -gt 1 ]]; then
    source "$(echo "${VENV}" | sort -u | fzf)"
  else
    source "${VENV}"
  fi
}


function ffpython() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

