#!/bin/bash

# Snippets meant for quickly setting up a Linux server environment.

# essential packages

sudo apt install -y openssh-server tmux git curl build-essential wget htop unzip zip mount

# list ip addresses to connect openssh-server (so you can copy paste from native OS via ssh + vim/nano/vscode)
ip addr show

# Mount UTM volume via mount command