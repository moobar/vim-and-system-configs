#!/usr/bin/env bash

function figure-out-feature {
  pwd | grep -Eo 'workspaces/(.*)/\+share\+' | awk -F '/' '{ print $(NF-1) }'
} 

STATUS=$(figure-out-feature)

if [[ -z "$STATUS" ]]; then
  STATUS=$(pwd)
  #STATUS="${STATUS##*/}"
fi
STATUS="${STATUS##*/}"

echo "${STATUS}"
