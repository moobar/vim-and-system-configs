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


## [_check_network]
#  Simple helper function to bail on upgrade if there is no internet
function _check_network() {
  curl --max-time 1 -s https://ifconfig.io >/dev/null 2>&1
  return $?
}

## [reinstall_java_jdtls_1_9]
#  Sometimes coc-java will install its down lsp server, and it sucks
#  this manually installs the eclipse jdtls
function reinstall_java_jdtls_1_9() {
  (
    mkdir -p ~/.config/coc/extensions/coc-java-data
    cd ~/.config/coc/extensions/coc-java-data || exit 1
    rm -rf -- *
    wget https://download.eclipse.org/jdtls/milestones/1.9.0/jdt-language-server-1.9.0-202203031534.tar.gz
    mkdir -p server
    cd server || exit 1
    tar -xvzf ../jdt-language-server-1.9.0-202203031534.tar.gz
  )
}

## [upgrade_package_managers]
#  Attempts to update npm global backages, brew, vim-plug and coc
function upgrade_package_managers() {
  if ! _check_network; then
    return 1
  fi

  local VERIFY_UPGRADE=
  while [[ $VERIFY_UPGRADE != "y" && $VERIFY_UPGRADE != "n" ]] ; do
    echo "Weekly terminal/package manager upgrade:"
    echo -n "Proceed - "
    read -r -p "y/N?: " VERIFY_UPGRADE
    VERIFY_UPGRADE=$(echo "${VERIFY_UPGRADE}" | tr '[:upper:]' '[:lower:]')
  done

  if [[ $VERIFY_UPGRADE != "y" ]];then
    return 1
  fi

  (
    CONFIGROOT_DIR_SUBSHELL="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
    if [ -f "${CONFIGROOT_DIR_SUBSHELL}/system-configs/bash-script-commons/common.sh" ]; then
      # shellcheck disable=SC1091
      source "${CONFIGROOT_DIR_SUBSHELL}/system-configs/bash-script-commons/common.sh"
    fi
    echo "Weekly Terminal Upgrade Beginning. [CTRL-C] to cancel"
    countdown --seconds 5 --flat
  )

  if type brew &>/dev/null; then
    echo "## Updating Brew.. ##"
    brew update && brew upgrade
    echo "Completed."
    echo ""
  fi

  if type apt-get &>/dev/null; then
    echo "## Updating Apt Packages.. ##"
    sudo apt-get update -y && sudo apt-get upgrade -y
    echo "Completed."
    echo ""
  elif type yum &>/dev/null; then
    echo "## Updating Apt Packages.. ##"
    sudo yum update -y
    echo "Completed."
    echo ""
  fi

  echo "## Updating npm global packages.. ##"
  if type npm &>/dev/null; then
    npm -g upgrade
    npm -i bash-language-server
    echo "Completed."
    echo ""
  fi

  echo "## Updating pip ##"
  python3 -m pip install --upgrade pip

  echo "## Updating outdated python3 pip packages.. ##"
  python3 -m pip list --outdated |
    tail -n +3 |
    awk '{print $1}' |
    sort | uniq |
    xargs -IPACKAGE python3 -m pip install --upgrade PACKAGE

  echo "## Reinstalling core pip packages, in case it requires and outdated packaged ##"
  local CONFIGROOT_DIR_LOCAL=
  CONFIGROOT_DIR_LOCAL="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
  bash "${CONFIGROOT_DIR_LOCAL}/system-configs/setup/install-03-python-packages.sh"
  echo "Completed."
  echo ""

  echo "## Updating Vim Plug.. ##"
  if type nvim &>/dev/null; then
    nvim +PlugClean +PlugUpdate +qall
  else
    command vim +PlugClean +PlugUpdate +qall
  fi
  echo "Completed."
  echo ""


  if type node &>/dev/null; then
    echo "## Updating coc-nvim.. ##"
    nvim +CocUpdateAndQuit
    echo "Completed."
    echo ""

    echo "## TreeSitter needs to be updated after CocUpdate ##"
    nvim +TSUpdateSync +qall
    nvim -S "${CONFIGROOT_DIR_LOCAL}/system-configs/setup/vimscript-add-treesitter-modules.vim"
    echo "Completed."
    echo ""

    echo "## Manually reinstalling jdtls (java lsp).. ##"
    reinstall_java_jdtls_1_9
    echo "Completed."
    echo ""
  fi

}

## [auto_upgrade_package_managers]
#  Tries to run the the package manager upgrade once a week
function auto_upgrade_package_managers() {
  if ! _check_network; then
    # For auto upgrades, not going to error because we'll just try again
    return 0
  fi

  # Cache for a week = 60 * 60 * 24 * 7 = 604800
  local CHECK_WEEKLY=604800

  (
    # shellcheck disable=SC2030
    CONFIGROOT_DIR_SUBSHELL="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"
    if [ -f "${CONFIGROOT_DIR_SUBSHELL}/system-configs/bash-script-commons/common.sh" ]; then
      # shellcheck disable=SC1091
      source "${CONFIGROOT_DIR_SUBSHELL}/system-configs/bash-script-commons/common.sh"
    fi

    cache_command \
      --no-cached-output \
      --ttl "${CHECK_WEEKLY}" \
      -d 'terminal-updates' \
      -f "paakage_managers" \
      -x 'upgrade_package_managers'
  )
}

## [auto_upgrade_bash]
#  Function performs upgrades on the custom bash install, once a week
function auto_upgrade_bash() {
  if ! _check_network; then
    # For auto upgrades, not going to error because we'll just try again
    return 0
  fi

  # Cache for a week = 60 * 60 * 24 * 7 = 604800
  local CHECK_WEEKLY=604800

  (
    local SRC_DIR_LOCAL=
    SRC_DIR_LOCAL="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
    # shellcheck disable=SC1091
    source "${SRC_DIR_LOCAL}/get-latest-bash.sh"

    cache_command \
      --no-cached-output \
      --ttl "${CHECK_WEEKLY}" \
      -d 'terminal-updates' \
      -f "${FUNCNAME[0]}" \
      -x 'upgrade_bash'
  )
}


function auto_upgrade_terminal() {
  local CONFIGROOT_DIR_LOCAL=''
  CONFIGROOT_DIR_LOCAL="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && git rev-parse --show-toplevel 2>/dev/null || echo ~/.vim )"

  # shellcheck disable=SC2031
  if [[ -f "${CONFIGROOT_DIR_LOCAL}/.disable_auto_upgrade" ]]; then
    return 0
  fi

  if ! _check_network; then
    # For auto upgrades, not going to error because we'll just try again
    return 0
  fi

  auto_upgrade_bash
  auto_upgrade_package_managers
}

function ffupgrade() {
  eval "${BASH_FZF_IN_SOURCED_SCRIPT}"
}
eval "${BASH_COMMON_SCRIPT_FOOTER}"
