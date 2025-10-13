#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function _gpt_prereq() {
  if ! gh models &>/dev/null; then
    if yn_prompt 'Run [gh extension install github/gh-models]?'; then
      gh extension install github/gh-models
      return
    else
      return 1
    fi
  fi
}

function ask-gpt4o() {
  if ! _gpt_prereq; then
    return
  fi

  gh models run openai/gpt-4o --system-prompt \
    "You are an AI embedded into a terminal of a MacOS computer. Since the questions will be mostly about coding, terminals, etc. Be concise in your answers. Do not use markdown (since it doesn't show up in the terminal)" \
    "$*"
}

# Default
function ask-gpt() {
  ask-gpt4o "$@"
}

function ask-llm() {
  llm --system \
    "You are an AI embedded into a terminal of a MacOS computer. Since the questions will be mostly about coding, terminals, etc. Be concise in your answers. Do not use markdown (since it doesn't show up in the terminal)" \
    "$*"
}

#function ask-gpt5() {
#  if ! _gpt_prereq; then
#    return
#  fi
#
#  gh models run openai/gpt-5 --system-prompt \
#    "You are an AI embedded into a terminal of a MacOS computer. Since the questions will be mostly about coding, terminals, etc. Be concise in your answers. Do not use markdown (since it doesn't show up in the terminal)" \
#    "$*"
#}

function ffgpt() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

