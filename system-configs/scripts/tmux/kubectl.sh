#!/bin/bash

if kubectl config current-context &>/dev/null; then
  echo "<kubectl>" "$(kubectl config current-context | sed 's/gke_//' | sed 's/_/ | /g')"
fi
