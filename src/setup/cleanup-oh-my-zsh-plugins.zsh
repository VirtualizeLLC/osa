#!/usr/bin/env zsh
# Cleanup oh-my-zsh plugin symlinks
# Useful for resetting symlinks if they become corrupted or broken

# Ensure OSA_CONFIG is set
if [[ -z "$OSA_CONFIG" ]]; then
    export OSA_CONFIG="$HOME/.osa"
fi

export OSA_EXTERNAL_LIBS="$OSA_CONFIG/external-libs"

echo "Cleaning up oh-my-zsh plugin symlinks..."
echo ""

# Remove all symlinks from custom themes directory
OMZ_CUSTOM_THEMES="$OSA_EXTERNAL_LIBS/oh-my-zsh/custom/themes"
if [[ -d "$OMZ_CUSTOM_THEMES" ]]; then
    echo "Cleaning themes in: $OMZ_CUSTOM_THEMES"
    
    # Remove all symlinks (but not regular files)
    for link in "$OMZ_CUSTOM_THEMES"/*; do
        if [[ -L "$link" ]]; then
            echo "  Removing: $(basename "$link")"
            rm "$link"
        elif [[ -e "$link" ]]; then
            echo "  ⚠ Skipping regular file: $(basename "$link")"
        fi
    done
fi

# Remove all symlinks from custom plugins directory
OMZ_CUSTOM_PLUGINS="$OSA_EXTERNAL_LIBS/oh-my-zsh/custom/plugins"
if [[ -d "$OMZ_CUSTOM_PLUGINS" ]]; then
    echo "Cleaning plugins in: $OMZ_CUSTOM_PLUGINS"
    
    # Remove all symlinks (but not regular files)
    for link in "$OMZ_CUSTOM_PLUGINS"/*; do
        if [[ -L "$link" ]]; then
            echo "  Removing: $(basename "$link")"
            rm "$link"
        elif [[ -e "$link" ]]; then
            echo "  ⚠ Skipping regular file: $(basename "$link")"
        fi
    done
fi

echo ""
echo "✓ Cleanup complete"
echo ""
echo "To restore the symlinks, run:"
echo "  ./osa-cli.zsh --interactive"
echo "or"
echo "  source src/setup/initialize-repo-symlinks.zsh"
