#!/usr/bin/env zsh
# Validate OSA symlinks for corruption and circular references
# Automatically repairs common issues (circular symlinks, broken targets)

set -e

echo "OSA Symlink Validation Utility"
echo "=============================="
echo ""

# Check .osa symlink
if test -L "$HOME/.osa"; then
    target=$(readlink "$HOME/.osa")
    if [[ "$target" == "$HOME/.osa" ]]; then
        echo "✗ Found circular symlink: $HOME/.osa -> $HOME/.osa"
        echo "  Removing..."
        rm "$HOME/.osa"
        echo "  ✓ Removed"
    else
        echo "✓ $HOME/.osa symlink exists and looks correct (-> $target)"
    fi
elif test -e "$HOME/.osa"; then
    echo "✓ $HOME/.osa exists but is not a symlink"
else
    echo "✓ $HOME/.osa does not exist (will be created during setup)"
fi

echo ""

# Check .zshrc symlink
if test -L "$HOME/.zshrc"; then
    target=$(readlink "$HOME/.zshrc")
    echo "✓ $HOME/.zshrc is a symlink -> $target"
    
    # Check if target exists
    if ! test -f "$target"; then
        echo "  ✗ Warning: Target file does not exist!"
        echo "  Removing broken symlink..."
        rm "$HOME/.zshrc"
        
        # Restore backup if available
        if test -f "$HOME/.zshrc_pre_osa"; then
            echo "  Restoring from backup..."
            mv "$HOME/.zshrc_pre_osa" "$HOME/.zshrc"
            echo "  ✓ Restored"
        fi
    fi
elif test -f "$HOME/.zshrc"; then
    echo "✓ $HOME/.zshrc exists (regular file)"
else
    echo "✓ $HOME/.zshrc does not exist (will be created during setup)"
fi

echo ""

# Validate external-libs directory
if test -d "$HOME/.osa/external-libs"; then
    echo "Checking $HOME/.osa/external-libs directory..."
    
    # Check oh-my-zsh
    if test -L "$HOME/.osa/external-libs/oh-my-zsh"; then
        target=$(readlink "$HOME/.osa/external-libs/oh-my-zsh")
        if [[ "$target" == *"/.osa/external-libs/oh-my-zsh"* ]]; then
            echo "  ✗ Found circular symlink: oh-my-zsh"
            echo "    Removing..."
            rm "$HOME/.osa/external-libs/oh-my-zsh"
            echo "    ✓ Removed"
        fi
    fi
    
    # Check other external-libs
    for lib in zsh-syntax-highlighting powerlevel10k evalcache; do
        if test -L "$HOME/.osa/external-libs/$lib"; then
            target=$(readlink "$HOME/.osa/external-libs/$lib")
            if [[ "$target" == *"/.osa/external-libs/$lib"* ]]; then
                echo "  ✗ Found circular symlink: $lib"
                echo "    Removing..."
                rm "$HOME/.osa/external-libs/$lib"
                echo "    ✓ Removed"
            fi
        fi
    done
fi

echo ""
echo "✓ Symlink validation complete"
