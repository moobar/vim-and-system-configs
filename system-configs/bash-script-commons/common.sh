#!/bin/bash

# WARNING: This file cannot have any dependencies

## [_capture_stdout_and_stder COMMAND]
#  Run a command and put stderr and stdout into CAPTURED_STDERR and CAPTURED_STDOUT
#
#  COMMAND  = Any arbitrary lenght command
#  RETURN  ->
#    CAPTURED_STDERR   Varibale set with the output from STDERR
#    CAPTURED_STDOUT   Varibale set with the output from STDOUT
#    returns 2 if not enough args
function _capture_stdout_and_stderr() {
  local IFS=
  if [[ $# -eq 0 ]]; then
    echo "Requires a command"
    return 2
  fi

  {
    IFS=$'\n' read -r -d '' CAPTURED_STDERR;
    IFS=$'\n' read -r -d '' CAPTURED_STDOUT;
    (IFS=$'\n' read -r -d '' _ERRNO_; exit "${_ERRNO_}");
    export CAPTURED_STDERR
    export CAPTURED_STDOUT
  } < <( (printf '\0%s\0%d\0' "$("$@")" "${?}" 1>&2) 2>&1 )
}

## [_unset_stdout_and_stderr]
#  calls unset on CAPTURED_STDERR and CAPTURED_STDOUT
#
#  RETURN  ->
#    Nothing
function _unset_stdout_and_stderr() {
  unset CAPTURED_STDERR
  unset CAPTURED_STDOUT
}

## [_send_keys_to_terminal STRING]
#  Checks if in tmux and if so, sends the [STRING] to the interactive tty
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#    KEYS to TTY if in tmux
#    STRING of command if not in tmux
# shellcheck disable=SC2120
function _send_keys_to_terminal() {
  local KEYS=
  if test ! -t 0; then
    KEYS=$(cat)
  else
    KEYS="$*"
  fi

  bind "\C-^":redraw-current-line
  if [[ -z "$TMUX" ]]; then
    Command to run: "${KEYS}"
  else
    tmux send-keys -t "${TMUX_PANE}" "${KEYS}" C-^
  fi
}

## [_file_older_than FILE SECONDS]
#  Checks [FILE] to see if it doesn't exist or if its been modified
#  more than [SECONDS] ago
#
#  FILE     = Name of file
#  SECOND   = Max number of seconds to cache
#  RETURN  ->
#    returns 0 if [FILE] is doesn't exist
#    returns 0 if [FILE] modification time is older than [SECONDS]
#    returns 1 otherwise
function _file_older_than() {
  if [[ $# -ne 2 ]]; then
    return 0
  fi
  local FILE=$1
  local SECONDS=$2

  if [[ ! -f "$FILE" ]]; then
    return 0
  fi

  local SECONDS_SINCE_LAST_MODIFIED=
  if [[ $(uname -s) == "Darwin" ]]; then
    SECONDS_SINCE_LAST_MODIFIED=$(( $(date +%s) - $(stat -f %a "${FILE}") ))
  else
    SECONDS_SINCE_LAST_MODIFIED=$(( $(date +%s) - $(stat --format=%Y "${FILE}") ))
  fi
  if [[ $SECONDS_SINCE_LAST_MODIFIED -ge $SECONDS ]]; then
    return 0
  else
    return 1
  fi
}

## [_file_empty FILE]
#  Checks [FILE] to see if it doesn't exist or if it's empty
#
#  FILE     = Name of file
#  RETURN  ->
#    returns 0 if [FILE] is doesn't exist
#    returns 0 if [FILE] is empty
#    returns 1 otherwise
function _file_empty {
  if [[ $# -ne 1 ]]; then
    return 0
  fi
  local FILE=$1

  if [[ ! -f "$FILE" ]]; then
    return 0
  fi

  if ! grep -q '[^[:space:]]' "${FILE}"; then
    return 0
  else
    return 1
  fi
}

## [countdown SECONDS]
#  Lowercase all the characters in [SECONDS]
#
#  Args:
#    -s|--seconds [SECONDS]   Number of seconds to countdown from
#  Options:
#    -f|--flat                Prints countdown on one line, instead of 1 line per count
#  RETURN  ->
#     Prints a count down starting from [SECONDS] to zero
function countdown() {
  local SECONDS=5
  local FLAT=

  while [[ $# -gt 0 ]]; do
    case $1 in
      -s|--seconds)
        SECONDS="$2"
        shift
        shift
        ;;
      -f|--flat)
        FLAT="True"
        shift
        ;;
      *)
        return 1
        ;;
    esac
  done

  if [[ -z "$SECONDS" ]]; then
    return 1
  fi

  for i in $(seq "${SECONDS}" 1); do
    if [[ "$FLAT" == "True" ]]; then
      echo -n "${i}... "
    else
      echo "${i}..."
    fi
    sleep 1
  done

  if [[ -z "$FLAT" ]]; then
    echo ""
  fi
}

## [ff SCRIPT]
#  Fuzzy finds all functions in a script
#
#  STRING   = Text of a script
#  RETURN  ->
#     fzf input with all the functions selectable
function ff() {
  if test ! -t 0; then
    cat \
      | sed -n -E 's/^function (([^\(]| )+).*$/\1/p' | grep -v ^_| sort | fzf | _send_keys_to_terminal
  else
    if [[ -z "${1}" ]]; then
      echo "Expecting input from pipe or a file"
      return 1
    fi

    # shellcheck disable=SC2002
    cat "$1" \
      | sed -n -E 's/^function (([^\(]| )+).*$/\1/p' | grep -v ^_| sort | fzf | _send_keys_to_terminal
  fi
}

## [to_lower STRING]
#  Lowercase all the characters in [STRING]
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#     STRING with all characters lowercased
function to_lower() {
  tr '[:upper:]' '[:lower:]'
}

## [escape STRING]
#  escape special characters in [STRING]
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#     STRING with special characters escaped
function escape() {
  printf '%s\n' "$*" | sed -e 's/[\/&]/\\&/g'
}

## [first STRING]
#  print the first column from text
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#     awk '{print $1}'
function first() {
  awk '{print $1}'
}

## [last STRING]
#  print the first column from text
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#     awk '{print $NF}'
function last() {
  awk '{print $NF}'
}

## [count_leading_spaces STRING]
#  Counts the number of whitespace characters at the beginning of [STRING]
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#     Number of spaces up until the first non whitespace character
function count_leading_spaces() {
  awk -F'[^ ]' '{print length($1)}' <<< "$1"
}

## [trim_leading_whitespace STRING]
#  Delete leading whitespaces
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#     STRING with the leading whitespaces removed
function trim_leading_whitespace() {
  sed 's/^[[:space:]]*//'
}

## [delete_empty_line STRING]
#  Delete all empty lines in [STRING]
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#     STRING with all empty lines removed
function delete_empty_line() {
  sed '/^[[:space:]]*$/d'
}

## [make_numbers_comma_list STRING]
#  Format a list of numbers so it looks like 1, 2, 3
#
#  STRING   = Numbers separated by spaces and/or commands
#  RETURN  ->
#     STRING in format of 1, 2, 3
function make_numbers_comma_list() {
  sed -E -e 's/([[:digit:]])[^[:digit:]]+/\1, /g'
}

## [is_base64 STRING]
#  Check to see if a [STRING] is a base64 string
#
#  STRING   = Some arbitrary text
#  RETURN  ->
#     returns 0 if base64
#     returns 1 if not
function is_base64() {
  cat "$@" | base64 -d 2>&1 /dev/null
  return $?
}

## [command_cache_dir]
#  Consistet way to reference the command command directory
#
#  RETURN  ->
#     STRING containing the name of the cache dir
function command_cache_dir() {
  local COMMAND_CACHE_DIR=
  COMMAND_CACHE_DIR="/tmp/$(whoami)_command_cache"
  if [[ ! -d ${COMMAND_CACHE_DIR} ]]; then
    mkdir "${COMMAND_CACHE_DIR}"
  fi
  echo "${COMMAND_CACHE_DIR}"
}

## [clean_cache_command]
#  Delete all the cached commands saved on disk
#
#  RETURN  ->
#     Nothing
function clean_cached_commands() {
  local COMMAND=
  local CACHE_DIR=
  CACHE_DIR=$(command_cache_dir)
  if [[ "$CACHE_DIR" == /tmp/* ]]; then
    # shellcheck disable=SC2116
    COMMAND=$(echo rm -rf "${CACHE_DIR:?}/*")
  else
    return 1
  fi

  local VERIFY_DELETE=
  while [[ $VERIFY_DELETE != "y" && $VERIFY_DELETE != "n" ]] ; do
    echo "Proceed with command?: [${COMMAND}]"
    read -r -p "y/N?: " VERIFY_DELETE
    VERIFY_DELETE=$(echo "${VERIFY_DELETE}" | to_lower)
  done

  if [[ $VERIFY_DELETE == "y" ]]; then
    echo "Running: ${COMMAND}"
    ${COMMAND}
  fi
}

## [cache_command]
#  Lets you specify a bash statement to cache.
#  The most common use of this function is to cache some inner
#  part (or all) of a function.
#
#  Env Variable Support:
#    DISABLE_COMMAND_CACHE    Set this to any value to disable caching commands
#    DISABLE_CACHE_COMMAND    Set this to any value to disable caching commands
#  Args:
#    -d|--directory [DIRECTORY]      Directory to nest cached file in
#    -f|--function  [FUNCTION_NAME]  Function name, usually use ${FUNCNAME[0]}
#    -x|--execute   [COMMAND]        Command to execute
#  Options:
#    -t|--ttl [SECONDS]        Max seconds to cache (default 36000)
#    -n|--no-cached-output     Instead of saving the output to disk, just run the command and send to stdout
#    -r|--run-now              Ignore cache and run now
#
#  Example:
#    cache_command \
#      --ttl 3600 \
#      -d '(gcloud config get project)' \
#      -f ${FUNCNAME[0]} \
#      -x 'gcloud compute instances list --sort-by=name'
function cache_command() {
  # TODO: Add logic to only cache if the command is successful

  # Example usage:
  local MAX_SECONDS_TO_CACHE=36000
  local FUNCTION=
  local COMMAND=
  local DIR=
  local NO_CACHED_OUTPUT=

  while [[ $# -gt 0 ]]; do
    case $1 in
      -f|--function)
        FUNCTION="$2"
        shift
        shift
        ;;
      -x|--execute)
        COMMAND="$2"
        shift
        shift
        ;;
      -d|--directory)
        DIR="$2"
        shift
        shift
        ;;
      -t|--ttl)
        local re='^[0-9]+$'
        if [[ $2 =~ $re ]] ; then
          MAX_SECONDS_TO_CACHE="$2"
        fi
        shift
        shift
        ;;
      -n|--no-cached-output)
        NO_CACHED_OUTPUT="True"
        shift
        ;;
      -r|--run-now)
        MAX_SECONDS_TO_CACHE="0"
        shift
        ;;
      *)
        return 1
        ;;
    esac
  done

  if [[ -z "$FUNCTION" || -z "$COMMAND" || -d "$DIR" ]]; then
    return 1
  fi

  local CACHE_DIR=
  CACHE_DIR="$(command_cache_dir)/${DIR}"
  mkdir -p "${CACHE_DIR}"

  local CACHE_FILE="${CACHE_DIR}/${FUNCTION}"

  if [[ -n $DISABLE_COMMAND_CACHE || -n $DISABLE_CACHE_COMMAND ]] ||
     ( [[ -z "$NO_CACHED_OUTPUT" ]] && _file_empty "${CACHE_FILE}" ) ||
     _file_older_than "${CACHE_FILE}" "${MAX_SECONDS_TO_CACHE}"; then
    if [[ "$NO_CACHED_OUTPUT" == "True" ]]; then
      touch "${CACHE_FILE}"
      eval "${COMMAND}"
    else
      eval "${COMMAND}" | tee "${CACHE_FILE}"
    fi
  else
    if [[ -z "$NO_CACHED_OUTPUT" ]]; then
      cat "${CACHE_FILE}"
    fi
  fi
}
