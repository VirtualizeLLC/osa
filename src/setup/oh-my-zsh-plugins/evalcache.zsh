cloneTarget=$OSA_EXTERNAL_LIBS/evalcache

if [[ ! -d "$cloneTarget" ]]; then
    if [[ "$OSA_VERBOSE" == "true" ]]; then
        git clone --depth=1 https://github.com/mroth/evalcache $cloneTarget
    else
        git clone --depth=1 https://github.com/mroth/evalcache $cloneTarget > /dev/null 2>&1
    fi
fi

# To link with oh-my-zsh this will need to be symlinked into the plugins section