#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function ssh-agent-start-or-attach() {
  local SSH_AUTH_SOCK_LOCAL=
  local SSH_AGENT_PID_LOCAL=
  if ! SSH_AGENT_PID_LOCAL="$(pgrep ssh-agent)"; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
  else
    #SSH_AUTH_SOCK_LOCAL="$(find /var/folders 2>/dev/null | grep "ssh.*agent.*${SSH_AGENT_PID}\$")"
    SSH_AUTH_SOCK_LOCAL="$(find /var/folders 2>/dev/null | grep -E "ssh.*agent.*\d+$")"
    SSH_AUTH_SOCK="$SSH_AUTH_SOCK_LOCAL"
    SSH_AGENT_PID="$SSH_AGENT_PID_LOCAL"
    export SSH_AUTH_SOCK
    export SSH_AGENT_PID
  fi
}

function ssh-agent-add() {
  ssh-add "$(find ~/.ssh/ | grep -Ev '\/$|\.pub$|known_hosts$|config$')"
}

function ssh-agent-list() {
  ssh-add -l
}

function ffssh() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

