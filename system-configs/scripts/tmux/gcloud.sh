#!/bin/bash

## This file interogates the gcloud config from the files on disk, instead of using the gcloud cli
#  This is because the gcloud cli is slow, and this is used in the tmux status bar by every window
#  which has been causing a lot of power usage

## [gcloud-get-service-account]  ->  Shorthand
#  Gets service account, if set
function gcloud-get-service-account() {
  local SERVICE_ACCOUNT=
  #SERVICE_ACCOUNT="$(gcloud config get auth/impersonate_service_account  2> /dev/null)"
  # shellcheck disable=SC2002
  SERVICE_ACCOUNT=$( awk -F'=' '/^impersonate_service_account/ {print $2}' \
    ~/.config/gcloud/configurations/config_"$(cat ~/.config/gcloud/active_config)" \
  )

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
  #gcloud auth list --format=json | jq -r '.[] | select(.status == "ACTIVE") | .account'
  # shellcheck disable=SC2002
  awk -F'=' '/^account/ {print $2}' \
    ~/.config/gcloud/configurations/config_"$(cat ~/.config/gcloud/active_config)" \
    | tr -d '[:space:]'
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

function print-gcloud-status-for-tmux() {
  local GCLOUD_PROJECT
  #GCLOUD_PROJECT="$(gcloud config get project 2>/dev/null)"
  # shellcheck disable=SC2002
  GCLOUD_PROJECT=$( awk -F'=' '/^project/ {print $2}' \
    ~/.config/gcloud/configurations/config_"$(cat ~/.config/gcloud/active_config)" \
  )
  if [[ $? -eq 0 && -n $GCLOUD_PROJECT ]]; then
    echo "#[bg=colour235]#[fg=colour220]<gcloud> ${GCLOUD_PROJECT} #[fg=colour219]{$(gcloud-whoami)}#[bg=colour233] "
  fi
}

print-gcloud-status-for-tmux
