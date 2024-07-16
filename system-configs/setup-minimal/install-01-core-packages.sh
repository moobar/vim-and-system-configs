#!/bin/bash

# From the root user: Add new user
(
  set -e -o pipefail

  if ! type sudo >/dev/null 2>&1; then
    function sudo() {
      "$@"
    }
  fi

  if grep -Eqi '^ID=(.*ubuntu.*|.*debian.*)' /etc/os-release 2>/dev/null ; then
    sudo apt-get -qq install -y wget git tmux ripgrep fzf vim pup jq bc bat lsof netcat htop taskwarrior
    sudo wget -qO /usr/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64

    # curl https://sh.rustup.rs -sSf -o rust-install.sh && bash rust-install.sh -y -q && rm rust-install.sh
    # cargo install git-delta
  elif grep -Eqi '^ID=(.*rocky.*|.*fedora.*|.*rhel.*|.*centos.*)' /etc/os-release 2>/dev/null; then
    if grep -Eqi '^ID=(.*rocky.*)' /etc/os-release; then
      sudo yum install -y -q epel-release
    fi
    sudo yum install -y -q wget git tmux ripgrep fzf vim pup jq bc bat lsof netcat htop taskwarrior
    sudo wget -qO /usr/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64

    # curl https://sh.rustup.rs -sSf -o rust-install.sh && bash rust-install.sh -y -q && rm rust-install.sh
    # cargo install git-delta
  elif [[ $(uname -s) == "Darwin" ]]; then
    # Install brew first
    if ! brew 2>/dev/null >/dev/null; then
      echo "Installing Brew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    ARCH="$(uname -p)"
    if [[ $ARCH == "arm" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/Homebrew/bin/brew shellenv)"
    fi

    brew install git-delta wget git tmux ripgrep fzf vim pup jq yq bc bat lsof netcat htop task bashdb
  fi
)


