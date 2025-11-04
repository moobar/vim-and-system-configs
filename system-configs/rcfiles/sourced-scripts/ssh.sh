#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

# shellcheck disable=SC2009
function ssh-agent-start-or-attach() {
  local SSH_AUTH_SOCK_LOCAL=
  local SSH_AGENT_PID_LOCAL=
  local SSH_PROCESSES=

  # Check if there are too many ssh-agents

  SSH_PROCESSES="$(ps auxwww | grep ssh-agent | grep -c -Fv grep)"
  if [[ $SSH_PROCESSES -gt 1 ]]; then
    echo "Too many ssh-agents"
    if yn_prompt "Kill and try again?"; then
      ps auxwww | grep ssh-agent | grep -Fv grep | awk '{print $2}' | xargs kill
    else
      echo Run: 'ps auxwww | grep ssh-agent | grep -Fv grep'
    fi
  fi

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

