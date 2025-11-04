#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

# Useful: https://helm.sh/docs/topics/chart_tests/
#         https://helm.sh/docs/topics/charts/
#         https://helm.sh/docs/intro/using_helm/
#         https://helm.sh/docs/intro/cheatsheet/

function helm-build-locally() {
  local HELM_WORKING_DIR=
  local HELM_WORKING_DIR_NAME=
  if [[ -z $1 ]]; then
    echo "Usage: ${FUNCNAME[0]} LOCAL_WORKING_DIR [ARGS...]"
    return 1
  fi

  if [[ "$1" == '-'* ]]; then
    echo "Don't provide -options until after the first positional argument"
    echo "Usage: ${FUNCNAME[0]} LOCAL_WORKING_DIR [ARGS...]"
    return 1
  fi

  HELM_WORKING_DIR="$1"; shift;

  # Build the chart locally:
  set -x
  helm dependency build "${HELM_WORKING_DIR}" "$@"
  set +x
}

function helm-build-and-install-locally() {
  local HELM_WORKING_DIR=
  local HELM_WORKING_DIR_NAME=
  local HELM_CHART_INSTANCE=
  if [[ -z $2 ]]; then
    echo "Usage: ${FUNCNAME[0]} <INSTALL_NAME> <LOCAL_WORKING_DIR> <ARGS...>"
    return 1
  fi

  if [[ "$1" == '-'* || "$2" == '-'* ]]; then
    echo "Don't provide -options until after the first two positional arguments"
    echo "Usage: ${FUNCNAME[0]} <INSTALL_NAME> <LOCAL_WORKING_DIR> <ARGS...>"
    return 1
  fi

  HELM_CHART_INSTANCE="$1"; shift;
  HELM_WORKING_DIR="$1"; shift;

  # Build the chart locally:
  set -x
  helm dependency build "${HELM_WORKING_DIR}"
  # helm install "${HELM_CHART_INSTANCE}" "${HELM_WORKING_DIR}" "$@"
  # Apparently upgrade -i will upgrade or install, and it's what we do in our github actions
  helm upgrade -i "${HELM_CHART_INSTANCE}" "${HELM_WORKING_DIR}" "$@"
  set +x
}

function fhelm-get-release-name() {
  helm list | fzf --accept-nth 1 --header-lines=1
}

function helm-list-by-name-flag() {
  local HELM_CHART_NAME=
  if [[ -z $1 ]]; then
    HELM_CHART_NAME="$(fhelm-list-and-get-name)"
  else
    HELM_CHART_NAME="$1"
  fi


  # shellcheck disable=SC2005
  echo "$(cat <<EOM
-l "app.kubernetes.io/name=${HELM_CHART_NAME}"
EOM
  )"
}

function helm-list-by-instance-flag() {
  local HELM_INSTANCE_NAME=
  if [[ -z $1 ]]; then
    echo "Must provide INSTANCE as first (and only) arg"
    return 1
  fi
  HELM_INSTANCE_NAME="$1"

  # shellcheck disable=SC2005
  echo "$(cat <<EOM
-l "app.kubernetes.io/instance=${HELM_INSTANCE_NAME}"
EOM
  )"
}

function helm-get-pods-by-instance() {
  local HELM_INSTANCE_NAME=
  if [[ -z $1 ]]; then
    echo "Usage: ${FUNCNAME[0]} INSTANCE_NAME [other_kubectl_get_pods_flags...]"
    return 1
  fi

  if [[ "$1" == '-'* ]]; then
    echo "Don't provide -options until after the first positional argument"
    echo "Usage: ${FUNCNAME[0]} INSTANCE_NAME [other_kubectl_get_pods_flags...]"
    return 1
  fi

  HELM_INSTANCE_NAME="$1"; shift;

  kubectl get pods \
    -l "app.kubernetes.io/instance=${HELM_INSTANCE_NAME}" \
    -o jsonpath="{.items[0].metadata.name}" \
    "$@"
  echo ""
}

function fhelm-get-pods-by-instance() {
  local HELM_INSTANCE_NAME=
  HELM_INSTANCE_NAME="$(fhelm-list-and-get-name)"

  if [[ -n "$HELM_INSTANCE_NAME" ]]; then
    kubectl get pods \
      -l "app.kubernetes.io/instance=${HELM_INSTANCE_NAME}" \
      -o=json \
      "$@" \
      | jq -r '.items[0].metadata.name'
  fi
}

function ffhelm() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

