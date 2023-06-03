#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/common.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/common.sh"
fi
CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi
eval "${BASH_COMMON_SCRIPT_UNSOURCEABLE}"

## Put Code Here
function moomoo() { echo "MOO!!"; }

function cache-command-moo() {
  cache_command -f "${FUNCNAME[0]}" -d "examples" \
    -x 'echo moo; echo moomoo; echo moomoomoo' \
  | fzf --tac --header="  [examples!: isn't this fun?]"
}
## End Example Code

eval "${BASH_COMMON_SCRIPT_FOOTER}"
