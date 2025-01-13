#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function get_cwd_of_script() {
  cat << 'EOM'
$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
EOM
}

function dont_source_script() {
  cat << 'EOM'
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi
EOM
}

function make_script_fzfable() {
  echo "${BASH_FZF_IN_SOURCED_SCRIPT}"
}

function common_footer_for_scripts() {
  echo "${BASH_COMMON_SCRIPT_FOOTER}"
}

function ffbashcode() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

