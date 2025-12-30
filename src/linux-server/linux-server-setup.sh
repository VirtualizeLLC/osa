#!/bin/bash

# Meant for copy pasting into linux server and running this script
# touch linux-server-setup.sh
# nano linux-server-setup.sh
# (paste the contents of this file)
# chmod +x linux-server-setup.sh

# Install essential packages for a Linux server
sudo apt install -y openssh-server tmux git curl build-essential wget htop unzip zip

# Default shell to zsh
if ! [ -x "$(command -v zsh)" ]; then
  sudo apt install -y zsh
fi

chsh -s $(which zsh)

# Install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# # mount utm volume share + add user permissions to read/write/modify/execute
# sudo mount -t 9p \
#   -o trans=virtio,version=9p2000.L,uid=$(id -u),gid=$(id -g) \
#   share /mnt/share