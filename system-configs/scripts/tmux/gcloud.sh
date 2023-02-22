#!/bin/bash

function get_gcloud_project() {
  local GCLOUD_PROJECT
  GCLOUD_PROJECT="$(gcloud config get project 2>/dev/null)"
  if [[ $? -eq 0 && -n $GCLOUD_PROJECT ]]; then
    echo "$(gcloud config get project)"
  fi
}

get_gcloud_project
