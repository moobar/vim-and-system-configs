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

## [gcloud-dump-all-iam]  ->  Alias
# Get all IAM policies for a project
function gcloud-dump-all-iam() {
  local PROJECT=
  PROJECT="$(parse-project "$@")"
  gcloud asset search-all-iam-policies \
    --scope="projects/${PROJECT}" \
    --query='resource://*' \
    --format=json \
    "$@"
}

## [gcloud-iam-members-by-roles]  ->  Alias
# Get all IAM policies for a project
function gcloud-iam-members-by-roles() {
  local PROJECT=
  PROJECT="$(parse-project "$@")"
  gcloud asset search-all-iam-policies \
    --scope="projects/${PROJECT}" \
    --query='resource://cloudresourcemanager.googleapis.com' \
    --format=json \
    "$@"
}

# Get all IAM policies for a project
function gcloud-iam-members-one-off-perms() {
  gcloud-dump-all-iam "$@" \
    | jq -c .[] | grep -Fv '//cloudresourcemanager.googleapis.com' \
    | jq -s
}

#function pprint-iam() {
#  # Check if anything is in stdin
#  if test ! -t 0; then
#    cat \
#      | jq '
#          .[]
#          | .policy.bindings[].role as $role
#          | .policy.bindings[].members as $members
#          | { assetType, resource, $role, $members }' \
#      | jq -s
#  else
#    echo "Expecting input from pipe"
#  fi
#}



function ffgcpiam() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

