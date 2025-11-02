#!/usr/bin/env zsh

REACT_EDITOR="code"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh";
  typeset -g POaWERLEVEL9K_INSTANT_PROMPT=quiet;
fi

# powerlevel10k
[[ ! -f $OSA_ZSH_PLUGINS/p10k.zsh ]] || source $OSA_ZSH_PLUGINS/p10k.zsh

# Mac OSX Config
