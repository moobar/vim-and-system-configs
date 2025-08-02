#!/bin/bash

CONFIGROOT_DIR_SCRIPT="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
if [ -f "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh" ]; then
  # shellcheck disable=SC1091
  source "${CONFIGROOT_DIR_SCRIPT}/system-configs/bash-script-commons/heredoc_bash_macros.sh"
fi

function reinstall-vscode-extensions() {
  code --list-extensions > /tmp/vscode-extensions.txt
  rm -rf /tmp/failed-vscode-extensions.txt

  while read -r extension || [[ -n "$extension" ]]; do
    if ! code --uninstall-extension "${extension}"; then
      echo "WARN:   Unable to uninstall ${extension}" | tee -a /tmp/failed-vscode-extensions.txt
      continue
    fi
    if ! code --install-extension "${extension}"; then
      echo "ERROR!: Unable to reinstall ${extension} !!" | tee -a /tmp/failed-vscode-e:waxtensions.txt
      continue
    fi

  done 3< "/tmp/vscode-extensions.txt" <&3

  echo "List of errors and warnings"
  cat /tmp/failed-vscode-extensions.txt
}

function ffvscode() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

