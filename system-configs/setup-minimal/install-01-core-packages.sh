#!/bin/bash

# From the root user: Add new user
(
  set -e -o pipefail
  if grep -Eqi '^ID=(.*ubuntu.*|.*debian.*)' /etc/os-release; then
    sudo apt-get -qq install -y wget git tmux ripgrep fzf vim pup jq bc bat lsof netcat
    # curl https://sh.rustup.rs -sSf -o rust-install.sh && bash rust-install.sh -y -q && rm rust-install.sh
    # cargo install git-delta
  elif grep -Eqi '^ID=(.*rocky.*|.*fedora.*|.*rhel.*|.*centos.*)' /etc/os-release; then
    if grep -Eqi '^ID=(.*rocky.*)' /etc/os-release; then
      sudo yum install -y -q epel-release
    fi
    sudo yum install -y -q wget git tmux ripgrep fzf vim pup jq bc bat lsof netcat
    # curl https://sh.rustup.rs -sSf -o rust-install.sh && bash rust-install.sh -y -q && rm rust-install.sh
    # cargo install git-delta
  elif [[ $(uname -s) == "Darwin" ]]; then
    # Install brew first
    if ! brew 2>/dev/null >/dev/null; then
      echo "Installing Brew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install git-delta wget git tmux ripgrep fzf vim pup jq bc bat lsof netcat
  fi
)


