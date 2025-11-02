#!/usr/bin/env zsh
# Complete cleanup of all OSA symlinks
# Use this if symlinks become corrupted or you need a fresh start

set -e

OSA_CONFIG="${OSA_CONFIG:-$HOME/.osa}"

echo "⚠ WARNING: This will remove all OSA symlinks"
echo "Location: $OSA_CONFIG"
echo ""
echo "This is safe - it only removes symlinks, not the actual files."
echo ""
echo -n "Continue? (y/N) "
read response

if [[ "$response" != "y" && "$response" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Removing symlinks..."

# Remove ~/.osa symlink
if [[ -L "$OSA_CONFIG" ]]; then
    echo "Removing: $OSA_CONFIG"
    rm "$OSA_CONFIG"
elif [[ -e "$OSA_CONFIG" ]]; then
    echo "ERROR: $OSA_CONFIG exists but is not a symlink!"
    echo "Please manually backup and remove it:"
    echo "  mv $OSA_CONFIG ${OSA_CONFIG}.backup"
    exit 1
fi

# Remove ~/.zshrc symlink
if [[ -L "$HOME/.zshrc" ]]; then
    echo "Removing: $HOME/.zshrc"
    rm "$HOME/.zshrc"
fi

echo ""
echo "✓ All symlinks removed"
echo ""
echo "To recreate the symlinks, run:"
echo "  cd /path/to/osa-repo"
echo "  ./osa-cli.zsh --interactive"
