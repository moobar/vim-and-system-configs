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
      sleep 1
    fi
    if ! code --install-extension "${extension}"; then
      echo "ERROR!: Unable to reinstall ${extension} !!" | tee -a /tmp/failed-vscode-e:waxtensions.txt
      sleep 1
    fi

  done 3< "/tmp/vscode-extensions.txt" <&3

  echo "List of errors and warnings"
  cat /tmp/failed-vscode-extensions.txt
}


function instructions-to-run-fix-copilot() {
  local UPDATED_NORTH_AGENT_CONFIG_B64=""
  clear
  cat <<EOM
## Purge Copilot Dirs ##

# GlobalStorage
ls ~/Library/Application\ Support/Code/User/globalStorage/github.copilot-chat/
# Delete it
rm -rf ~/Library/Application\ Support/Code/User/globalStorage/github.copilot-chat/


# Cached Extension
## Uninstall Copiilot Chat Extension and Restart
# 1. CMD+SHIFT+X (Extension View)
# 2. Uninstall Copilot and Copilot Chat
# 3. Restart Extensinos

# Check and Delete Extension Cache
ls ~/.vscode/extensions/github.copilot-*
# Delete
rm -rf ~/.vscode/extensions/github.copilot-*


## Install Copiilot Chat Extension

EOM

  echo "Enter to continue, CTRL-C to exit"
  read -r _;
  clear
  cat <<EOM
## Reinstall extensions ##

# This is not fully fleshed out. You need to read the warnings and make sure you didn't lose any extensions!
reinstall-vscode-extensions

EOM

  echo "Enter to continue, CTRL-C to exit"
  read -r _;
  clear
  cat <<EOM
## Restart vscode ##

# CTRL-Q

EOM
}

function ffvscode() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"

