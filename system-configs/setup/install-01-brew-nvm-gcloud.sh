#!/bin/bash
# vim: set foldmethod=marker foldlevel=0 nomodeline:

# ============================================================================
# Don't source script and set -e -o pipefail {{{1
# ============================================================================

(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi

set -e -o pipefail

# }}}}
# ============================================================================
# Helper Functions {{{1
# ============================================================================

function countdown() {
  local SECONDS=
  if [[ -z $1 ]]; then
    SECONDS=$1
  else
    SECONDS=5
  fi
  for i in $(seq "${SECONDS}" 1); do
    echo "${i}..."
    sleep 1
  done
}

# }}}}
# ============================================================================
# Linux w/Apt: Install dependencies {{{1
# ============================================================================

if apt-get --version 1>/dev/null 2>&1; then
  sudo apt-get update -y && sudo apt-get install -y build-essential clang
elif yum --version 1>/dev/null 2>&1; then
  sudo yum groupinstall -y 'Development Tools'
  sudo yum install -y clang
fi

# }}}}
# ============================================================================
# Install Brew and NVM {{{1
# ============================================================================

echo "Installing Brew and NVM"
countdown 5

# Install brew first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# }}}}
# ============================================================================
# OSX: we need zsh to call bash. Update zprofile and zshrc to do so {{{1
# ============================================================================

if [[ $(uname -s) == "Darwin" ]]; then
  (
    ## At a high level this code:
    #  1. Makes sure there is a .zprofile
    #  2. Adds the brew shellenv initialization to the zprofile
    #  3. exports ~/bin to the zsh PATH
    #  4. Makes sure the last thing that happens in the zshrc is 'bash'
    #     In other words, executes bash from the zsh
    #
    #  This is all just a hacky workaround rather than making chsh work and
    #  overwriting the builtin bash, because I was afraid that would do something
    #  weird.
    if [[ ! -e ~/.zprofile ]]; then
      touch ~/.zprofile
    fi

    ARCH="$(uname -p)"
    if [[ $ARCH == "arm" ]]; then
      # shellcheck disable=SC2016
      if ! grep -F 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile > /dev/null; then
        echo '' >> ~/.zprofile
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
      fi
    else
      # shellcheck disable=SC2016
      if ! grep -F 'eval "$(/usr/local/Homebrew/bin/brew shellenv)"' ~/.zprofile > /dev/null; then
        echo '' >> ~/.zprofile
        echo 'eval "$(/usr/local/Homebrew/bin/brew shellenv)"' >> ~/.zprofile
      fi
    fi

    # shellcheck disable=SC2016
    if ! grep -F 'export PATH=~/bin${PATH+:$PATH}' ~/.zprofile > /dev/null; then
      echo 'export PATH=~/bin${PATH+:$PATH}' >> ~/.zprofile
    fi

    if [[ ! -e ~/.zshrc ]]; then
      cat <<EOM > ~/.zshrc
#!/bin/zsh

bash
EOM
    elif ! grep '^[[:space:]]*bash[[:space:]]*$' ~/.zshrc > /dev/null; then
      echo '' >> ~/.zshrc
      echo 'bash' >> ~/.zshrc
    fi
  )
fi

# }}}}
# ============================================================================
# OSX: Clean up some NVM stuff from the zsh and zprofile {{{1
# ============================================================================

if [[ $(uname -s) == "Darwin" ]]; then
  (
    # Since vim/nvim rely on nvm/node make a little helper
    # command that gets the NVM path in place place before
    # running vim
    if ! grep -F 'function vim() {' ~/.zshrc >/dev/null; then
    cat <<'EOM' >> ~/.zshrc

function vim() {
  if ! env | grep NVM_DIR >/dev/null
  then
    export NVM_DIR=~/.nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi
  /usr/bin/vim $@
}

alias vi=vim
EOM
    fi
  )
fi
# }}}}
# ============================================================================
# Install CLI packages via Brew and add fzf bash completition {{{1
# ============================================================================

echo "Installing cli packages"
countdown 5
(

  ## brew in path
  if [[ -r /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -r /usr/local/Homebrew/bin/brew ]]; then
    eval "$(/usr/local/Homebrew/bin/brew shellenv)"
  elif [[ -r /home/linuxbrew/.linuxbrew/bin ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  ## For linux, set the number of open files really high for brew
  #  packages with huge dependencies can cause issues otherwise
  if [[ "$(uname -s)" == "Linux" ]]; then
    ulimit -n 65535
  fi

  brew update
  brew upgrade
  brew update
  brew install autoconf automake bc bat coreutils cowsay curl fd fx fzf gh git \
               git-delta grpcurl htop jq neovim nmap pstree pup pv \
               python3 ripgrep shellcheck shtool socat sponge sqlite terraform \
               tmux tree tree-sitter util-linux vim watch wget xz yq termshark \
               websocat dhcping ldns fping iftop iperf iperf3 w3m fswatch pigz \
               task taskwarrior-tui terraform-ls bashdb ruff ranger imagemagick \
               mise lua docker csvkit go

  # Useful but not really super core packages
  brew install gpatch gpatch guile lazygit maven poppler protobuf

  ## Instal OS Specific Apps and CLI tools
  if [[ $(uname -s) == "Darwin" ]]; then
    echo "OSX: Installing cli tools that conflict on linux systems"
    countdown 3
    # bash-completion conflicts with util-linux
    # qt has an huge dependency stack and really isn't useful
    #   for our linux installs, since we normally don't have a GUI
    #   May revisit at some point in the future
    #   Consider installing wiht the builtin package manager
    brew install bash-completion@2 qt

    echo "OSX: Installing pam module for touch id"
    countdown 3
    brew install pam-reattach
  fi

  { echo y; echo y; echo n; } | "$(brew --prefix)"/opt/fzf/install
)

# }}}}
# ============================================================================
# Install gcloud for all platforms and iTerm for OSX {{{1
# ============================================================================

(
  if [[ $(uname -s) == "Darwin" ]]; then
    echo "OSX: Installing casks for iterm and gcloud"
    countdown 3
    brew install mitmproxy jwt-cli 1password-cli
    brew install --cask iterm2 || true
    brew install --cask kitty || true
    brew install --cask visual-studio-code || true
    brew remove google-cloud-sdk -f || true
    brew install google-cloud-sdk
  elif [[ $(uname -s) == "Linux" ]]; then
    echo "Installing google cloud CLI directly from tar.gz"
    countdown 5
    if [[ ! -d ~/bin/source ]]; then
      mkdir -p ~/bin/source
    fi
    # shellcheck disable=SC2164
    cd ~/bin/source
    if [[ ! -d google-cloud-sdk ]]; then
      curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
      tar -xf google-cloud-cli-linux-x86_64.tar.gz
      rm google-cloud-cli-linux-x86_64.tar.gz
      { echo n; echo n; } | ./google-cloud-sdk/install.sh
      ln -sf ~/bin/source/google-cloud-sdk/bin/gcloud ~/bin/gcloud
    fi
  fi
)

# }}}}
# ============================================================================

echo "${BASH_SOURCE[0]}: Completed installation succesfully!"
