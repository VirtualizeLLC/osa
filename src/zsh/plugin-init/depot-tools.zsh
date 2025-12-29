#!/usr/bin/env zsh
# depot_tools plugin initialization
# Add depot_tools to PATH if installed
# https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html

DEPOT_TOOLS_HOME="${DEPOT_TOOLS_HOME:-$OSA_CONFIG/external-libs/depot_tools}"

if [[ -d "$DEPOT_TOOLS_HOME" ]]; then
  export PATH="$DEPOT_TOOLS_HOME:$PATH"
else
  # Inform user depot_tools is not installed
  if [[ -z "$DEPOT_TOOLS_INIT_MESSAGE_SHOWN" ]]; then
    echo "Note: depot_tools not found at: $DEPOT_TOOLS_HOME"
    echo "Install with: ./osa-cli.zsh --enable depot-tools"
    echo "Or manually: git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ~/.depot_tools"
    export DEPOT_TOOLS_INIT_MESSAGE_SHOWN=1
  fi
fi
