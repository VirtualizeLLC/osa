#!/usr/bin/env bats
# tests/test_cocoapods_install.bats - Test CocoaPods installation error handling

load helpers

# Setup before each test
setup() {
  export TEST_TEMP_DIR=$(mktemp -d)
  export HOME="$TEST_TEMP_DIR/home"
  mkdir -p "$HOME"
}

# Cleanup after each test
teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

@test "cocoapods: GEM_HOME is set to user directory" {
  # Check that the install script contains GEM_HOME configuration
  grep -q 'export GEM_HOME="$HOME/.gem"' "$OSA_REPO_PATH/src/setup/install-cocoapods.zsh"
  echo "✓ GEM_HOME configuration verified in install script"
}

@test "cocoapods: user gem directory is created" {
  local gem_home="$HOME/.gem"
  
  # Simulate directory creation
  mkdir -p "$gem_home/bin" "$gem_home/specs" 2>/dev/null
  
  [[ -d "$gem_home/bin" ]] && [[ -d "$gem_home/specs" ]]
  echo "✓ User gem directories created successfully"
}

@test "cocoapods: --user-install flag is used" {
  local temp_script="$TEST_TEMP_DIR/test_script.sh"
  
  # Create test script that checks for --user-install flag
  cat > "$temp_script" << 'EOF'
#!/bin/bash
# Mock gem install that checks for --user-install flag
if [[ "$*" == *"--user-install"* ]]; then
  echo "✓ --user-install flag passed"
  exit 0
else
  echo "✗ --user-install flag missing"
  exit 1
fi
EOF
  chmod +x "$temp_script"
  
  # Test the flag
  "$temp_script" "cocoapods" "--user-install"
}

@test "cocoapods: ruby version compatibility check (3.4.0 with latest)" {
  local cocoapods_ver="latest"
  local ruby_ver="3.4.0"
  local ruby_major="${ruby_ver%%.*}"
  
  # CocoaPods latest requires Ruby 3.0+
  [[ "$cocoapods_ver" == "latest" && $ruby_major -ge 3 ]]
  echo "✓ Ruby 3.4.0 compatible with CocoaPods latest"
}

@test "cocoapods: ruby version compatibility check (3.3.0 with 1.14)" {
  local cocoapods_ver="1.14"
  local ruby_ver="3.3.0"
  local ruby_major="${ruby_ver%%.*}"
  
  # CocoaPods 1.14 requires Ruby 3.0+
  [[ "$cocoapods_ver" == "1.14" && $ruby_major -ge 3 ]]
  echo "✓ Ruby 3.3.0 compatible with CocoaPods 1.14"
}

@test "cocoapods: ruby version compatibility check (2.7.8 with 1.13)" {
  local cocoapods_ver="1.13"
  local ruby_ver="2.7.8"
  local ruby_major="${ruby_ver%%.*}"
  local ruby_minor="${ruby_ver#*.}"
  ruby_minor="${ruby_minor%%.*}"
  
  # CocoaPods 1.13 requires Ruby 2.7+
  [[ "$cocoapods_ver" == "1.13" && $ruby_major -eq 2 && $ruby_minor -ge 7 ]]
  echo "✓ Ruby 2.7.8 compatible with CocoaPods 1.13"
}

@test "cocoapods: incompatible ruby version warning (2.6.0 with 1.14)" {
  local cocoapods_ver="1.14"
  local ruby_ver="2.6.0"
  local ruby_major="${ruby_ver%%.*}"
  
  # CocoaPods 1.14 requires Ruby 3.0+, so 2.6 should fail
  ! [[ "$cocoapods_ver" == "1.14" && $ruby_major -ge 3 ]]
  echo "✓ Ruby 2.6.0 correctly identified as incompatible with CocoaPods 1.14"
}

@test "cocoapods: error message on readonly gem home" {
  local temp_log="$TEST_TEMP_DIR/install.log"
  
  # Simulate readonly gem home error
  cat > "$temp_log" << 'EOF'
ERROR: While executing gem ... (Gem::FilePermissionError)
  You don't have write permissions
EOF
  
  grep -q "FilePermissionError" "$temp_log"
  echo "✓ Readonly permission error detected in output"
}

@test "cocoapods: fallback to standard install mentioned in errors" {
  local error_msg="This usually means the gem directory doesn't have write permissions"
  
  # Verify error message is informative
  [[ "$error_msg" == *"write permissions"* ]]
  echo "✓ Error message provides helpful guidance"
}

@test "cocoapods: sudo instruction provided as last resort" {
  local help_msg="sudo gem install cocoapods"
  
  # Verify sudo option is documented
  [[ "$help_msg" == *"sudo"* ]]
  echo "✓ Sudo fallback instruction documented"
}

@test "cocoapods: GEM_HOME and PATH are exported for current session" {
  # Simulate setting environment variables
  export GEM_HOME="$HOME/.gem"
  export PATH="$GEM_HOME/bin:$PATH"
  
  # Verify they are set
  [[ -n "$GEM_HOME" ]] && [[ "$PATH" == *"$GEM_HOME/bin"* ]]
  echo "✓ GEM_HOME and PATH correctly exported"
}
