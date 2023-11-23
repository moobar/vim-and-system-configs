#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function docker-mapped-port() {
  # Check if anything is in stdin
  if test ! -t 0; then
    cat \
      | grep -Eo '0.0.0.0:[0-9]+' \
      | cut -d: -f2
  else
    if [[ -z "${1}" ]]; then
      echo "Expecting input from pipe or grep pattern"
      return 1
    fi

    # shellcheck disable=SC2002
    docker ps \
      | grep "$1" \
      | grep -Eo '0.0.0.0:[0-9]+' \
      | cut -d: -f2
  fi
}

function docker-grep() {
  local SEARCH_PATTERN=
  if test ! -t 0; then
    SEARCH_PATTERN="$(cat)"
  else
    if [[ -z "${1}" ]]; then
      echo "Expecting input from pipe or grep pattern"
      return 1
    fi
    SEARCH_PATTERN="$1"
  fi
  docker ps | grep -i "${SEARCH_PATTERN}" | awk '{print $1}'
}

function docker-kill() {
  docker kill "$(docker-grep "$@")"
}

function docker-exec() {
  if docker exec -it "$(docker-grep amicus)" /bin/ls /bin/bash &>/dev/null; then
    docker exec -it "$(docker-grep "$@")" /bin/bash
  else
    docker exec -it "$(docker-grep "$@")" /bin/sh
  fi
}

function ffdocker() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

