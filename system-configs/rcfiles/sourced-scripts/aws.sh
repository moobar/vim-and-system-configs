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

function parse-aws-project() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --prod|--production)
        if [[ -n "${AWS_PROD}" ]]; then
          echo "${AWS_PROD}"
          return 0
        else
          break
        fi
        ;;
      --stage|--staging)
        if [[ -n "${AWS_STAGE}" ]]; then
          echo "${AWS_STAGE}"
          return 0
        else
          break
        fi
        ;;
      --dev|--development)
        if [[ -n "${AWS_DEV}" ]]; then
          echo "${AWS_DEV}"
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
  # TODO fix this
  # Also maybe this just doesn't work
  return 0
}

## [aws]  ->  Alias
#  runs aws cli, but ensures a profile is set
#  use command aws to run it without a profile
function aws() {
  if [[ -z "$AWS_PROFILE" ]]; then
    # shellcheck disable=SC2016
    echo 'Must set $AWS_PROFILE first'
    echo 'Use: [faws-set-profile]'
    return 1
  fi

  command aws "$@"
}

function aws-list-profiles() {
  aws configure list-profiles "$@"
}


function aws-eks-list-clusters() {
  aws eks list-clusters "$@"
}

function aws-eks-update-kubeconfig() {
  aws eks update-kubeconfig "$@"
}

function aws-describe-instances() {
  # shellcheck disable=SC2016
  aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].{ID:InstanceId, Type:InstanceType, State:State.Name, Name:Tags[?Key==`Name`].Value | [0]}' \
    --output table
}

function faws-eks-update-kubeconfig() {
  local CLUSTER_NAME=""
  if CLUSTER_NAME="$(aws eks list-clusters  | jq -r '.clusters[]' | fzf)" && [[ -n "$CLUSTER_NAME" ]]; then
    echo "Authing to: ${CLUSTER_NAME}"
  else
    echo "No profile selected"
    return 1
  fi
  aws eks update-kubeconfig --name "${CLUSTER_NAME}" "$@"
}

function faws-set-profile() {
  local PROFILE=""
  if PROFILE="$(command aws configure list-profiles  | grep -Fv default | fzf)" && [[ -n "$PROFILE" ]]; then
    export AWS_PROFILE="${PROFILE}"
  else
    echo "No profile selected"
    return 1
  fi
}

function ffaws() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

