#!/bin/bash

# This script gets the latest bash from source and has the ability to install it

## [latest_bash_link]
#  Checks ftp.gnu.org for the latest stable bash release
#
#  RETURNS  ->
#    URL to the bash source (tar.gz)
function latest_bash_link() {
  local BASH_URL_PREFIX='https://ftp.gnu.org/gnu/bash'
  local FILE=
  FILE=$(curl -s "${BASH_URL_PREFIX}"'/?C=M;O=D' | pup 'a attr{href}' | grep -E 'bash-[0-9.]+\.tar\.gz$' | sort -rV | head -1)
  if [[ -n $FILE ]]; then
    echo "${BASH_URL_PREFIX}/${FILE}"
  else
    return 1
  fi
}

## [download_latest_bash]
#  Downloads latest bash source
#
#  RETURNS  ->
#    Bash source code (tar.gz) is downloaded to cwd
function download_latest_bash() {
  local BASH_URL=
  BASH_URL=$(latest_bash_link)
  if [[ -n $BASH_URL ]]; then
    wget --no-clobber --quiet "${BASH_URL}"
  else
    return 1
  fi
}

## [check_newer_version_of_bash]
#  Compares the current version of bash in ~/bin/source/bash and
#  sees if there is a newer version available.
#
#  RETURNS  ->
#    returns 1 if on latest version
#    returns 0 if a newer version is available
function check_newer_version_of_bash() {
  mkdir -p ~/bin/source/bash
  (
    cd ~/bin/source/bash || return 1
    local FILE=
    local DIR=

    FILE=$(basename "$(latest_bash_link)")
    DIR="${FILE/.tar.gz/}"

    # If the directory is already there, we are on the latest version
    if [[ -d ${DIR} ]]; then
      return 1
    else
      return 0
    fi
  )
}

## [install_latest_bash]
#  If its not already there: download, compile, and install bash locally
#
#  RETURNS  ->
#    [~/bin/bash] should point to the latest version of bash
function install_latest_bash() {
  mkdir -p ~/bin/source/bash
  (
    cd ~/bin/source/bash || return 1
    local FILE=
    local DIR=

    FILE=$(basename "$(latest_bash_link)")
    DIR="${FILE/.tar.gz/}"

    # If the directory is already there, we can just exit
    if [[ -d ${DIR} ]]; then
      return 0
    fi

    if ! download_latest_bash; then
      return 1
    fi

    tar -xzf "${FILE}"
    rm "${FILE}"

    if [[ ! -d ${DIR} ]]; then
      # Something went wrong with the extraction
      return 1
    fi

    ln -sfn "${DIR}" ~/bin/source/bash/latest
    cd latest || return 1

    # Build bash and symlink
    sed -i.bak -E 's/define HEREDOC_PIPESIZE ([0-9]+|PIPESIZE)/define HEREDOC_PIPESIZE 512/g' redir.c
    ./configure && make || return 1
    ln -sf "$(pwd)/bash" ~/bin/bash || return 1
  )
}

function upgrade_bash() {
  if ! check_newer_version_of_bash; then
    return 0
  fi

  local FILE=
  FILE="$(latest_bash_link)"
  if [[ -z $FILE ]]; then
    return 1
  fi

  local VERIFY_UPGRADE=
  while [[ $VERIFY_UPGRADE != "y" && $VERIFY_UPGRADE != "n" ]] ; do
    echo "Found newer version of bash: [${FILE}]"
    echo -n "Install [${FILE}] - "
    read -r -p "y/N?: " VERIFY_UPGRADE
    VERIFY_UPGRADE=$(echo "${VERIFY_UPGRADE}" | tr '[:upper:]' '[:lower:]')
  done

  if [[ $VERIFY_UPGRADE == "y" ]]; then
    echo "Upgrading bash to: ${FILE}"
    if install_latest_bash; then
      echo "[${FILE}] Successfully upgraded!"
      echo "Open a new terminal, to start using the latest bash version"
      return 0
    else
      return 1
    fi
  fi

  return 0
}
