#!/usr/bin/env bash

function github-repo-name() {
  local REPO_NAME=
  REPO_NAME=$(git rev-parse --show-toplevel)

  echo "[${REPO_NAME##*/}]"
}

function get-window-name() {
  local REPO_NAME='' CURRENT_DIR='' STATUS=''

  CURRENT_DIR="$(pwd)"
  CURRENT_DIR="${CURRENT_DIR##*/}"
  if git status &> /dev/null; then
    REPO_NAME="$(github-repo-name)"
    STATUS="${REPO_NAME}"
  else
    STATUS="${CURRENT_DIR}"
  fi

  echo "${STATUS}"
}

get-window-name
