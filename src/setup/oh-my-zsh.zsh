#!/usr/bin/env zsh

# oh-my-zsh will destructively nuke .zshrc file
export ZSH=$OSA_EXTERNAL_LIBS/oh-my-zsh;

echo "Installing Oh My Zsh..."

# Create external-libs directory if it doesn't exist
if [[ ! -d $OSA_EXTERNAL_LIBS ]]; then 
    echo "Creating external-libs directory: $OSA_EXTERNAL_LIBS"
    mkdir -p $OSA_EXTERNAL_LIBS
fi

# Check if oh-my-zsh is FULLY installed (not just custom folder)
# Look for the main oh-my-zsh.sh file as proof of full installation
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    echo "✓ Oh My Zsh already installed at $ZSH"
else
    # Remove any partial installation (e.g., just custom folder from previous failed run)
    if [[ -d "$ZSH" ]]; then
        echo "⚠ Removing partial oh-my-zsh installation at $ZSH"
        rm -rf "$ZSH"
    fi
    
    echo "Installing oh-my-zsh to $ZSH"
    cd $OSA_EXTERNAL_LIBS
    
    if [[ "$OSA_VERBOSE" == "true" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1
    fi
    
    if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
        echo "✓ Oh My Zsh installed successfully"
    else
        echo "✗ Oh My Zsh installation failed"
        return 1
    fi
fi