#!/bin/bash

## Just copy and paste this entire script to clipboard and paste into vps
#  terminal

## NOTE: This script only works if the user doesn't exist.
#  run: [userdel -r <USER>] before running this script

# From the root user: Add new user
(
  set -e -o pipefail
  export EDITOR=vi
  NEW_USER=sagar
  NEW_USER_GROUP=
  NEW_USER_SUDO_GROUP=

  if grep -Eqi '^ID=(.*ubuntu.*|.*debian.*)' /etc/os-release; then
    NEW_USER_GROUP=staff
    NEW_USER_SUDO_GROUP=sudo
    sudo apt-get -qq install -y git screen
  elif grep -Eqi '^ID=(.*rocky.*|.*fedora.*|.*rhel.*|.*centos.*)' /etc/os-release; then
    NEW_USER_GROUP=users
    NEW_USER_SUDO_GROUP=wheel
    if grep -Eqi '^ID=(.*rocky.*)' /etc/os-release; then
      sudo yum install -y -q epel-release
    fi
    sudo yum install -y -q git screen
  fi

  useradd -m "${NEW_USER}" -g "${NEW_USER_GROUP}" -G "${NEW_USER_SUDO_GROUP}"

  mkdir -p /home/"${NEW_USER}"/.ssh
  chmod 700 /home/"${NEW_USER}"/.ssh
  cp -f ~/.ssh/authorized_keys /home/"${NEW_USER}"/.ssh/
  touch /home/"${NEW_USER}"/.ssh/authorized_keys
  chmod 600 /home/"${NEW_USER}"/.ssh/authorized_keys

  echo "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBG4PL+No4yd0Wd+NCWVp/PSATC6eDUExTz7+hEiiXcLIEY1LB6BSptUz/04kouEXXMJ2gappdk9Dia1cIsOqlII= ${NEW_USER}@laptop" >> /home/"${NEW_USER}"/.ssh/authorized_keys
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBq7MLfDk1oXBwkAelYoMrHoCLs2WNkhULDxS/Fcwj9+ sagarmomin@Sagar-macbook-pro" >> /home/"${NEW_USER}"/.ssh/authorized_keys
  chown -R "${NEW_USER}":${NEW_USER_GROUP} /home/"${NEW_USER}"/.ssh
  sed -Ei.bak "s|(${NEW_USER}.*/home/${NEW_USER}):.*|\1:/bin/bash|" /etc/passwd && rm -f /etc/passwd.bak

  ## Make sudo passwordless, this is useful right now while I keep rebuilding
  #  my vps for testing. Eventually I'll want to purge this
  if ! grep -qF "${NEW_USER} ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo -e "\n${NEW_USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
  fi

  # Set a new password for the user
  while ! passwd "${NEW_USER}"; do : ; done

  # Clone the repo and run the installation in screen
  su - "${NEW_USER}" -c 'git clone https://github.com/moobar/vim-and-system-configs.git && ln -s vim-and-system-configs ~/.vim'
  if type tmux; then
    su - "${NEW_USER}" -c 'tmux new -s bootstrap bash ~/.vim/system-configs/install-everything.sh'
  else
    su - "${NEW_USER}" -c 'screen -S bootstrap bash ~/.vim/system-configs/install-everything.sh'
  fi
  su - "${NEW_USER}" -c 'sed -i "s/prefix C-g/prefix C-f/" ~/.tmux.conf'
)

