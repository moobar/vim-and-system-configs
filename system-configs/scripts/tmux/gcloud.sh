#!/bin/bash

if gcloud config get project &>/dev/null; then
  echo "<gcloud> $(gcloud config get project)"
fi
