# terminal-configs

Get started by downloading this repo and symlinking or renaming to ~/.vim

## Install Minimal

No frills install that disables coc.nvim until node is intalled

```bash
git clone https://github.com/moobar/vim-and-system-configs.git && ln -s vim-and-system-configs ~/.vim
bash ~/.vim/system-configs/install-minimal.sh

# To disable auto upgrading the terminal, also copy
touch ~/.vim/.disable_auto_upgrade

# If running on a VPC change prefix to C-f
sed -i 's/prefix C-g/prefix C-f/' ~/.tmux.conf
```

## Install Minimal, with Node

Minimal install which also installs node so coc.nvim works

```bash
git clone https://github.com/moobar/vim-and-system-configs.git && ln -s vim-and-system-configs ~/.vim
bash ~/.vim/system-configs/install-minimal-with-node.sh

# To disable auto upgrading the terminal, also copy
touch ~/.vim/.disable_auto_upgrade

# If running on a VPC change prefix to C-f
sed -i 's/prefix C-g/prefix C-f/' ~/.tmux.conf
```

## Install Locally

Install brew, node, gcloud and lots of useful packages. Can take up to an hour to complete

```bash
git clone https://github.com/moobar/vim-and-system-configs.git && ln -s vim-and-system-configs ~/.vim
bash ~/.vim/system-configs/install-everything.sh
```

### VS Code
Switch to VS Code, and sync extensions (sign in) and settings [settings.json]

Open settings and update 'Window: Zoom Level' 
* For 13" MBA, with Resolution set to `2560 x 1664` --> Set to: `2`
* For 14" MBP, with Resolution set to `2294 x 1490` --> Set to: `1` 

## Install on a VPS

Install brew, node, gcloud and lots of useful packages. Can take up to an hour to complete

From OSX
```bash
cat linux-bootstrap.sh | pbcopy
```

Otherwise copy this script
https://github.com/moobar/vim-and-system-configs/blob/main/system-configs/vps-setup/linux-bootstrap.sh

```bash
ssh root@SERVER
# <Paste contents of linux-bootstrap directly into the terminal>
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
