#!/bin/bash

# WARNING: This file cannot have any dependencies

function __validate_current_working_script_dir_with_shellcheck() {
  # shellcheck disable=SC2005
  echo "$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
}
# shellcheck disable=SC2034
BASH_COMMON_SCRIPT_CWD_OF_SCRIPT=$(cat <<'EOM'
  # shellcheck disable=SC2005
  echo "$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
EOM
)


function __validate_unsourceable_with_shellcheck() {
  (return 0 2>/dev/null) && sourced=1 || sourced=0
  if [[ $sourced -ne 0 ]]; then
    echo "Don't source this script. Run it directly"
    return 1
  fi
}
# shellcheck disable=SC2034
BASH_COMMON_SCRIPT_UNSOURCEABLE=$(cat <<'EOM'
  (return 0 2>/dev/null) && sourced=1 || sourced=0
  if [[ $sourced -ne 0 ]]; then
    echo "Don't source this script. Run it directly"
    return 1
  fi
EOM
)

function __validate_fzf_in_sourced_script_with_shellcheck() {
  # shellcheck disable=SC2317
  function __error_handler_script__() {
    local NC='\033[0m' # No Color

    # Regular Colors
    local Red='\033[0;31m'
    local Yellow='\033[0;33m'

    local last_status_code=$1;
    local lc="$BASH_COMMAND"

    echo -e 1>&2 "${Red}Script-Error:${NC}${Yellow} [$lc] ${NC}-${Red} exited with status $last_status_code${NC}";
  }

  local CHOICES=
  local CHOICE=
  # shellcheck disable=SC2002
  CHOICES=$(grep -h '^function' "${BASH_SOURCE[0]}" | cut -d' ' -f2 | grep -v '^_' | tr -d ')(}{ ' | grep -v '^ff[a-zA-Z0-9_-]*$' | sort -f | uniq)
  CHOICE=$(echo "${CHOICES}" |
    fzf --reverse \
        --preview-window='up:wrap,35%' \
        --bind "ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
        --bind "ctrl-j:preview-down,ctrl-k:preview-up" \
        --preview="echo {} | xargs -I}{ grep -E -l '^function }{[ ({]+' ${BASH_SOURCE[0]} | xargs -n1 tac | sed -E -n '/^function {}[ ({]+/,/^ *$/p' | sed '/^ *$/d' | grep -iv '# *shellcheck disable=' | tail -n +2 | tac"
      )


  # Common to ctrl-c/esc after fzf. So only start trapping after fzf
  trap  '__error_handler_script__ $?' ERR
  if [[ -n "$CHOICE" ]]; then
    _send_keys_to_terminal "${CHOICE}"
  else
    return 1
  fi
}
# shellcheck disable=SC2034
BASH_FZF_IN_SOURCED_SCRIPT=$(cat <<'EOM'
  # shellcheck disable=SC2317
  function __error_handler_script__() {
    local NC='\033[0m' # No Color

    # Regular Colors
    local Red='\033[0;31m'
    local Yellow='\033[0;33m'

    local last_status_code=$1;
    local lc="$BASH_COMMAND"

    echo -e 1>&2 "${Red}Script-Error:${NC}${Yellow} [$lc] ${NC}-${Red} exited with status $last_status_code${NC}";
  }

  local CHOICES=
  local CHOICE=
  # shellcheck disable=SC2002
  CHOICES=$(grep -h '^function' "${BASH_SOURCE[0]}" | cut -d' ' -f2 | grep -v '^_' | tr -d ')(}{ ' | grep -v '^ff[a-zA-Z0-9_-]*$' | sort -f | uniq)
  CHOICE=$(echo "${CHOICES}" |
    fzf --reverse \
        --preview-window='up:wrap,35%' \
        --bind "ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
        --bind "ctrl-j:preview-down,ctrl-k:preview-up" \
        --preview="echo {} | xargs -I}{ grep -E -l '^function }{[ ({]+' ${BASH_SOURCE[0]} | xargs -n1 tac | sed -E -n '/^function {}[ ({]+/,/^ *$/p' | sed '/^ *$/d' | grep -iv '# *shellcheck disable=' | tail -n +2 | tac"
      )


  # Common to ctrl-c/esc after fzf. So only start trapping after fzf
  trap  '__error_handler_script__ $?' ERR
  if [[ -n "$CHOICE" ]]; then
    _send_keys_to_terminal "${CHOICE}"
  else
    return 1
  fi
EOM
)

function __validate_footer_with_shellcheck() {
  (return 0 2>/dev/null) && sourced=1 || sourced=0
  if [[ $sourced -eq 0 ]]; then
    set -Ee -o pipefail

    # shellcheck disable=SC2317
    function __error_handler_script__() {
      local NC='\033[0m' # No Color

      # Regular Colors
      local Red='\033[0;31m'
      local Yellow='\033[0;33m'

      local last_status_code=$1;
      local lc="$BASH_COMMAND"

      echo -e 1>&2 "${Red}Script-Error:${NC}${Yellow} [$lc] ${NC}-${Red} exited with status $last_status_code${NC}";
    }

    if [[ -z ${1-""} ]]; then
      echo "Must provide a function to call. To see available functions"
      echo "Try: bash ${BASH_SOURCE[0]} fzf"
      exit 1
    else
      FUNCTION="$1"
    fi

    # Check if the function exists (bash specific)
    if [[ $FUNCTION == "fzf" ]]; then
      # shellcheck disable=SC2002
      FUNCTION=$(cat "${BASH_SOURCE[0]}" | sed -n -E 's/^function (([^\(]| )+).*$/\1/p' | grep -v ^_| sort | fzf)

      # Common to ctrl-c/esc after fzf. So only start trapping after fzf
      trap  '__error_handler_script__ $?' ERR
      if [[ -n "$FUNCTION" ]]; then
        # shellcheck disable=SC2116
        CMD=$(echo bash "${BASH_SOURCE[0]}" "$FUNCTION")
        #_send_keys_to_terminal "${CMD}"
        echo CMD: "${CMD}"
        unset FUNCTION
        unset CMD
      else
        exit 1
      fi
    elif declare -f "$FUNCTION" > /dev/null; then
      unset FUNCTION
      "$@"
    else
      # Show a helpful error
      echo "'$1' is not a known function name" >&2
      exit 1
    fi
  fi
}
# shellcheck disable=SC2034
BASH_COMMON_SCRIPT_FOOTER=$(cat <<'EOM'
  (return 0 2>/dev/null) && sourced=1 || sourced=0
  if [[ $sourced -eq 0 ]]; then
    set -Ee -o pipefail

    # shellcheck disable=SC2317
    function __error_handler_script__() {
      local NC='\033[0m' # No Color

      # Regular Colors
      local Red='\033[0;31m'
      local Yellow='\033[0;33m'

      local last_status_code=$1;
      local lc="$BASH_COMMAND"

      echo -e 1>&2 "${Red}Script-Error:${NC}${Yellow} [$lc] ${NC}-${Red} exited with status $last_status_code${NC}";
    }

    if [[ -z ${1-""} ]]; then
      echo "Must provide a function to call. To see available functions"
      echo "Try: bash ${BASH_SOURCE[0]} fzf"
      exit 1
    else
      FUNCTION="$1"
    fi

    # Check if the function exists (bash specific)
    if [[ $FUNCTION == "fzf" ]]; then
      # shellcheck disable=SC2002
      FUNCTION=$(cat "${BASH_SOURCE[0]}" | sed -n -E 's/^function (([^\(]| )+).*$/\1/p' | grep -v ^_| sort | fzf)

      # Common to ctrl-c/esc after fzf. So only start trapping after fzf
      trap  '__error_handler_script__ $?' ERR
      if [[ -n "$FUNCTION" ]]; then
        # shellcheck disable=SC2116
        CMD=$(echo bash "${BASH_SOURCE[0]}" "$FUNCTION")
        #_send_keys_to_terminal "${CMD}"
        echo CMD: "${CMD}"
        unset FUNCTION
        unset CMD
      else
        exit 1
      fi
    elif declare -f "$FUNCTION" > /dev/null; then
      unset FUNCTION
      "$@"
    else
      # Show a helpful error
      echo "'$1' is not a known function name" >&2
      exit 1
    fi
  fi
EOM
)

