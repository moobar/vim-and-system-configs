#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function docker-mapped-port() {
  # Check if anything is in stdin
  if test ! -t 0; then
    cat \
      | grep -Eo '0.0.0.0:[0-9]+' \
      | cut -d: -f2
  else
    if [[ -z "${1}" ]]; then
      echo "Expecting input from pipe or grep pattern"
      return 1
    fi

    # shellcheck disable=SC2002
    docker ps \
      | grep "$1" \
      | grep -Eo '0.0.0.0:[0-9]+' \
      | cut -d: -f2
  fi
}

function docker-grep() {
  local SEARCH_PATTERN=
  if test ! -t 0; then
    SEARCH_PATTERN="$(cat)"
  else
    if [[ -z "${1}" ]]; then
      echo "Expecting input from pipe or grep pattern"
      return 1
    fi
    SEARCH_PATTERN="$1"
  fi
  docker ps | grep -i "${SEARCH_PATTERN}" | awk '{print $1}'
}

function docker-kill() {
  docker kill "$(docker-grep "$@")"
}

function docker-exec() {
  if docker exec -it "$(docker-grep amicus)" /bin/ls /bin/bash &>/dev/null; then
    docker exec -it "$(docker-grep "$@")" /bin/bash
  else
    docker exec -it "$(docker-grep "$@")" /bin/sh
  fi
}

function docker-build-and-push-multiarch() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: docker-build-and-push-multiarch [MULTI_ARCH_IMAGE_SORCE] [PUSH_DESTINATION]"
    echo "Example: docker-build-and-push-multiarch \"gcr.io/google.com/cloudsdktool/google-cloud-cli:518.0.0-emulators\" \"us.gcr.io/MY_COOL_PROJECT/google-cloud-cli:518.0.0-emulators\""
    return 1
  fi
  local IMAGE_SOURCE="$1"
  local PUSH_DESTINATION="$2"
  (

    function cleanup-dockerfile() {
      # shellcheck disable=SC2317
      rm -f temp-dockerbuidfile-for-pushing-multiarch
    }

    trap cleanup-dockerfile EXIT

    echo "FROM ${IMAGE_SOURCE}" > temp-dockerbuidfile-for-pushing-multiarch
    echo About to run: docker buildx build . --platform linux/amd64,linux/arm64 -f temp-dockerbuidfile-for-pushing-multiarch -t "${PUSH_DESTINATION}" --progress plain --push
    echo "Enter to continue, CTRL-C to quit"
    read -r _
    set -x
    docker buildx build . --platform linux/amd64,linux/arm64 -f temp-dockerbuidfile-for-pushing-multiarch -t "${PUSH_DESTINATION}" --progress plain --push
    set +x
  )
}

function docker-pull-tag-and-push() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: docker-pull-tag-and-push [IMAGE_SORCE] [PUSH_DESTINATION] <OPTIONAL ARCH, defaults to linux/amd64 (not host default)>"
    echo "Example: docker-pull-tag-and-push \"gcr.io/google.com/cloudsdktool/google-cloud-cli:518.0.0-emulators\" \"us.gcr.io/MY_COOL_PROJECT/google-cloud-cli:518.0.0-emulators\" \"linux/arm64\""
    return 1
  fi
  local IMAGE_SOURCE="$1"
  local PUSH_DESTINATION="$2"
  local PLATFORM="linux/amd64"

  if [[ -n $3 ]]; then
    PLATFORM=$3
  fi

  docker pull --platform="${PLATFORM}" "${IMAGE_SOURCE}"
  docker tag "${IMAGE_SOURCE}" "${PUSH_DESTINATION}"
  docker push "${PUSH_DESTINATION}"
}

function ffdocker() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

