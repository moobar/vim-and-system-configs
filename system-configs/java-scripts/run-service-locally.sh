#!/bin/bash

(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi

set -e

function debugEnabledFlag() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --debug)
        echo "true"
        return 0
        ;;
      *)
        shift # past argument
        ;;
    esac
  done

  echo "false"
  return 0
}

function repo-name() {
    basename -s .git "$(git config --get remote.origin.url)"
}


function get-app-version() {
    xq -x '/project/version' "$(git rev-parse --show-toplevel)/pom.xml"
}

function extract-env-vars() {
  local file=$1
  local container_name=$2

  if [[ -z "$file" || -z "$container_name" ]]; then
    echo "Usage: extract-env-vars <file> <container_name>"
    return 1
  fi

  # Don't include DD and use local GOOGLE creds
  yq e \
    ".spec.template.spec.containers[] | select(.name == \"$container_name\") | .env[] | \"export \(.name)=\\\"\(.value // .valueFrom.fieldRef.fieldPath // .valueFrom.secretKeyRef.key)\\\"\"" "$file" \
    | grep -Fv DD_  \
    | grep -Fv GOOGLE_APPLICATION_CREDENTIALS \
    | grep -Fv JAVA_OPTS
}

function production-deployments() {
  local dir=$1

  if [[ -z "$dir" ]]; then
    echo "Usage: production-deployments <directory>"
    return 1
  fi

  for file in "$dir"/*production*.y*ml; do
    if yq e -e 'select(.kind == "Deployment")' "$file" &> /dev/null; then
      echo "$file"
    fi
  done
}

function staging-deployments() {
  local dir=$1

  if [[ -z "$dir" ]]; then
    echo "Usage: staging_deployments <directory>"
    return 1
  fi

  for file in "$dir"/*staging*.y*ml; do
    if yq e -e 'select(.kind == "Deployment")' "$file" &> /dev/null; then
      echo "$file"
    fi
  done
}

function clean-compile-repo() {
  (
    if [[ ${BUILD:-false} == "true" ]]; then
      cd "$(git rev-parse --show-toplevel)" || return
      mvn clean install -DskipTests -Ddockerfile.skip=true
    fi
  )
}
function compile-repo() {
  (
    cd "$(git rev-parse --show-toplevel)" || return
    mvn install -DskipTests -Ddockerfile.skip=true
  )
}

function set-staging() {
  local KUBE_DIR=
  KUBE_DIR="$(git rev-parse --show-toplevel)/kube"
  GCP_TAG="$(get-app-version)"
  export GCP_TAG
  export ENVIRONMENT=tidal-nova-135821
  export GCP_PROJECT_ID=tidal-nova-135821
  export GCP_NODE_ENV=staging

  # shellcheck disable=SC1090
  source <(extract-env-vars "$(staging-deployments "${KUBE_DIR}" | tail -1)" "$(repo-name)")
}

function run-locally() {
  local TARGET_DIR=
  local SERVICE_MAIN=
  # shellcheck disable=SC2116
  TARGET_DIR=$(echo "$(git rev-parse --show-toplevel)/server/target")
  SERVICE_MAIN=$(grep SERVICE_MAIN "$(git rev-parse --show-toplevel)/server/Dockerfile" | cut -d= -f2 | tr -d '"')

  clean-compile-repo

  if [[ "$(debugEnabledFlag "$@")" == "true" ]]; then
    export JAVA_TOOL_OPTIONS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:7777'
  fi

  # shellcheck disable=SC2086
  java \
    -cp "${TARGET_DIR}/lib/*:${TARGET_DIR}/*" \
    "${SERVICE_MAIN}"
}

function run-staging() {
  (
    set-staging
    run-locally "$@"
  )
}

if [[ -z ${1-""} ]]; then
  echo "Usage: bash ${BASH_SOURCE[0]} [FUNCTION]"
  echo "To see available functions run:"
  echo "bash ${BASH_SOURCE[0]} fzf"
  exit 1
else
  FUNCTION="$1"
fi

if declare -f "$FUNCTION" > /dev/null; then
  unset FUNCTION
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  echo "Usage: bash ${BASH_SOURCE[0]} [FUNCTION]"
  exit 1
fi

