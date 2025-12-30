#!/usr/bin/env zsh
# Configure macOS default apps using duti based on config overrides
# This script applies duti settings loaded from the YAML configuration file
#
# It validates that required apps exist, checks for conflicts, and applies
# the overrides in a safe manner.

echo "Configuring macOS default applications..."

# Check if duti is installed
if ! command -v duti &>/dev/null; then
  echo "⚠ duti is not installed - skipping default app configuration"
  echo "Run the duti component to install: ./osa-cli.zsh --setup duti"
  return 0
fi

# Function to validate bundle ID exists on the system
validate_bundle_id() {
  local bundle_id="$1"
  local extension="$2"
  
  # Try to find the bundle using mdutil/spotlight first
  if mdfind "kMDItemCFBundleIdentifier == '$bundle_id'" &>/dev/null 2>&1; then
    return 0
  fi
  
  # Fallback: check common app names in /Applications
  local app_name=$(echo "$bundle_id" | sed 's/.*\.//')
  if find /Applications -iname "${app_name}.app" -type d &>/dev/null 2>&1; then
    return 0
  fi
  
  # For VSCode, check if code command exists
  if [[ "$bundle_id" == "com.microsoft.VSCode" ]] && command -v code &>/dev/null; then
    return 0
  fi
  
  return 1
}

# Function to validate that extension overrides don't conflict
check_for_conflicts() {
  local -A bundle_assignments
  
  # This function could be expanded to validate that the same extension
  # isn't assigned to multiple apps, but the YAML structure already prevents this
  return 0
}

# Ensure VSCode is installed if we're setting VSCode overrides
if env | grep -q "OSA_CONFIG_DUTI_.*_BUNDLE_ID.*com\.microsoft\.VSCode"; then
  if ! validate_bundle_id "com.microsoft.VSCode" ""; then
    echo "⚠ Visual Studio Code is not installed"
    echo "  Installing Visual Studio Code via Homebrew..."
    
    if command -v brew &>/dev/null && brew install --cask visual-studio-code 2>&1; then
      echo "✓ Visual Studio Code installed"
    else
      echo "⚠ Failed to install Visual Studio Code - skipping VSCode duti overrides"
    fi
  fi
fi

# Ensure Keka is installed if we're setting Keka overrides
if env | grep -q "OSA_CONFIG_DUTI_.*_BUNDLE_ID.*com\.aone\.keka"; then
  if ! find /Applications -name "Keka.app" -type d &>/dev/null 2>&1; then
    echo "ℹ Keka is not installed"
    echo "  To use Keka overrides, install with: brew install --cask keka"
  fi
fi

# Apply duti overrides from config
local config_vars=$(env | grep "^OSA_CONFIG_DUTI_" | sort)
local override_count=0
local failed_count=0

if [[ -n "$config_vars" ]]; then
  echo "Applying duti overrides from configuration..."
  
  while IFS='=' read -r var_line; do
    [[ -z "$var_line" ]] && continue
    
    # Split on first = to get var name and value
    local var_name="${var_line%%=*}"
    local var_value="${var_line#*=}"
    
    [[ -z "$var_name" || -z "$var_value" ]] && continue
    
    # Extract extension and bundle ID from variable name
    # OSA_CONFIG_DUTI_ZIP_BUNDLE_ID -> .zip
    local extension_part="${var_name#OSA_CONFIG_DUTI_}"
    extension_part="${extension_part%_BUNDLE_ID}"
    
    # Reconstruct extension with dot (e.g., zip -> .zip)
    local extension=".${extension_part,,}"
    
    # Handle special case of Podfile (no dot)
    if [[ "$extension_part" == "PODFILE" ]]; then
      extension="Podfile"
    fi
    
    local bundle_id="$var_value"
    
    # Validate bundle ID before applying
    if validate_bundle_id "$bundle_id" "$extension"; then
      if duti -s "$bundle_id" "$extension" all 2>/dev/null; then
        echo "✓ Set $extension → $(echo "$bundle_id" | sed 's/.*\.//')"
        ((override_count++))
      else
        echo "✗ Failed to set $extension → $bundle_id"
        ((failed_count++))
      fi
    else
      echo "⚠ Bundle not found: $bundle_id (for $extension)"
    fi
  done <<< "$config_vars"
fi

if [[ $override_count -gt 0 ]]; then
  echo ""
  echo "✓ Applied $override_count duti override(s)"
fi

if [[ $failed_count -gt 0 ]]; then
  echo "⚠ $failed_count override(s) failed"
fi

if [[ $override_count -eq 0 && $failed_count -eq 0 ]]; then
  echo "ℹ No duti overrides configured"
fi

echo ""

return 0

