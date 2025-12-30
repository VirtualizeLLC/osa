#!/usr/bin/env zsh
# 7zip shell integration for macOS
# Provides convenient aliases and functions for fast archive extraction
# https://www.7-zip.org/

# Check if 7zz is available
if command -v 7zz &>/dev/null; then
  # Alias to replace slow Archive Utility with fast 7zz
  # Usage: unzip7 archive.zip
  alias unzip7='7zz x -mmt=on'
  
  # Advanced function: extract with progress and auto-detect best settings
  # Usage: extract_archive archive.zip [output_dir]
  extract_archive() {
    local archive="$1"
    local output="${2:-.}"
    
    if [[ ! -f "$archive" ]]; then
      echo "Error: Archive not found: $archive"
      return 1
    fi
    
    echo "Extracting (multi-threaded): $archive → $output"
    7zz x "$archive" -o"$output" -mmt=on
    
    local result=$?
    if [[ $result -eq 0 ]]; then
      echo "✓ Extraction complete"
    else
      echo "✗ Extraction failed with exit code $result"
    fi
    return $result
  }
  
  # Export functions for use in subshells
  export -f extract_archive
else
  # Fallback: inform user 7zz is not installed
  if [[ -z "$OSA_7ZIP_SKIP_INIT_MESSAGE" ]]; then
    echo "Note: 7zz (7zip) not found - install with: ./osa-cli.zsh --enable 7zip"
    echo "This provides fast multi-threaded archive extraction instead of slow macOS default"
    export OSA_7ZIP_SKIP_INIT_MESSAGE=1
  fi
fi
