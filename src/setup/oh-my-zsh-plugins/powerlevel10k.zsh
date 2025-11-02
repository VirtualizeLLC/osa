cloneTarget=$OSA_EXTERNAL_LIBS/powerlevel10k

isFontInstalled(){
    # Check if MesloLGS NF font is already installed
    # On macOS, fonts can be in ~/Library/Fonts or /Library/Fonts
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if fc-list 2>/dev/null | grep -qi "MesloLGS NF" || \
           ls ~/Library/Fonts/*MesloLGS* 2>/dev/null | grep -q . || \
           ls /Library/Fonts/*MesloLGS* 2>/dev/null | grep -q .; then
            return 0
        fi
    fi
    return 1
}

installFonts(){
    if isFontInstalled; then
        echo "✓ MesloLGS NF font already installed, skipping font installation"
        return 0
    fi
    
    echo "Installing MesloLGS NF font for Powerlevel10k..."
    # Install the fonts manually and trigger fontBook
    FONT_NAME="MesloLGS NF Regular.ttf"
    curl -L "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf" --output "$HOME/Downloads/$FONT_NAME"
    
    if [[ -f "$HOME/Downloads/$FONT_NAME" ]]; then
        open -b com.apple.FontBook "$HOME/Downloads/$FONT_NAME"
        echo "✓ Font downloaded. Please install it from Font Book if it didn't open automatically."
    else
        echo "⚠ Font download failed, you may need to install MesloLGS NF manually"
    fi
}

if [[ ! -d "$cloneTarget" ]]; then
    if [[ "$OSA_VERBOSE" == "true" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $cloneTarget
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $cloneTarget > /dev/null 2>&1
    fi
    installFonts
else
    echo "✓ Powerlevel10k already installed"
fi

# To link with oh-my-zsh this will need to be symlinked into the plugins section