#!/usr/bin/env bash

## [download-certificate DOMAIN]
#  Downloads a certificate chain for a [DOMAIN]
#
#  DOMAIN   = String formatted as json
#  RETURN  ->
#    Full certificate chain for [DOMAIN], saved to disk
function download-certificate() {
  local REMOTE_HOST="${1}"
  if [[ -z $1 || $# -ne 1 ]]; then
    echo "usage: download-certificate <domain>"
    return 1
  fi

  echo \
      | openssl s_client -showcerts -servername "${REMOTE_HOST}" -connect "${REMOTE_HOST}":443 \
       | sed -n -e '/-.BEGIN/,/-.END/ p' \
       | awk 'split_after == 1 {n++;split_after=0}/-----END CERTIFICATE-----/ {split_after=1}{if(!n){n=0}; out="cert-downloaded-" n ".pem"; print >out}'
      #| awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert-downloaded-"a".pem"; print >out}'

  for cert in cert-downloaded-*.pem; do
    mv "${cert}" "${cert/cert-downloaded/${REMOTE_HOST}}"
  done
}

## [add-to-keystore KEYSTORE_ENTRY CERTIFICATE_PATH]
#  Given a java keystore, add an try to it
#
#  KEYSTORE_ENTRY    = Name of the entry
#  CERTIFICATE_PATH  = Path to the certificate, on disk
#  RETURN  ->
#    Updates the certificate store with the new cert
function add-to-keystore() {
  local KEYSTORE_ENTRY="${1}"
  local CERTIFICATE_PATH="${2}"
  if [[ -z $1 || -z $2 || $# -ne 2 ]]; then
    echo "usage: add-to-keystore <keystore-entry-name> <certificate-path>"
    return 1
  fi

  sudo keytool -import -alias "${KEYSTORE_ENTRY}" -file "${CERTIFICATE_PATH}" -keystore "$(/usr/libexec/java_home)/lib/security/cacerts"
}

## [remove-fromkeystore KEYSTORE_ENTRY]
#  Given a java keystore, add an try to it
#
#  KEYSTORE_ENTRY    = Name of the entry
#  RETURN  ->
#    Updates the certificate store and removes the [KEYSTORE_ENTRY]
function remove-from-keystore() {
  local KEYSTORE_ENTRY="${1}"
  if [[ -z $1 || $# -ne 1 ]]; then
    echo "usage: add-to-keystore <keystore-entry-name>"
    return 1
  fi

  sudo keytool -delete -alias "${KEYSTORE_ENTRY}" -keystore "$(/usr/libexec/java_home)/lib/security/cacerts"
}

## [verify-cert-in-keystore KEYSTORE_ENTRY]
#  Checks to make sure [KEYSTORE_ENTRY] was succesfully added to the keystore
#
#  KEYSTORE_ENTRY    = Name of the entry
#  RETURN  ->
#    Updates the certificate store and removes the [KEYSTORE_ENTRY]
function verify-cert-in-keystore() {
  local CERTIFICATE_PATH="${1}"
  if [[ -z $1 || $# -ne 1 ]]; then
    echo "usage: verify-cert-in-keystore <certificate-path>"
    return 1
  fi

  printf "\n" | keytool -list -keystore "$(/usr/libexec/java_home)/lib/security/cacerts" 2>/dev/null | grep -B1 "$(openssl x509 -noout -fingerprint -sha256 -inform pem -in "${CERTIFICATE_PATH}" | cut -d= -f2)"
}
