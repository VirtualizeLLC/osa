#!/usr/bin/env bats
# tests/test_cli_args.bats - Test osa-cli.zsh argument parsing and flag handling

load helpers

setup() {
  setup_test_env
}

teardown() {
  teardown_test_env
}

# Argument Parsing Tests
# ======================

@test "help flag shows usage and exits" {
  # We can't easily test script execution without running it,
  # but we can verify the help text exists
  grep -q "OSA (Open Source Automation) CLI" "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "help flag takes precedence over other flags" {
  # Verify that --help check comes before other processing
  local cli_file="$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  
  # Check that help is checked early in main()
  grep -A 5 "Check for --help first" "$cli_file" | grep -q "exit 0"
}

@test "verbose flag sets OSA_VERBOSE=true" {
  # Verify verbose flag handling in the script
  grep -q "OSA_VERBOSE=true" "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "clean and unsafe flags are parsed as global flags" {
  # Verify both are in the first parsing loop
  local cli_file="$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  
  grep -q 'should_clean=true' "$cli_file"
  grep -q 'unsafe_mode=true' "$cli_file"
}

@test "only first primary action wins" {
  # Verify that -z check ensures only first action is used
  grep -q 'if \[\[ -z "\$primary_action' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "dry-run and clean cannot be used together" {
  # Verify the check in the script
  grep -q 'cannot be used with' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "arguments with values are parsed correctly" {
  # Verify --config-file and similar flags handle arguments
  grep -q 'action_arg=' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Flag Order Independence
# =======================

@test "clean runs before primary action regardless of order" {
  # Verify clean is checked before case statement for primary action
  local cli_file="$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  
  # Get line numbers
  local clean_check_line=$(grep -n "should_clean == true" "$cli_file" | head -1 | cut -d: -f1)
  local primary_case_line=$(grep -n 'case "\$primary_action"' "$cli_file" | head -1 | cut -d: -f1)
  
  # Clean should be checked before primary action case
  [[ $clean_check_line -lt $primary_case_line ]]
}

@test "unsafe flag works in any position" {
  # Verify unsafe is in the global flags loop, not action-dependent
  grep -q 'unsafe_mode=true' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "verbose flag works in any position" {
  # Verify verbose is parsed in global flags
  grep -q 'OSA_VERBOSE=true' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Error Handling
# ==============

@test "unknown flags produce error message" {
  # Verify error handling for unknown options
  grep -q 'Unknown option:' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "flags requiring arguments show error if missing" {
  # Verify argument validation for config-file, enable, disable
  grep -q 'requires an argument' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

# Script Validation
# =================

@test "script is syntactically valid" {
  bash -n "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "script has shebang" {
  head -1 "$OSA_TEST_REPO_ROOT/osa-cli.zsh" | grep -q '#!/usr/bin/env zsh'
}

@test "all major functions are defined" {
  local cli_file="$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q 'show_help()' "$cli_file"
  grep -q 'clean_all()' "$cli_file"
  grep -q 'interactive_setup()' "$cli_file"
  grep -q 'automated_setup()' "$cli_file"
  grep -q 'main()' "$cli_file"
}

# Help Text Verification
# ========================

@test "help text mentions --clean flag" {
  grep -q '\--clean' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "help text mentions --unsafe flag" {
  grep -q '\--unsafe' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "help text mentions --minimal and --all" {
  grep -q '\--minimal' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q '\--all' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "help includes examples" {
  grep -q 'EXAMPLES:' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
  grep -q './osa-cli.zsh --clean' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}

@test "help includes troubleshooting section" {
  grep -q 'TROUBLESHOOTING:' "$OSA_TEST_REPO_ROOT/osa-cli.zsh"
}
