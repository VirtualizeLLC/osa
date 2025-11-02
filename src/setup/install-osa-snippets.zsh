#!/usr/bin/env zsh
# Install/update osa-snippets - community shell functions and helpers
# https://github.com/VirtualizeLLC/osa-scripts

# Check if snippets should be skipped
if [[ "$OSA_SKIP_SNIPPETS" == "true" ]]; then
  echo "⊘ osa-snippets skipped (--disable-osa-snippets)"
  return 0
fi

echo "Installing osa-snippets (community shell helpers)..."

# Allow override via environment variable
SNIPPETS_REPO="${SNIPPETS_REPO:-https://github.com/VirtualizeLLC/osa-scripts}"
SNIPPETS_DIR="${SNIPPETS_DIR:-$OSA_REPO_PATH/src/zsh/snippets}"
SNIPPETS_ARCHIVE_URL="$SNIPPETS_REPO/archive/refs/heads/main.zip"

# Create parent directory if needed
mkdir -p "$(dirname "$SNIPPETS_DIR")"

# Download and extract via curl/unzip
echo "Downloading osa-snippets from $SNIPPETS_REPO..."

# Create temp directory for download
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

# Download archive
if ! curl -sL -o "$temp_dir/osa-scripts.zip" "$SNIPPETS_ARCHIVE_URL"; then
  echo "✗ Failed to download osa-snippets from $SNIPPETS_ARCHIVE_URL"
  return 1
fi

# Extract archive
if ! unzip -q "$temp_dir/osa-scripts.zip" -d "$temp_dir"; then
  echo "✗ Failed to extract osa-scripts archive"
  return 1
fi

# Remove old installation if exists
if [[ -d "$SNIPPETS_DIR" ]]; then
  rm -rf "$SNIPPETS_DIR"
fi

# Move extracted repo to target location (archive creates osa-scripts-main directory)
if [[ -d "$temp_dir/osa-scripts-main" ]]; then
  mv "$temp_dir/osa-scripts-main" "$SNIPPETS_DIR"
elif [[ -d "$temp_dir/main" ]]; then
  mv "$temp_dir/main" "$SNIPPETS_DIR"
else
  echo "✗ Failed to find extracted osa-scripts directory"
  return 1
fi

if [[ ! -d "$SNIPPETS_DIR" ]]; then
  echo "✗ Failed to install osa-snippets"
  return 1
fi

echo "✓ osa-snippets installed to $SNIPPETS_DIR"

# Ensure entry.zsh exists
if [[ ! -f "$SNIPPETS_DIR/entry.zsh" ]]; then
  echo "⚠ Warning: entry.zsh not found in $SNIPPETS_DIR"
  echo "  Make sure osa-scripts repo has an entry.zsh file"
  return 1
fi

echo "✓ osa-snippets installation complete"
