#!/usr/bin/env zsh
# Install 7zip (7zz) - Fast multi-threaded archive extraction tool for macOS
# https://www.7-zip.org/
# 
# On macOS, the default Archive Utility is single-threaded and slow for large archives.
# 7zip provides true parallel decompression and is much faster for:
# - Large ZIP files
# - Archives with many small files (e.g., Chromium source trees)
# - Bulk extraction operations

echo "Installing 7zip (7zz) - fast multi-threaded archive extraction..."

# Check if Homebrew is available
if ! command -v brew &>/dev/null; then
  echo "✗ Homebrew is required but not installed"
  echo "Install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  return 1
fi

# Install sevenzip via Homebrew
if ! brew install sevenzip 2>&1; then
  echo "✗ Failed to install sevenzip via Homebrew"
  return 1
fi

echo "✓ sevenzip (7zz) installed successfully"
echo ""

# Optionally install Keka (GUI app that uses 7zip backend for Finder integration)
if [[ -z "$OSA_SKIP_KEKA" ]]; then
  echo "Optionally installing Keka (GUI 7zip app for Finder integration)..."
  echo "This allows you to set 7zip as the default handler for .zip files in Finder"
  echo ""
  
  if command -v brew &>/dev/null && brew tap --list | grep -q "homebrew/cask"; then
    if brew install --cask keka 2>&1; then
      echo "✓ Keka installed successfully"
      echo ""
      echo "To set Keka as default ZIP handler:"
      echo "  1. Right-click any .zip file in Finder"
      echo "  2. Get Info (Cmd+I)"
      echo "  3. Open With → Keka"
      echo "  4. Click 'Change All...'"
      echo ""
    else
      echo "⚠ Keka installation failed (optional - 7zz CLI still works)"
    fi
  fi
fi

echo ""
echo "✓ 7zip setup complete!"
echo ""
echo "Usage:"
echo "  Extract archive (multi-threaded):"
echo "    7zz x archive.zip"
echo ""
echo "  Extract with explicit thread count:"
echo "    7zz x archive.zip -mmt=on"
echo ""
echo "  Shell function (added to .zshrc):"
echo "    unzip7 archive.zip          # Uses 7zz instead of slow Archive Utility"
echo ""
echo "Pro tips for Chromium-scale archives:"
echo "  • Extract to APFS SSD for best performance"
echo "  • Disable Spotlight on extraction folder: mdutil -i off ./path"
echo "  • Use 7zz for parallel decompression: 7zz x huge.zip -mmt=on"
echo ""
