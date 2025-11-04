#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function get_git_root_of_script() {
  cat << 'EOM'
"$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null)"
EOM
}

function get_cwd_of_script() {
  cat << 'EOM'
"$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
EOM
}

function dont-source-script() {
  cat << 'EOM'
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi
EOM
}

function robust-while-loop() {
  echo "This reads in a file, handles when the file has no newline at the end and puts it in FD 3 to avoid STDIN conflicts"
  echo "  -----  "
  cat << 'EOM'
while read -r line <&3 || [[ -n "$line" ]]; do
  k="$(awk -F '=' '{print $1}' <<< "${line}")"
  if [[ "${k,,}" == "${KEY,,}" ]]; then
    cut -d '=' -f2- <<< "${line}"
    return 0
  fi
done 3< "${FILE}"
EOM

  echo ""
  echo "Using a safer approach with the redirects at the end, which will always work:"
  echo "  -----  "
  cat << 'EOM'
while read -r line || [[ -n "$line" ]]; do
  k="$(awk -F '=' '{print $1}' <<< "${line}")"
  if [[ "${k,,}" == "${KEY,,}" ]]; then
    cut -d '=' -f2- <<< "${line}"
    return 0
  fi
done 3< "${FILE}" <&3
EOM
}

function debug-gke-node() {
  cat << 'EOM'
# 1. Find the node
kubectl get pods -o=wide | grep POD_NAME

# 2. ssh to the node with fgcloud-ssh
fgcloud-ssh

# 3. Find the process associated witht he pod
sudo ps auxwww | grep -F POD_NAME
sudo ps auxwww | grep -F POD_NAME | grep -Fv 'grep' | awk '{print $2}'

# 4. Inspect memory maps
sudo pmap -x PID
sudo pmap -x PID | grep -F anon | sort -nk3 | tail -10

# 5. Inspect raw memory
sudo xxd -s 0xMAP_ADDRESS -l BYTES_TO_INSPECT -g1 /proc/PID/mem

# example: sudo xxd -s 0x00007d62a0000000 -l 1024 -g1 /proc/2724172/mem

# 6. Need more? Try sudo toolbox
# https://cloud.google.com/kubernetes-engine/distributed-cloud/vmware/docs/troubleshooting/toolbox
sudo toolbox

EOM
}

function print-function-name() {
  cat << 'EOM'
# Refers to the name of the currently executing function.
${FUNCNAME[0]}

# Refers to the name of the calling function.
${FUNCNAME[1]}
EOM
}

function pipe-from-stdin-or-use-args() {
  cat << 'EOM'
# Check if anything is in stdin
# [cat] is a way to get the input out of stdin
if test ! -t 0; then
  cat | COMMAND_ASSUMING_DATA_FROM_STDIN
else
  if [[ -z "${1}" ]]; then
    echo "Expecting input or with an ARG"
    return 1
  fi

  COMMAND_WITHOUT_STDIN "$@"
fi
EOM
}

function yn_prompt-function() {
  cat << 'EOM'
yn_prompt() {
  if [[ -z $1 ]]; then
    echo "Must supply a prompt message"
    return 1
  fi
  local PROMPT="$1"
  local YN=""

  echo -n "${PROMPT} [y/N]: "
  read -r YN
  if [[ "$YN" == [Yy] || "$YN" == [Yy][Ee][Ss] ]]; then
    return 0
  else
    return 1
  fi
}
EOM
}

function make_script_fzfable() {
  echo "${BASH_FZF_IN_SOURCED_SCRIPT}"
}

function common_footer_for_scripts() {
  echo "${BASH_COMMON_SCRIPT_FOOTER}"
}

function ffbashcode() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

