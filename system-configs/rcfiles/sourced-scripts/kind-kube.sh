#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

# Useful: https://kind.sigs.k8s.io/docs/user/quick-start/

function _verify_kube_kind_context()
{
  if [[ "$(kubectl config current-context)" != "kind-"* ]]; then
    echo "Only run this when auth'd to a local kind cluster. Cluster most be prefixed with 'kind-'"
    return 1
  else
    return 0
  fi
}

function kind-create-cluster()
{
  if [[ $# -lt 1 ]]; then
    echo "Usage: ${FUNCNAME[0]} <Cluster_Name> [Host_Port]"
    return 1
  fi

  local CLUSTER_NAME="${1}"
  local HOST_PORT=

  if [[ -n $2 ]]; then
    HOST_PORT="$(cat <<EOM
  - containerPort: 80
    hostPort: ${2}
EOM
# Also maybe add?
# listenAddress: "127.0.0.1"
)"
  fi

  kind create cluster --name "${CLUSTER_NAME}" --config= <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
${HOST_PORT}
  - containerPort: 80
    hostPort: 10080
    listenAddress: "127.0.0.1"
  extraMounts:
  - hostPath: "${HOME}"/.docker/
    containerPath: /docker/
    readOnly: true
- role: worker
- role: worker
EOF

}

function make-docker-creds-for-kind ()
{
  local DOMAIN=
  local DOCKER_CREDS=
  local DOCKER_CREDS_B64=

  if ! _verify_kube_kind_context; then
      return 1
  fi

  if [[ -z $1 ]]; then
      DOMAIN="us-docker.pkg.dev"
  else
      DOMAIN="$1"
  fi

  DOCKER_CREDS="gclouddockertoken:$(gcloud auth print-access-token)"
  DOCKER_CREDS_B64="$(base64 <<< "${DOCKER_CREDS}")"

  cat <<EOM > temp-docker.config
{
  "auths": {
    "${DOMAIN}": {
      "auth": "${DOCKER_CREDS_B64}",
      "email": "not@val.id"
    }
  }
}
EOM

  kubectl create secret generic regcred \
    --from-file=.dockerconfigjson="temp-docker.config" \
    --type=kubernetes.io/dockerconfigjson

  rm temp-docker.config
}

function kind-delete-cluster()
{
  kind delete cluster "$@"
}

function kind-get-clusters ()
{
  kind get clusters "$@"
}

function kind-list-clusters()
{
  kind-get-clusters "$@"
}

function kind-verify-docker-creds()
{
  if ! _verify_kube_kind_context; then
    return 1
  fi
  kubectl get secret regcred -o=yaml | yq '.data.".dockerconfigjson"' | base64 -d
}

function ffkind() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

