#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/common.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/common.sh"
fi
CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

## [fnmap-script]  ->  Shorthand
#  Finds all the .nse scripts that are available and prepopulates the command
#  This also will preview the script on the right, which usually contains a description
#
#  ** It's worth noting you need to fill in all the arguments yourself when you run the script
function fnmap-script() {
  local FILE_TO_OPEN
  FILE_TO_OPEN=$(
  (
    local NMAP_DIR=
    if [[ -r "$(brew --prefix)/opt/nmap/share/nmap/scripts" ]]; then
      NMAP_DIR="$(brew --prefix)/opt/nmap/share/nmap/scripts"
    else
      # Only tested on Ubuntu
      NMAP_DIR="/usr/share/nmap/scripts"
    fi
    local preview=
    preview="bat --style='${BAT_STYLE:-full}' --color=always --pager=never -- ${NMAP_DIR}/{-1}"
    find "${NMAP_DIR}" -iname "*.nse" 2>/dev/null | sort \
      | fzf -m --ansi \
      -d / --with-nth=-1 \
      --preview "${preview}" \
      --bind "ctrl-d:preview-page-down,ctrl-u:preview-page-up" \
      --bind "ctrl-j:preview-down,ctrl-k:preview-up"

    )
  )
  SCRIPT=$(basename "${FILE_TO_OPEN}" | sed 's/\.nse$//')
  _send_keys_to_terminal "nmap --script ${SCRIPT} $*"
}

## [simple_mitm]
#  This acts as a very rudimentary mitm tool.
#  It works by establishing a TLS tunnel to a remote host and then listens on
#  a local port (2323, by default) for requests.
#  The intended use here is to send plaintext requests to the local listener
#  and the proxy will encrypt the requests and send them over the tunnel.
#
#  Args:
#    -h|--host [HOST]         Remote host to establish the TLS tunnel with
#  Options:
#    -l|--listen-port [PORT]  Local port to listen on, defaults to 2323
#    -p|--port [PORT]         Remote port to connect to, defaults to 443
#    -s|--silent              Disable messages about connections, default is not silent
#  Example:
#    simple_mitm -h www.google.com -p 443 -l 2222 && curl -H 'host: www.google.com' http://localhost:2222
function simple_mitm() {
  local MESSAGES="-d -d"
  local HOST=
  local LISTEN_PORT=2323
  local REMOTE_PORT=443

  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--host)
        HOST="$2"
        shift
        shift
        ;;
      -l|--listen-port)
        LISTEN_PORT="$2"
        shift
        shift
        ;;
      -p|--port)
        REMOTE_PORT="$2"
        shift
        shift
        ;;
      -s|--silent)
        MESSAGES=
        shift
        ;;
      *)
        echo "Usage: simple_mitm -h|--host HOST [-s|--silent, -p|--port (443 by default) [PORT], -l|--listen-port (2323 by default) [PORT]]"
        return 1
        ;;
    esac
  done

  if [[ -z $HOST ]]; then
    echo "host is required"
    echo "Usage: simple_mitm -h|--host HOST [-s|--silent, -p|--port (443 by default) [PORT], -l|--listen-port (2323 by default) [PORT]]"
    return 1
  fi

  # shellcheck disable=SC2086
  socat $MESSAGES TCP-LISTEN:"$LISTEN_PORT",fork openssl:"$HOST":"$REMOTE_PORT",verify=0

}

## [diff HOSTNAME]  ->  Alias
#  Simple alias for [openssl s_client] that only takes a single [HOSTNAME] and connects over port 443
function openssl_client() {
  if [[ $# -ne 1 ]]; then
    echo "This is a simple client. Must pass in just the hostname"
    return 1
  fi
  local HOST=$1
  openssl s_client -connect "${HOST}":443
}

function ffnet() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

