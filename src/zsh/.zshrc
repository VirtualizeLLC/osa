 #! /bin/zsh
# The .zshrc file references files from the $USER root directory. See initialize-symlinks for how to generate these symlinks
#   Based on user_specified priority of files.
    # All files will be loaded in the following order
        # 1. initial
        # 2. platform
        # 3. base
        # 4. final

# all variables come from this file. These variables are reused in other scripts.
# path must use HOME path for constants/paths.zsh
source "$HOME/.osa/src/zsh/constants/paths.zsh"
source "$OSA_ZSH_CONSTANTS/versions.zsh"

# init file (optional)
    # NOTE useful for adding a bunch of __local__ config files
if test -f $OSA_ZSH_CONSTRUCTORS/init.zsh; then
    source $OSA_ZSH_CONSTRUCTORS/init.zsh
fi

# platform files
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
    $OSA_CONFIG_VERBOSE && echo "adding config: Windows - WSL"
    source $OSA_ZSH_CONSTRUCTORS/platform-wsl.zsh
else
    $OSA_CONFIG_VERBOSE && echo "adding config: mac"
    source $OSA_ZSH_CONSTRUCTORS/platform-mac.zsh
fi
 
# base files
source $OSA_ZSH_CONSTRUCTORS/base.zsh

# final file (optional)
    # NOTE useful for adding a bunch of __local__ config files
if test -f $OSA_ZSH_CONSTRUCTORS/final.zsh; then
    source $OSA_ZSH_CONSTRUCTORS/final.zsh
fi
