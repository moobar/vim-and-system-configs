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
  local CONTAINER=
  if ! CONTAINER="$(docker-grep "$@")" || [[ -z "$CONTAINER" ]]; then
    echo "Failed to find a valid docker container for [$*]"
    return 1
  fi

  if (( $(grep -c . <<< "${CONTAINER}") > 1 )); then
    echo "Too many containers return. Fix your grep string"
    echo "${CONTAINER}"
    return 1
  fi

  if ! docker exec -it "${CONTAINER}" /bin/bash; then
    echo "Bash not found on docker image, trying /bin/sh"
    docker exec -it "${CONTAINER}" /bin/sh
  fi
}


function docker-buildx-imagetools() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: docker-buildx-imagetools-create [SOURCE_IMAGE] --tag TAG --tag TAG..."
    echo 'Example: docker-buildx-imagetools "gcr.io/google.com/cloudsdktool/google-cloud-cli:518.0.0-emulators" --tag "us.gcr.io/MY_COOL_PROJECT/google-cloud-cli:518.0.0-emulators" --tag "us.gcr.io/MY_COOL_PROJECT/google-cloud-cli:latest-emulators"'
    echo "See: https://docs.docker.com/reference/cli/docker/buildx/imagetools/create/ for more information"
    return 1
  fi

  echo "Running dry run: Validate output!"
  cat <<EOM
Running: docker buildx imagetools create --dry-run "$@"
EOM
  docker buildx imagetools create --dry-run "$@"

  yn_prompt "Continue with actual push?"
  set -x
  docker buildx imagetools create "$@"
  set +x
}

function docker-build-image-with-busybox-sh() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: ${FUNCNAME[0]} IMAGE_WITHOUT_A_SHELL"
    echo "Example: ${FUNCNAME[0]} \"gcr.io/google.com/cloudsdktool/google-cloud-cli:518.0.0-emulators\""
    return 1
  fi
  DOCKER_IMAGE=$1

  cat <<EOM > temp-dockerbuildfile-for-adding-busybox-sh
FROM busybox:1.36-musl AS utility

FROM ${DOCKER_IMAGE}

# Run as root for best debugging
USER root
COPY --from=utility /bin/busybox /busybox

SHELL ["/busybox", "sh", "-c"]
RUN /busybox --install -s /bin

# WORKDIR /

# Use bash by default, sh is also available
# ENTRYPOINT ["/bin/bash"]

EOM

  (
    # shellcheck disable=SC2329
    function cleanup-dockerfile() {
      # shellcheck disable=SC2317
      rm -f temp-dockerbuildfile-for-adding-busybox-sh
    }

    trap cleanup-dockerfile EXIT

    if ! yn_prompt 'Run: docker build -t debug-image:sh . -f temp-dockerbuildfile-for-adding-busybox-sh ?'; then
      return 1
    fi
    set -x
    docker build -t debug-image:sh . -f temp-dockerbuildfile-for-adding-busybox-sh
    set +x
  )

  if [[ $? -eq 0 ]]; then
    echo ""
    echo "debug-image:sh successfully built!"
    echo ""
    echo "To run image:"
    echo "docker run --workdir '/' --entrypoint '/bin/sh' -it debug-image:sh"
  fi
}

function docker-build-image-with-bash-installed() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: ${FUNCNAME[0]} IMAGE_WITHOUT_A_SHELL"
    echo "Example: ${FUNCNAME[0]} \"gcr.io/google.com/cloudsdktool/google-cloud-cli:518.0.0-emulators\""
    return 1
  fi
  DOCKER_IMAGE=$1

  cat <<EOM > temp-dockerbuildfile-for-adding-bash
FROM busybox:1.36-musl AS utility

FROM alpine:latest AS bash-builder
RUN apk add --no-cache wget && \
    wget https://github.com/robxu9/bash-static/releases/download/5.2.015-1.2.3-2/bash-linux-x86_64 -O /bash && \
    chmod +x /bash

FROM ${DOCKER_IMAGE}

# Run as root for best debugging
USER root
COPY --from=utility /bin/busybox /busybox

SHELL ["/busybox", "sh", "-c"]
RUN /busybox --install -s /bin

# Add bash here
COPY --from=bash-builder /bash /bin/bash

# WORKDIR /

# Use bash by default, sh is also available
# ENTRYPOINT ["/bin/bash"]

EOM

  (
    # shellcheck disable=SC2329
    function cleanup-dockerfile() {
      # shellcheck disable=SC2317
      rm -f temp-dockerbuildfile-for-adding-bash
    }

    trap cleanup-dockerfile EXIT

    if ! yn_prompt 'Run: docker build -t debug-image:bash . -f temp-dockerbuildfile-for-adding-bash ?'; then
      return 1
    fi
    set -x
    docker build -t debug-image:bash . -f temp-dockerbuildfile-for-adding-bash
    set +x
  )

  if [[ $? -eq 0 ]]; then
    echo ""
    echo "debug-image:bash successfully built!"
    echo ""
    echo "To run image:"
    echo "docker run --workdir '/' --entrypoint '/bin/bash' -it debug-image:bash"
  else
    echo "Hmm, didn't work. Try running [docker-build-image-with-busybox-sh] instead"
    return 1
  fi
}

function docker-export-image-tar() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: ${FUNCNAME[0]} IMAGE_TO_EXPORT [OUTPUT_TAR_FILE]"
    echo "Example: ${FUNCNAME[0]} \"gcr.io/distroless/static-debian11\""
    echo "Example: ${FUNCNAME[0]} \"gcr.io/distroless/static-debian11\" /tmp/my-export.tar"
    return 1
  fi

  local DOCKER_IMAGE=$1
  local OUTPUT_FILE=$2
  local SAFE_NAME
  local TIMESTAMP
  local EXPORT_TAR
  local CONTAINER_ID

  if [[ -z "${OUTPUT_FILE}" ]]; then
    local EXPORT_DIR="/tmp/container-exports"

    mkdir -p "${EXPORT_DIR}"

    SAFE_NAME="$(basename "${DOCKER_IMAGE}" | tr '/:' '_')"
    TIMESTAMP=$(date +%Y%m%d-%H%M)
    EXPORT_TAR="${EXPORT_DIR}/${SAFE_NAME}_${TIMESTAMP}.tar"

    echo "No output file specified."
    echo "Exporting to: ${EXPORT_TAR}"
    echo ""
  else
    EXPORT_TAR="${OUTPUT_FILE}"
  fi

  echo "Exporting filesystem for [${DOCKER_IMAGE}]..."
  if ! CONTAINER_ID=$(docker create "${DOCKER_IMAGE}"); then
    echo "Failed to create container from image: ${DOCKER_IMAGE}" >&2
    return 1
  fi

  (
    set -e
    # shellcheck disable=SC2329
    function cleanup-container() {
      docker rm "${CONTAINER_ID}" >/dev/null 2>&1
    }
    trap cleanup-container EXIT

    set -x
    docker export "${CONTAINER_ID}" -o "${EXPORT_TAR}"
    set +x
  )

  local EXIT_CODE=$?
  if [[ $EXIT_CODE -ne 0 ]]; then
    echo "Failed to export filesystem." >&2
    rm -f "${EXPORT_TAR}"
    return $EXIT_CODE
  fi

  echo ""
  echo "Filesystem successfully exported!"
  echo "Tarball located at:"
  echo "${EXPORT_TAR}"
  echo ""
  echo "To list contents, run:"
  echo "tar -tf ${EXPORT_TAR} | less"
  echo ""
  echo "When exporting contents, be sure to do it in an empty directory. The tar contains all the files at its root"
  echo "rm -rf container-export && mkdir -p container-export && tar -xvzf ${EXPORT_TAR} -C container-export"
}

function docker-list-cached-images() {
  docker images --format '{{.Repository}}:{{.Tag}}' | grep -Fv '<none>' | sort | uniq
}

function docker-crictl-images-pull() {
  docker exec "$(docker-grep "$@")" crictl images -o=json \
    | jq -r .images[].repoTags[] \
    | xargs -n1 docker pull
}

function docker-kill-all-containers() {
  docker ps | tail -n +2 | awk '{print $1}' | xargs -n1 docker kill
}

function docker-create-container-for-file-access() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: ${FUNCNAME[0]} TEMP_NAME IMAGE_PATH"
    echo "Ex ${FUNCNAME[0]} google-emulator gcr.io/google.com/cloudsdktool/google-cloud-cli:518.0.0-emulators"
    return 1
  fi
  local CONTAINER_NAME="$1"
  local IMAGE_PATH="$2"
  set -x
  docker create --name "${CONTAINER_NAME}" "${IMAGE_PATH}"
  set +x
  echo "Can now run:"
  echo "> docker cp ${CONTAINER_NAME}:/path/to/file/in/container /path/to/destination/on/host"
}

#https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes
function docker-rm-all-volumes() {
  docker volume ls --format=json | jq -r .Name | xargs -n1 docker volume rm
}

function docker-prune-images() {
  # use -a to do all intermediate images too
  docker system prune "$@"
}


function ffdocker() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"


## Deprecated functions ##

# shellcheck disable=SC2347,SC2317,SC2329
function docker-build-and-push-multiarch-deprecated() {
  echo "use docker-buildx-imagetools instead"
  return 1

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

function docker-pull-tag-and-push-deprecated() {
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

function docker-inspect-and-get-entrypoint() {
  local DOCKER_ID=
  if [[ -z $1 ]]; then
    DOCKER_ID="$(docker ps | fzf --accept-nth 1 --header-lines=1)"
  fi

  if [[ -z $DOCKER_ID ]]; then
    echo "No image id selected"
    return 1
  else
    set -- "${DOCKER_ID}" "$@"
  fi

  docker inspect -f '{{.Config.Entrypoint}}' "$@"
}
