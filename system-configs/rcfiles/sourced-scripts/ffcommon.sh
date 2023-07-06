#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function ffcommon() {
  local ESCAPED_REPLACE=$(printf '%s\n' "${CONFIGROOT_DIR_SCRIPT}" | sed -e 's/[\/&]/\\&/g')
  # shellcheck disable=SC2016
  eval "$(echo "${BASH_FZF_IN_SOURCED_SCRIPT}" | sed 's/\${BASH_SOURCE\[0\]}'"/${ESCAPED_REPLACE}"'\/system-configs\/bash-script-commons\/common.sh/')"
}


function print-src-dir-bash() {
  # shellcheck disable=SC2016
  echo 'SRC_DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"'
}
