#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function get_git_root_of_script() {
  cat << 'EOM'
"$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null)"
EOM
}

function get_cwd_of_script() {
  cat << 'EOM'
"$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
EOM
}

function dont-source-script() {
  cat << 'EOM'
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi
EOM
}

function robust-while-loop() {
  cat << 'EOM'
  echo "This reads in a file, handles when the file has no newline at the end and puts it in FD 3 to avoid STDIN conflicts"
  echo "  -----  "
  while read -r line || [[ -n "$line" ]] <&3; do
    k="$(awk -F '=' '{print $1}' <<< "${line}")"
    if [[ "${k,,}" == "${KEY,,}" ]]; then
      cut -d '=' -f2- <<< "${line}"
      return 0
    fi
  done 3< "${FILE}"
  return 1
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

