#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

## Only run this script when on OSX
if [[ $(uname -s) != "Linux" ]]; then
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

## [strace-all CMD] -> Alias
#  Given a [CMD] of an app. Strace all the useful syscalls
function strace-all() {
  strace -f -s1000000 "${@}"
}

## [strace-read-and-network CMD] -> Alias
#  Given a [CMD] show file reads and network connections
function strace-read-and-network() {
  strace -f -e trace=open,openat,close,read,stat,getdents,write,connect,send,sendto,recv,recvfrom,accept -s1000000 "${@}"
}

function fflinux() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

