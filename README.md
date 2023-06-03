# terminal-configs

Get started by downloading this repo and symlinking or renaming to ~/.vim

## Install Minimal

No frills install that disables coc.nvim until node is intalled

```bash
git clone https://github.com/moobar/vim-and-system-configs.git && ln -s vim-and-system-configs ~/.vim
bash ~/.vim/system-configs/install-minimal.sh

# To disable auto upgrading the terminal, also copy
touch ~/.vim/.disable_auto_upgrade
```

## Install Minimal, with Node

Minimal install which also installs node so coc.nvim works

```bash
git clone https://github.com/moobar/vim-and-system-configs.git && ln -s vim-and-system-configs ~/.vim
bash ~/.vim/system-configs/install-minimal-with-node.sh

# To disable auto upgrading the terminal, also copy
touch ~/.vim/.disable_auto_upgrade
```

## Install

Install brew, node, gcloud and lots of useful packages. Can take up to an hour to complete

```bash
git clone https://github.com/moobar/vim-and-system-configs.git && ln -s vim-and-system-configs ~/.vim
bash ~/.vim/system-configs/install-everything.sh
```

## Overview

Configs get you started with nvim as an IDE, via coc. Languages that should
work out of the box.

* c, cpp
* java
* python
* go
* md

Also I use Amethyst for window tiling

## WIP

* Better organizatino for the vimrc that's loaded after plugings
* Better vimrc settings, based on jungegunn's dotfiles (sponsor him!)
* Support for other OS's besides makes
  * Probably just ubuntu and debian
