#!/bin/bash

## This file interogates the gcloud config from the files on disk, instead of using the gcloud cli
#  This is because the gcloud cli is slow, and this is used in the tmux status bar by every window
#  which has been causing a lot of power usage

function print-kubectl-for-tmux() {
  local CURRENT_CONTEXT=
  #CURRENT_CONTEXT="$(kubectl config current-context 2>/dev/null | sed 's/gke_//' | sed 's/_/ | /g')"
  CURRENT_CONTEXT=$(yq .current-context ~/.kube/config 2>/dev/null | sed 's/gke_//' | sed 's/_/ | /g')

  if [[ $? -eq 0 && -n $CURRENT_CONTEXT ]]; then
    echo "#[bg=colour235]#[fg=colour229]#[bg=colour235]#[fg=colour229] <kubectl> ${CURRENT_CONTEXT} #[bg=colour233] "
  fi
}

print-kubectl-for-tmux
