#!/bin/bash

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

gcloud-whoami
