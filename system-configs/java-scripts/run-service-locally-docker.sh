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
    ".spec.template.spec.containers[] | select(.name == \"$container_name\") | .env[] | \"echo \(.name)=\\\"\(.value // .valueFrom.fieldRef.fieldPath // .valueFrom.secretKeyRef.key)\\\"\"" "$file" \
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

function get-staging-env() {
  (
    local KUBE_DIR=
    KUBE_DIR="$(git rev-parse --show-toplevel)/kube"
    GCP_TAG="$(get-app-version)"
    export GCP_TAG
    export ENVIRONMENT=tidal-nova-135821
    export GCP_PROJECT_ID=tidal-nova-135821
    export GCP_NODE_ENV=staging

    # shellcheck disable=SC1090
    eval "$(extract-env-vars "$(staging-deployments "${KUBE_DIR}" | tail -1)" "$(repo-name)")"
  )
}

function kube-deploy-cloud-arm-image() {
  echo "kube-deploy-cloud-arm:local-runner"
}

function local-docker-image() {
  echo "local-$(repo-name)-arm:server"
}

function build-kube-deploy-cloud-arm() {
  (
    mkdir -p /tmp/local-build
    cd /tmp/local-build || return
    git clone git@github.com:finco-services/kube-deploy.git
    cd /tmp/local-build/kube-deploy || return

    # This git switch is temporary until i get the pr checked in
    git switch add-instrumentation-support-for-mongo-in-later-jdks

    docker build -t "$(kube-deploy-cloud-arm-image)" -f kube-deploy-cloud/Dockerfile .
    rm -rf /tmp/local-build/kube-deploy
  )
}

function build-server-docker-image() {
  (
    build-kube-deploy-cloud-arm
    SERVER_DIR="$(git rev-parse --show-toplevel)/server"
    #clean-compile-repo
    sed "s|FROM.*|FROM $(kube-deploy-cloud-arm-image)|" "${SERVER_DIR}/Dockerfile" > "${SERVER_DIR}/Dockerfile.local"
    docker build --build-arg JAR_FILE="server-$(get-app-version).jar" -t "$(local-docker-image)" -f "${SERVER_DIR}/Dockerfile.local" "${SERVER_DIR}"
    rm "${SERVER_DIR}/Dockerfile.local"
  )
}

function run-server-docker-image-bash() {
  if [[ -z "$(docker image ls --quiet "$(local-docker-image)")" ]]; then
    clean-compile-repo
    build-server-docker-image
  fi
  docker run -v ~/.config/gcloud/:/root/.config/gcloud -v ~/.ssh:/root/.ssh -p 8080:8080 --env-file <(get-staging-env) -it --entrypoint /bin/bash "$(local-docker-image)"
}

function run-server-docker-image() {
  if [[ -z "$(docker image ls --quiet "$(local-docker-image)")" ]]; then
    clean-compile-repo
    build-server-docker-image
  fi
  docker run -v ~/.config/gcloud/:/root/.config/gcloud -v ~/.ssh:/root/.ssh:ro -p 8080:8080 --env-file <(get-staging-env) -it "$(local-docker-image)"
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


