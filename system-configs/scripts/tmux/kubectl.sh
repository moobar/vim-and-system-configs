#!/bin/bash

function print-kubectl-for-tmux() {
  local CURRENT_CONTEXT=
  CURRENT_CONTEXT="$(kubectl config current-context 2>/dev/null | sed 's/gke_//' | sed 's/_/ | /g')"

  if [[ $? -eq 0 && -n $CURRENT_CONTEXT ]]; then
    echo "#[bg=colour235]#[fg=colour229]#[bg=colour235]#[fg=colour229] <kubectl> ${CURRENT_CONTEXT} #[bg=colour233] "
  fi
}

print-kubectl-for-tmux
