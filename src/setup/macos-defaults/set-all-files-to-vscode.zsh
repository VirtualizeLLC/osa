#!/usr/bin/env zsh
# Configure macOS default applications for code editors
# This script applies duti settings loaded from the YAML configuration file
#
# DEPRECATED: This file is kept for backwards compatibility.
# Use the new duti-based configuration system instead (configure-duti.zsh)

echo "⚠ This script is deprecated - using new duti configuration system"
echo ""

# Source the new configure-duti script
source_path="$(dirname "${(%):-%x}")/../configure-duti.zsh"
if [[ -f "$source_path" ]]; then
  source "$source_path"
else
  echo "✗ configure-duti.zsh not found at $source_path"
  return 1
fi

return 0
