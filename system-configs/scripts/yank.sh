#!/usr/bin/env bash

set -e

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
# shellcheck disable=SC1091
source "${CONFIGROOT_DIR_SCRIPT}/system-configs/rcfiles/sourced-scripts/yank.sh"
yank "$@"

