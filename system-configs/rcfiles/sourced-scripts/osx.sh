#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

## Only run this script when on OSX
if [[ $(uname -s) != "Darwin" ]]; then
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

## [find-bundle-id NAME]
#  Given a [NAME] of an app, try to find the bundle id
#
#  NAME   = Name of the applicatino
#  RETURNS  ->
#    id of app, via osascript
function find-bundle-id() {
  if [[ -z $1 || $# -ne 1 ]]; then
    echo "Must supply exactly one arg"
  else
    app_query=$(cat <<EOM
id of app "${1}"
EOM
  )
  osascript -e "${app_query}"
  fi
}

## [list-all-apps]  ->  Alias
#  Use the builtin [mdfind] to try to find Applications
function list-all-apps() {
  mdfind -onlyin / kMDItemKind==Application
}

## [lsapps]  ->  Alias
#  Alias for [lsappinfo]
function lsapps() {
  lsappinfo
}

## [lsusers]  ->  Shorthand
#  Get list of all users on computer. By default, filters users that begin with an "_"
#  Options:
#    -a|--all       View all users, even those that begin with an "_"
function lsusers() {
  local ALL_USERS=

  while [[ $# -gt 0 ]]; do
    case $1 in
      -a|--all)
        ALL_USERS="True"
        shift
        ;;
      *)
        return 1
        ;;
    esac
  done

  if [[ -z "$ALL_USERS" ]]; then
    dscl . list /Users | grep -v '^_'
  else
    dscl . list /Users
  fi
}

function finder-replace-with-app() {
  if [[ -z $1 ]]; then
    echo 'Must provide the bundleID of the app'
    return 1
  fi
  local APP_BUNDLE_ID="$1"
  local ARRAY_ADD=

  ARRAY_ADD="$(cat <<EOM
{LSHandlerContentType="public.folder";LSHandlerRoleAll="${APP_BUNDLE_ID}";}
EOM
)"

  echo "About to run:"
  echo defaults write -g NSFileViewer -string "${APP_BUNDLE_ID}"
  echo defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add "${ARRAY_ADD}"
  echo "CTRL-C to quit"
  read -r _;

  set -x
  defaults write -g NSFileViewer -string "${APP_BUNDLE_ID}"
  defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add "${ARRAY_ADD}"
  set +x

  echo "Done! Requires a restart to take effect"
}

function finder-restore-as-default-app() {
  defaults delete -g NSFileViewer
  defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType="public.folder";LSHandlerRoleAll="com.apple.finder";}'
}

function disable-hold-and-popup() {
  defaults write -g ApplePressAndHoldEnabled -bool false

  echo "Disabled. You must log out and log back in for it to take effect"
}

function ffosx() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

