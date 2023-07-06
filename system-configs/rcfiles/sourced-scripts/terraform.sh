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

function parse-project() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --prod|--production)
        if [[ -n "${GCP_PROD}" ]]; then
          echo "${GCP_PROD}"
          return 0
        else
          break
        fi
        ;;
      --stage|--staging)
        if [[ -n "${GCP_STAGE}" ]]; then
          echo "${GCP_STAGE}"
          return 0
        else
          break
        fi
        ;;
      --dev|--development)
        if [[ -n "${GCP_DEV}" ]]; then
          echo "${GCP_DEV}"
          return 0
        else
          break
        fi
        ;;
      --project)
        if [[ -n "${2}" ]]; then
          echo "${2}"
          return 0
        else
          break
        fi
        ;;
      --project=*)
        echo "${1#*=}"
        return 0
        ;;
      *)
        shift # past argument
        ;;
    esac
  done

  # shellcheck disable=SC2005
  echo "$(gcloud config get project)"
  return 0
}

function get-tf-resource() {
  # Check if anything is in stdin
  if test ! -t 0; then
    cat \
      | grep '^resource' \
      | tr ' ' '.' \
      | tr -d '}{"' \
      | sed -E 's/\.$|^resource\.//g' \
      | fzf
  else
    if [[ -z "${1}" ]]; then
      echo "Expecting input from pipe or a file"
      return 1
    fi

    # shellcheck disable=SC2002
    cat "$1" \
      | grep '^resource' \
      | tr ' ' '.' \
      | tr -d '}{"' \
      | sed -E 's/\.$|^resource\.//g' \
      | fzf
  fi
}

function fftf() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

