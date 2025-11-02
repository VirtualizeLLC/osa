#!/usr/bin/env zsh
# Install CocoaPods
# Works with any Ruby 2.7.5 or higher (e.g. 3.2.2, 3.3.0, 3.4.0, etc)

echo "Installing CocoaPods..."
gem install cocoapods

# Verify installation
if command -v pod &>/dev/null; then
  echo "✓ CocoaPods $(pod --version) installed successfully"
else
  echo "✗ Failed to install CocoaPods"
  exit 1
fi