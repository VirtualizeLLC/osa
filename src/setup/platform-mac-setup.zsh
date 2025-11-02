#!/usr/bin/env zsh

# install java
source $OSA_CONFIG/src/setup/brew-install-java.zsh

# jenv to manage the java sdks
# ls -1 /Library/Java/JavaVirtualMachines
# jenv add <path>
source $OSA_CONFIG/src/setup/install-jenv.zsh

# rbenv
source $OSA_CONFIG/src/setup/install-rbenv.zsh

# Git
source $OSA_CONFIG/src/setup/git.zsh

get-node-version(){
  # If DEFAULT_NODE_VERSION is set, prefer it as the source of truth
  if [ -n "$DEFAULT_NODE_VERSION" ] ; then
    echo "$DEFAULT_NODE_VERSION"
    return 0
  fi

  # Otherwise, if the repo provides a .node-version file, use it
  if [ -f "$OSA_CONFIG/.node-version" ]; then
    cat "$OSA_CONFIG/.node-version"
  else
    echo "lts"
  fi
}

if ! [ $(command -v perl) ]; then
  brew install perl
fi

# FNM install
# Its 40x faster than NVM
# https://github.com/Schniz/fnm
if ! [ $(command -v fnm) ]; then
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir $HOME/.fnm --skip-shell
  eval "$(fnm env)"
  fnm install "$(get-node-version)"
fi

# nvm install
# https://github.com/nvm-sh/nvm#git-install
# if ! [[ $(command -v nvm) || -d $HOME/.nvm ]]; then
#   git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm && cd $HOME/.nvm && git checkout v0.39.1
#   cd $OSA_CONFIG
# fi

source $OSA_CONFIG/src/setup/setup-xcode-node-file-permissions.zsh

# direnv
[ $(command -v direnv) ] || brew install direnv