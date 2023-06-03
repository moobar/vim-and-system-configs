#!/bin/bash

## Fzf finder for all available vim-tooling functions
function ffocaml() {
  function _send_keys_to_terminal() {
    local KEYS='' CHOICES='' CHOICE='' SRC_DIR_LOCAL=''
    KEYS=${1}

    bind "\C-^":redraw-current-line
    if [[ -z "$TMUX" ]]; then
      Command to run: "${KEYS}"
    else
      tmux send-keys -t "${TMUX_PANE}" "${KEYS}" C-^
    fi
  }

  if [[ -z $1 ]]; then
    SRC_DIR_LOCAL="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
  else
    SRC_DIR_LOCAL="${1}"
  fi
  # tac $(grep -h '^function compile-workspace' * -l --color=none) | sed -n '/^function compile-workspace/,/^ *$/p' | sed '/^ *$/d' | tail -n +2 | tac
  CHOICES=$(grep -h '^function' "${SRC_DIR_LOCAL}/"* | cut -d' ' -f2 | grep -v '^_' | tr -d ')(}{ ' | grep -v '^ff$' | sort | uniq)
  CHOICE=$(echo "${CHOICES}" | fzf --reverse --preview-window=up:wrap  --preview="echo {} | xargs -I}{ grep -E -l '^function }{[ ({]+' ${SRC_DIR_LOCAL}/* | xargs -n1 tac | sed -E -n '/^function {}[ ({]+/,/^ *$/p' | sed '/^ *$/d' | tail -n +2 | tac")

  _send_keys_to_terminal "${CHOICE}"
}
