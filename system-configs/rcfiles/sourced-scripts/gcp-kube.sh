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

## [gcloud-set-stage]  ->  Alias
# Set project config to staging
function gcloud-set-stage() {
  gcloud config set project "${GCP_STAGE}"
}

## [gcloud-set-prod]  ->  Alias
# Set project config to prod
function gcloud-set-prod() {
  gcloud config set project "${GCP_PROD}"
}

## [gcloud-auth]  ->  Shorthand
#  Use gcloud principal to authenticate to the cli and with local app developement (application-default)
function gcloud-auth() {
  gcloud auth login
  gcloud auth application-default login
}

## [gcloud-unset-service-account]  ->  Shorthand
#  Unset service account
function gcloud-unset-service-account() {
  gcloud config unset auth/impersonate_service_account
}

## [gcloud-get-service-account]  ->  Shorthand
#  Gets service account, if set
function gcloud-get-service-account() {
  local SERVICE_ACCOUNT=
  SERVICE_ACCOUNT="$(gcloud config get auth/impersonate_service_account  2> /dev/null)"
  if [[ -z $SERVICE_ACCOUNT ]]; then
    return 1
  else
    echo "${SERVICE_ACCOUNT}"
    return 0
  fi
}

## [gcloud-active-account]  ->  Shorthand
#  Displays the active account that gcp is auth'd to
function gcloud-active-account() {
  gcloud auth list --format=json | jq -r '.[] | select(.status == "ACTIVE") | .account'
}

## [gcloud-whoami]  ->  Shorthand
#  Displays the principal in use. Will first check if is a service account
function gcloud-whoami() {
  local SERVICE_ACCOUNT=
  if ! SERVICE_ACCOUNT="$(gcloud-get-service-account)"; then
    gcloud-active-account
  else
    echo "${SERVICE_ACCOUNT}"
  fi
}

## [docker-auth]  ->  Shorthand
#  use gloud princpal to authenticate to https://us.gcr.io via the gcloud cli + docker cli
function docker-auth() {
  gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://us.gcr.io
}

## [gcloud-config]  ->  Alias
#  List current gcloud config
function gcloud-config() {
  gcloud config list
}

## [gcloud-projects] | Cache enabled | ->  Alias
#  List all the projects for the GCP instance you're authenticated to
function gcloud-projects() {
  cache_command \
    -d "gcloud-global" \
    -f "${FUNCNAME[0]}" \
    -x 'gcloud projects list '
}

## [gcloud-container-clusters] | Cache enabled | ->  Alias
#  List all the GKE clusters in the current working project
function gcloud-container-clusters() {
  local PROJECT=
  PROJECT="$(parse-project "$@")"
  cache_command \
    -d "${PROJECT}" \
    -f "${FUNCNAME[0]}" \
    -x "gcloud container clusters list --project=${PROJECT}"
}

## [gcloud-compute-instances] | Cache enabled | ->  Alias
#  List all the compute in the current working project
function gcloud-compute-instances() {
  local PROJECT=
  PROJECT="$(parse-project "$@")"
  cache_command \
    -d "${PROJECT}" \
    -f "${FUNCNAME[0]}" \
    -x "gcloud compute instances list --sort-by=name --project=${PROJECT}"
}

## [gcloud-build-list] -> Alias
#  List the last 500 builds
function gcloud-build-list() {
  gcloud beta builds list \
    --format="table(substitutions.REPO_NAME, substitutions.BRANCH_NAME, status, id, substitutions.SHORT_SHA)" \
    --limit=500 \
    --page-size=500
}

## [gcloud-compute-instances]  ->  Alias
#  Helper command to search gcloud logs
#  DEFAULT ARGS:  --limit=10000 --freshness=1d
#  ARGS:          Can pass any other [gcloud logging read] args
function gcloud-log-search() {
  local PROJECT
  PROJECT="$(parse-project "$@")"
  local LIMIT=10000 FRESHNESS=1d
  local UNUSED_ARGS=()

  while [[ $# -gt 0 ]]; do
    case $1 in
      --limit=*)
        LIMIT="${1#*=}"
        shift
        ;;
      --freshness=*)
        FRESHNESS="${1#*=}"
        shift
        ;;
      # These are handled by parse-project
      --prod|--production|--stage|--staging|--dev|--development|--project=)
        shift
        ;;
      *)
        UNUSED_ARGS+=("$1")
        shift
        ;;
    esac
  done
  set -- "${UNUSED_ARGS[@]}"

  gcloud logging read --format=json --project="${PROJECT}" --limit="${LIMIT}" --freshness="${FRESHNESS}" "$@"
}

## [ssh-gcloud <gcloud compute ssh ARGS>]  ->  Alias
#  Runs [gcloud compute ssh] and makes sure it always adds the
#    [--tunnel-trhgouh-iap] flag
function ssh-gcloud() {
  local FIRST_THREE=("${@:1:3}")
  if [[ "${FIRST_THREE[*]}" == "gcloud compute ssh" ]]; then
    set -- "${@:4}"
  fi

  local arg
  for arg do
    shift
    case $arg in
      (--tunnel-through-iap) : ;;
        (*) set -- "$@" "$arg" ;;
    esac
  done

  gcloud compute ssh --tunnel-through-iap "$@"
}

## [fgcloud-projects]  ->  Shorthand
#  Calls [gcloud-projects] and pipes it to fzf
function fgcloud-projects() {
  gcloud-projects | fzf --tac --header-lines=1
}

## [fgcloud-container-clusters]  ->  Shorthand
#  Calls [gcloud-container-clusters] and pipes it to fzf, with the project name
function fgcloud-container-clusters() {
  local PROJECT
  PROJECT="$(parse-project "$@")"
  gcloud-container-clusters --project "${PROJECT}" | fzf --tac --header-lines=1 --header="  [project: ${PROJECT}]"
}

## [fgcloud-compute-instances]  ->  Shorthand
#  Calls [gcloud-compute-instances] and pipes it to fzf, with the project name
function fgcloud-compute-instances() {
  local PROJECT
  PROJECT="$(parse-project "$@")"
  gcloud-compute-instances --project "${PROJECT}" | fzf --tac --header-lines=1 --header="  [project: ${PROJECT}]"
}

## [fgcloud-set-project]
#  Sets the project via a fzf window with all the projects.
#
#  RETURNS  ->
#    Calls [gcloud config set project] on project selected from the fzf windows
function fgcloud-set-project() {
  local PROJECT=
  PROJECT=$(fgcloud-projects | awk '{print $1}')
  if [[ -z $PROJECT ]]; then
    return 0
  fi

  local CMD=
  # shellcheck disable=SC2116
  CMD=$(echo gcloud config set project "${PROJECT}")

  if [[ -n $CMD ]]; then
    echo Running: "${CMD}"
    ${CMD}
  fi
}

## [fgcloud-get-cluster-creds]
#  Gets credentials for a GKE cluster after picking from a fzf window with all the GKE clusters
#  This command is project specific
#
#  RETURNS  ->
#    Calls [gcloud container clusters get-credentials] on the selected GKE cluster
function fgcloud-get-cluster-creds() {
  local CLUSTER=
  local CLUSTER_NAME=
  local CLUSTER_ZONE=
  local PROJECT=
  PROJECT="$(parse-project "$@")"
  CLUSTER=$(fgcloud-container-clusters --project "${PROJECT}")
  if [[ -z $CLUSTER ]]; then
    return 0
  fi

  CLUSTER_NAME=$(awk '{print $1}' <<< "${CLUSTER}")
  CLUSTER_ZONE=$(awk '{print $2}' <<< "${CLUSTER}")

  local CMD
  # shellcheck disable=SC2116
  CMD=$(echo gcloud container clusters get-credentials "${CLUSTER_NAME}" --zone="${CLUSTER_ZONE}" --project="${PROJECT}")

  if [[ -n $CMD ]]; then
    echo Running: "${CMD}"
    ${CMD}
  fi
}

## [fgcloud-get-deployment-cluster-creds]
#  Gets credentials for a GKE cluster after picking from a fzf window with all the GKE deployments
#  This command is project specific
#
#  RETURNS  ->
#    Calls [gcloud container clusters get-credentials] on the selected GKE cluster associated with the deployment
function fgcloud-get-deployment-cluster-creds() {
  local CLUSTER_NAME=
  local CLUSTER_ZONE=
  local PROJECT=
  PROJECT="$(parse-project "$@")"
  CLUSTER_NAME=$(fkubectl-get-deployment --project "${PROJECT}" | awk '{print $1}')
  if [[ -z $CLUSTER_NAME ]]; then
    return 0
  fi

  CLUSTER_ZONE=$(gcloud-container-clusters --project "${PROJECT}" | grep "${CLUSTER_NAME}" | awk '{print $2}')

  local CMD
  # shellcheck disable=SC2116
  CMD=$(echo gcloud container clusters get-credentials "${CLUSTER_NAME}" --zone="${CLUSTER_ZONE}" --project="${PROJECT}")

  if [[ -n $CMD ]]; then
    echo Running: "${CMD}"
    ${CMD}
  fi
}

## [fgcloud-ssh <gcloud compute ssh ARGS>]
#  Pulls up all the compute on the current working project and ssh's to the selected one
#
#  ARGS      = Any args that are available from the [gcloud compute ssh] command
#  RETURNS  ->
#    ssh connection to the selected GCP compute
function fgcloud-ssh() {
  local INSTANCE=
  local INSTANCE_NAME=
  local INSTANCE_ZONE=
  local PROJECT=
  PROJECT="$(parse-project "$@")"
  INSTANCE=$(fgcloud-compute-instances --project "${PROJECT}")
  if [[ -z $INSTANCE ]]; then
    return 0
  fi

  # interestingly [for arg; do] is equivalent [for arg in "$@"; do]
  for arg in "$@"; do
    shift
    case $arg in
      --prod|--production)
        ;;
      --stage|--staging)
        ;;
      --dev|--development)
        ;;
      --project)
        ;;
      *)
        set -- "$@" "$arg"
        ;;
    esac
  done

  INSTANCE_NAME=$(awk '{print $1}' <<< "${INSTANCE}")
  INSTANCE_ZONE=$(awk '{print $2}' <<< "${INSTANCE}")

  local CMD
  # shellcheck disable=SC2116
  CMD=$(echo gcloud compute ssh --tunnel-through-iap --zone "${INSTANCE_ZONE}" --project "${PROJECT}" "${INSTANCE_NAME}")

  echo Running: "${CMD}" "$@"
  ${CMD} "$@"
}

## [fssh-gcloud <gcloud compute ssh ARGS>]   ->  Alias
#  Alias for fgcloud-ssh
#
#  ARGS      = Any args that are available from the [gcloud compute ssh] command
#  RETURNS  ->
#    ssh connection to the selected GCP compute
function fssh-gcloud() {
  fgcloud-ssh "$@"
}

## [kubectl-event-logs]  ->  Alias
#  Print out all GKE event logs for current working GKE cluster
function kubectl-event-logs() {
  kubectl get events --sort-by='.lastTimestamp' -w
}

## [kubectl-get-cluster-deployment] | Cache enabled
#  Print out all of the GKE deployments (workloads) for a given cluster.
#  This function will get the cluster credentials, if it's not authenticated
#  By default the output is cached for 10 hours.
#
#  Args:
#    -c|--cluster [CLUSTER_NAME]  Cluster to get deployment information from
#  Options:
#    -t|--ttl      [SECONDS]       Max seconds to cache (default 36000)
#    -p|--project  [PROJECT_NAME]  GCP Project, (defaults to $(cloud config get project))
#
#  Example:
#    kubectl-get-cluster-deployment \
#      -c cluster_name \
#      -p my_project
function kubectl-get-cluster-deployment() {
  local CLUSTER_INFO=
  local TTL=36000
  local PROJECT=
  local UNUSED_ARGS=()

  PROJECT="$(parse-project "$@")"
  while [[ $# -gt 0 ]]; do
    case $1 in
      -c|--cluster)
        CLUSTER_INFO="$2"
        shift
        shift
        ;;
      -t|--ttl)
        TTL="$2"
        shift
        shift
        ;;
      -p|--project)
        PROJECT="$2"
        shift
        shift
        ;;
      -|--help)
        echo "Usage: ${FUNCNAME[0]} <-c CLUSTER> [-p PROJECT] [-t TTL]"
        return 1
        ;;
      *)
        UNUSED_ARGS+=("$1")
        shift
        ;;
    esac
  done
  set -- "${UNUSED_ARGS[@]}"

  if [[ -z $CLUSTER_INFO ]]; then
    echo "Usage: ${FUNCNAME[0]} <-c CLUSTER> [-p PROJECT] [-t TTL]"
    return 1
  fi


  local GCLOUD_CLUSTER=
  local CLUSTER_ZONE=
  local GKE_CLUSTER=

  GCLOUD_CLUSTER=$(awk '{print $1}' <<< "${CLUSTER_INFO}")
  CLUSTER_ZONE=$(awk '{print $2}' <<< "${CLUSTER_INFO}");
  GKE_CLUSTER=$(awk -v project="${PROJECT}" '{printf "gke_%s_%s_%s\n", project, $2, $1}' <<< "${CLUSTER_INFO}")

#  if ! kubectl config get-clusters | grep -q "${GKE_CLUSTER}" >/dev/null 2>&1 ; then
#    gcloud container clusters get-credentials "${GCLOUD_CLUSTER}" --zone="${CLUSTER_ZONE}" --project="${PROJECT}" >/dev/null 2>&1
#  fi

  CMD=$(cat<<EOM
(
  if [[ ! -d ~/.kube ]]; then
    mkdir -p ~/.kube
  fi
  export KUBECONFIG=~/.kube/config-workloads
  gcloud container clusters get-credentials "${GCLOUD_CLUSTER}" --zone="${CLUSTER_ZONE}" --project="${PROJECT}" >/dev/null 2>&1
  kubectl get cronjobs.batch --cluster="${GKE_CLUSTER}" --all-namespaces 2>/dev/null
  kubectl get daemonsets.apps --cluster="${GKE_CLUSTER}" --all-namespaces 2>/dev/null
  kubectl get deployments --cluster="${GKE_CLUSTER}" --all-namespaces 2>/dev/null
  kubectl get statefulsets.apps --cluster="${GKE_CLUSTER}" --all-namespaces 2>/dev/null
)
EOM
  )

  cache_command \
    --ttl "${TTL}"\
    -d "${PROJECT}" \
    -f "${FUNCNAME[0]}-${GCLOUD_CLUSTER}" \
    -x "${CMD}"
}

#  TODO(sagar): for some reason the I can't see the datadog deployments when i do -n datadog for challenger in staging

## [kubectl-get-deployments]
#  Finds all GKE clusters in the current working project and prints the deployments for each cluster
#    Google calls deployments [Workloads]
#
#  RETURNS  ->
#    Table of every deployment, sorted by cluster
#
#  Options:
#    -g|--gke-system  Include all the builtin gke deployments
function kubectl-get-deployments() {
  local GKE_SYSTEM_INCLUDED=
  local DEPLOYMENTS=
  local PROJECT=
  local UNUSED_ARGS=()

  PROJECT="$(parse-project "$@")"
  while [[ $# -gt 0 ]]; do
    case $1 in
      -g|--gke-system)
        GKE_SYSTEM_INCLUDED="True"
        shift
        ;;
      -h|--help)
        echo "Usage: ${FUNCNAME[0]} <-g|gke-system>"
        return 1
        ;;
      *)
        UNUSED_ARGS+=("$1")
        shift
        ;;
    esac
  done
  set -- "${UNUSED_ARGS[@]}"

  (
    echo "PROJECT: ${PROJECT}"
    echo 'DEPLOYMENT NAMESPACE NAME AGE'
    DEPLOYMENTS=$(
      while read -r cluster_info <&3; do
        GCLOUD_CLUSTER=$(awk '{print $1}' <<< "${cluster_info}")
        kubectl-get-cluster-deployment --cluster "${cluster_info}" --project "${PROJECT}" |
          awk -v cluster="${GCLOUD_CLUSTER}" '{ printf "%-30s%-30s%-40s%-10s\n", (NR==1? "DEPLOYMENT" : cluster), $1, $2, $6 }' |
          grep -v 'NAMESPACE' |
          grep -v "kube-system"
      done 3< <(gcloud-container-clusters --project "${PROJECT}" | tail -n +2)
    )

    (
      if [[ $GKE_SYSTEM_INCLUDED == "True" ]]; then
        echo "${DEPLOYMENTS}"
      else
        echo "${DEPLOYMENTS}" | grep -Fv -- "-gkecomposer-" | grep -Fv -- -gkedefault
      fi
    ) | sort
  ) | column -t
}

## [fkubectl-get-deployments]  ->  Shorthand
#  Calls [kubectl-get-deployments] and pipes it to fzf
function fkubectl-get-deployment() {
  local PROJECT
  PROJECT="$(parse-project "$@")"
  kubectl-get-deployments --project "${PROJECT}" "$@" | fzf --tac --header-lines=1 --header="  [project: ${PROJECT}]"
}

## [fkubectl-get-cluster-deployment]  ->  Shorthand
#  Pulls up a fzf window with all of the GKE clusters in the current working project
#    The selected cluster will be authed to
function fkubectl-get-cluster-deployment() {
  local PROJECT=
  PROJECT="$(parse-project "$@")"
  kubectl-get-cluster-deployment --cluster "$(fgcloud-container-clusters --project "${PROJECT}")"
}


# Taken from Junegunn's config.
# TODO - I should take some of these params as inspo. For example, the

## [fpods]  ->  Shorthand
#  Pulls up a fzf window with all pods in the current working cluster.
#
#  Preview pane:
#    Displays logs
#  Keybindings:
#    <CTRL-R> - Reload logs
#    <CTRL-O> - Open logs in vim
#    <ENTER>  - ssh to the pod
# shellcheck disable=SC2016
function fpods() {
  FZF_DEFAULT_COMMAND="kubectl get pods --all-namespaces" \
    fzf --info=inline --layout=reverse --header-lines=1 \
    --prompt "$(kubectl config current-context | sed 's/-context$//')> " \
    --header $'╱ Enter (kubectl exec) ╱ CTRL-O (open log in editor) ╱ CTRL-R (reload) ╱\n\n' \
    --bind 'ctrl-/:change-preview-window(80%,border-bottom|hidden|)' \
    --bind 'enter:execute:kubectl exec -it --namespace {1} {2} -- bash > /dev/tty' \
    --bind 'ctrl-o:execute:${EDITOR:-vim} <(kubectl logs --all-containers --namespace {1} {2}) > /dev/tty' \
    --bind 'ctrl-r:reload:$FZF_DEFAULT_COMMAND' \
    --preview-window up:follow \
    --preview 'kubectl logs --follow --all-containers --tail=10000 --namespace {1} {2}' "$@"
}

## TODO: I'm not going to include this for now. Using the contexts to iterate through pods is problematic
#        because it will include both prod and staging simultaneously. I think for now, picking a cluster and
#        then getting the pods with fpods is better

## [fpods-all]  ->  Shorthand
#  Pulls up a fzf window with all pods in all available contexts
#
#  Preview pane:
#    Displays logs
#  Keybindings:
#    <CTRL-R> - Reload logs
#    <CTRL-O> - Open logs in vim
#    <ENTER>  - ssh to the pod
# shellcheck disable=SC2016
# function fpods-all() {
#   FZF_DEFAULT_COMMAND='
#     (echo CONTEXT NAMESPACE NAME READY STATUS RESTARTS AGE
#      for context in $(kubectl config get-contexts --no-headers -o name | sort); do
#        kubectl get pods --all-namespaces --no-headers --context "$context" | sed "s/^/${context%-context} /" &
#      done; wait) 2> /dev/null | column -t
#   ' fzf --info=inline --layout=reverse --header-lines=1 \
#     --prompt 'all-pods> ' \
#     --header $'╱ Enter (kubectl exec) ╱ CTRL-O (open log in editor) ╱ CTRL-R (reload) ╱\n\n' \
#     --bind 'ctrl-/:change-preview-window(80%,border-bottom|hidden|)' \
#     --bind 'enter:execute:kubectl exec -it --context {1}-context --namespace {2} {3} -- bash > /dev/tty' \
#     --bind 'ctrl-o:execute:${EDITOR:-vim} <(kubectl logs --all-containers --context {1}-context --namespace {2} {3}) > /dev/tty' \
#     --bind 'ctrl-r:reload:eval "$FZF_DEFAULT_COMMAND"' \
#     --preview-window up:follow \
#     --preview 'kubectl logs --follow --tail=10000 --all-containers --context {1}-context --namespace {2} {3}' "$@"
# }

function kubectl-refresh-deployment-cache() {
  function __kubectl-refresh-deployment-cache () {
    (
      DISABLE_COMMAND_CACHE=true kubectl-get-deployments --staging >&/dev/null;
      DISABLE_COMMAND_CACHE=true kubectl-get-deployments --prod >&/dev/null;
      wall <(echo "Deployment cache refreshed")
    )
  }
  echo "Refreshing deployment cache.. Will broadcast a message when complete";
  __kubectl-refresh-deployment-cache &
}

function ffg() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

