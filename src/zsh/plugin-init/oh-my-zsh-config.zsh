#!/usr/bin/env zsh

export ZSH="$OSA_EXTERNAL_LIBS/oh-my-zsh"

# Set default theme to powerlevel10k if available
if [[ -f "$OSA_EXTERNAL_LIBS/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  source $OSA_EXTERNAL_LIBS/powerlevel10k/powerlevel10k.zsh-theme
  ZSH_THEME="powerlevel10k/powerlevel10k"
else
  ZSH_THEME="robbyrussell"  # Fallback to oh-my-zsh default theme
fi

autoload -U promptinit; promptinit

# Build plugins array, checking for availability
local -a plugins_list=(git colorize pip python brew macos)

# Add zsh-syntax-highlighting only if available
if [[ -d "$OSA_EXTERNAL_LIBS/zsh-syntax-highlighting" ]]; then
  plugins_list+=(zsh-syntax-highlighting)
fi

# Add evalcache only if available
if [[ -d "$OSA_EXTERNAL_LIBS/evalcache" ]]; then
  plugins_list=(evalcache ${plugins_list[@]})
fi

plugins=(${plugins_list[@]})


source $OSA_EXTERNAL_LIBS/oh-my-zsh/oh-my-zsh.sh