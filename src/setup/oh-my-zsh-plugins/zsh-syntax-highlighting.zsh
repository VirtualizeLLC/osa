cloneTarget=$OSA_EXTERNAL_LIBS/zsh-syntax-highlighting

if [[ ! -d $cloneTarget ]]; then
    if [[ "$OSA_VERBOSE" == "true" ]]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $cloneTarget
    else
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $cloneTarget > /dev/null 2>&1
    fi
fi

# To link with oh-my-zsh this will need to be symlinked into the plugins section