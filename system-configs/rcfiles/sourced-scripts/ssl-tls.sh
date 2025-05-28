#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

# View a PEM-encoded certificate:
function certs-view-pem-or-crt() {
  if [[ $# -eq 0 ]]; then
    echo "You probably want to add -in <FILE>"
    return 1
  fi
  openssl x509 -noout -text "$@"
}

# View a certificate encoded in PKCS#7 format:
function certs-view-pkcs7() {
  if [[ $# -eq 0 ]]; then
    echo "You probably want to add -in <FILE>"
    return 1
  fi
  openssl pkcs7 -print_certs -noout -text "$@"
}

# Print PEM certificates encoded in PKCS#7 format:
function certs-print-pkcs7() {
  if [[ $# -eq 0 ]]; then
    echo "You probably want to add -in <FILE>"
    return 1
  fi
  openssl pkcs7 -print_certs "$@"
}

# Verify and display a key pair:
function rsa-key-verify-and-print() {
  if [[ $# -eq 0 ]]; then
    echo "You probably want to add -in <FILE>"
    return 1
  fi
  openssl rsa -noout -text -check "$@"
}

# Check and display a certificate request (CSR):
function certs-csr-verify-and-print() {
  if [[ $# -eq 0 ]]; then
    echo "You probably want to add -in <FILE>"
    return 1
  fi
  openssl req -noout -text -verify "$@"
}

# Verify an SSL connection and display all certificates in the chain:
function cert-connect-to-host-and-verify() {
  if [[ $# -ne 1 ]]; then
    echo "You must provide <HOST:PORT>"
    return 1
  fi

  openssl s_client -connect "${1}"
}

# sclient
function openssl-s_client() {
  if [[ $# -eq 0 ]]; then
    echo "You probably want to add -connect <HOST:PORT>"
    return 1
  fi

  openssl s_client "$@"
}

function bash-convert-x509-to-pem() {
  echo 'openssl x509 -in <CRT_or_PEM> -outform pem -out <NEW_PEM_FILE>.pem'
}

function bash-convert-pkcs7-to-pem() {
  echo 'openssl pkcs7 -print_certs -in <BUNDLE>.p7b -out <NEW_PEM_BUNDLE>.pem'
}

function bash-convert-pem-to-pkcs7(){
  echo 'openssl crl2pkcs7 -nocrl -certfile <PEM_OR_CRT> -out <BUNDLE>.p7b'
}


function make_script_fzfable() {
  echo "${BASH_FZF_IN_SOURCED_SCRIPT}"
}

function common_footer_for_scripts() {
  echo "${BASH_COMMON_SCRIPT_FOOTER}"
}

function ffssl() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

