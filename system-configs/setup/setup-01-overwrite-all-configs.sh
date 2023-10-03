#!/usr/bin/env bash

(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ $sourced -ne 0 ]]; then
  echo "Don't source this script. Run it directly"
  return 1
fi

if [[ ! -d ~/.vim || ! -L ~/.vim ]]; then
  echo "This script only works if the ~/.vim directory is there"
  echo "and it's a symbolic link to the github repo"
  return 1
fi

set -e -o pipefail

if [[ -e ~/.inputrc && ! -L ~/.inputrc ]]; then
  mv ~/.inputrc ~/.inputrc.bak."$(date "+%Y-%m-%d")"
fi
rm -rf ~/.inputrc
ln -fs ~/.vim/system-configs/rcfiles/inputrc ~/.inputrc

if [[ -e ~/.vimrc && ! -L ~/.vimrc ]]; then
  mv ~/.vimrc ~/.vimrc.bak."$(date "+%Y-%m-%d")"
fi
rm -rf ~/.vimrc
ln -fs ~/.vim/vimrc ~/.vimrc

if [[ -e ~/.amethyst.yml && ! -L ~/.amethyst.yml ]]; then
  mv ~/.amethyst.yml ~/.amethyst.yml.bak."$(date "+%Y-%m-%d")"
fi
rm -rf ~/.amethyst.yml
ln -fs ~/.vim/system-configs/amethyst-config/amethyst.yml ~/.amethyst.yml

if [[ -e ~/.ideavimrc && ! -L ~/.ideavimrc ]]; then
  mv ~/.ideavimrc ~/.ideavimrc.bak."$(date "+%Y-%m-%d")"
fi
rm -rf ~/.ideavimrc
ln -fs ~/.vim/ideavim/ideavimrc ~/.ideavimrc

if [[  ! -d ~/.config ]]; then
  mkdir -p ~/.config
fi

if [[  ! -d ~/bin/source ]]; then
  mkdir -p ~/bin/source
fi

if [[ -e ~/.config/nvim && ! -L ~/.config/nvim ]]; then
  mv ~/.config/nvim ~/.config/nvim.bak."$(date "+%Y-%m-%d")"
fi
rm -rf ~/.config/nvim
ln -fs ~/.vim/nvim ~/.config/nvim

if [[ -e ~/.config/pylintrc && ! -L ~/.config/pylintrc ]]; then
  mv ~/.config/pylintrc ~/.config/pylintrc.bak."$(date "+%Y-%m-%d")"
fi
rm -rf ~/.config/pylintrc
ln -fs ~/.vim/system-configs/rcfiles/python/pylintrc ~/.config/pylintrc

# If no tmux config exists, make one or add the proper source line
if [[ ! -e ~/.tmux.conf ]]; then
  (
    SRC_DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
    bash "${SRC_DIR}/smash-01-tmux-confg.sh"
  )
else
  if ! grep -qF 'source ~/.vim/system-configs/rcfiles/tmux/tmux.conf' ~/.tmux.conf > /dev/null; then
    # shellcheck disable=SC2129
    echo '' >> ~/.tmux.conf
    echo 'source ~/.vim/system-configs/rcfiles/tmux/tmux.conf' >> ~/.tmux.conf
  fi
fi

# If no gitconfig exists, make one or link the shared gitconfig
if [[ ! -e ~/.gitconfig ]]; then
  (
    SRC_DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
    bash "${SRC_DIR}/smash-02-gitconfig.sh"
  )
else
  if ! grep -qF 'path = ~/.vim/system-configs/git-configs/gitconfig' ~/.gitconfig > /dev/null; then
    (
      SRC_DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
      bash "${SRC_DIR}/append-01-gitconfig.sh"
    )
  fi
fi

# Link bash_profile, but backup existing one first
if [[ -e ~/.bash_profile && ! -L ~/.bash_profile ]]; then
  mv ~/.bash_profile ~/.bash_profile.bak."$(date "+%Y-%m-%d")"
fi
ln -fs ~/.vim/system-configs/rcfiles/bash_profile ~/.bash_profile

# Link bashrc, but backup existing one first
if [[ -e ~/.bashrc && ! -L ~/.bashrc ]]; then
  mv ~/.bashrc ~/.bashrc.bak."$(date "+%Y-%m-%d")"
fi
rm -rf ~/.bashrc
ln -fs ~/.vim/system-configs/rcfiles/bashrc ~/.bashrc

echo "${BASH_SOURCE[0]}: Completed rcfiles setup succesfully!"
