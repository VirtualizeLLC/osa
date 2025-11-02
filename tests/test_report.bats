#!/usr/bin/env bats
# tests/test_report.bats - Test system report generation

load helpers

setup() {
  setup_test_env
  # Source necessary helpers
  source "$OSA_TEST_REPO_ROOT/src/zsh/helpers/detect-platform.zsh"
  source "$OSA_TEST_REPO_ROOT/src/zsh/helpers/system-report.zsh"
  # Ensure platform detection is run
  detect_platform
}

teardown() {
  teardown_test_env
}

# Report Generation
# =================

@test "--report generates text report" {
  # Act
  run ./osa-cli.zsh --report
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"OSA System Report"* ]]
  [[ "$output" == *"Platform"* ]]
  [[ "$output" == *"Shell"* ]]
}

@test "--report includes platform info" {
  # Act
  run ./osa-cli.zsh --report
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Platform:"* ]]
  [[ "$output" == *"OS Version:"* ]]
  [[ "$output" == *"Architecture:"* ]]
  [[ "$output" == *"Running in VM:"* ]]
}

@test "--report includes shell info" {
  # Act
  run ./osa-cli.zsh --report
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"zsh"* ]]
  [[ "$output" == *"Version:"* ]]
}

@test "--report includes OSA info" {
  # Act
  run ./osa-cli.zsh --report
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"OSA Version:"* ]]
  [[ "$output" == *"Repository:"* ]]
}

@test "--report-json generates JSON output" {
  # Skip if jq is not available
  if ! command -v jq &>/dev/null; then
    skip "jq not installed"
  fi
  
  # Act
  run ./osa-cli.zsh --report-json
  
  # Assert
  [[ "$status" -eq 0 ]]
  # Verify it's valid JSON
  echo "$output" | jq . > /dev/null
}

@test "--report-json includes environment section" {
  # Skip if jq is not available
  if ! command -v jq &>/dev/null; then
    skip "jq not installed"
  fi
  
  # Act
  run ./osa-cli.zsh --report-json
  
  # Assert
  [[ "$status" -eq 0 ]]
  echo "$output" | jq -e '.environment.platform' > /dev/null
  echo "$output" | jq -e '.environment.os_version' > /dev/null
  echo "$output" | jq -e '.environment.architecture' > /dev/null
  echo "$output" | jq -e '.environment.in_vm' > /dev/null
}

@test "--report-json includes shell section" {
  # Skip if jq is not available
  if ! command -v jq &>/dev/null; then
    skip "jq not installed"
  fi
  
  # Act
  run ./osa-cli.zsh --report-json
  
  # Assert
  [[ "$status" -eq 0 ]]
  echo "$output" | jq -e '.shell.type' > /dev/null
  echo "$output" | jq -e '.shell.version' > /dev/null
  echo "$output" | jq -e '.shell.path' > /dev/null
}

@test "--report-json includes osa section" {
  # Skip if jq is not available
  if ! command -v jq &>/dev/null; then
    skip "jq not installed"
  fi
  
  # Act
  run ./osa-cli.zsh --report-json
  
  # Assert
  [[ "$status" -eq 0 ]]
  echo "$output" | jq -e '.osa.version' > /dev/null
  echo "$output" | jq -e '.osa.repository' > /dev/null
  echo "$output" | jq -e '.osa.config_exists' > /dev/null
  echo "$output" | jq -e '.osa.symlinks_exist' > /dev/null
}

@test "--report-url generates GitHub issue URL" {
  # Act
  run ./osa-cli.zsh --report-url
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"https://github.com"* ]]
  [[ "$output" == *"/issues/new"* ]]
}

@test "--report-url includes system info in body" {
  # Act
  run ./osa-cli.zsh --report-url
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Environment"* ]]
  [[ "$output" == *"Platform"* ]]
  [[ "$output" == *"Running in VM"* ]]
  [[ "$output" == *"Shell"* ]]
  [[ "$output" == *"OSA"* ]]
}

@test "--report-url includes instructions" {
  # Act
  run ./osa-cli.zsh --report-url
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"open this in your browser"* ]]
}

# VM Detection
# ============

@test "detect_vm_environment sets OSA_IN_VM variable" {
  # Act
  source "$OSA_TEST_REPO_ROOT/src/zsh/helpers/system-report.zsh"
  detect_vm_environment
  
  # Assert
  [[ -n "$OSA_IN_VM" ]]
}

@test "detect_vm_environment sets OSA_VM_TYPE variable" {
  # Act
  source "$OSA_TEST_REPO_ROOT/src/zsh/helpers/system-report.zsh"
  detect_vm_environment
  
  # Assert
  [[ -n "$OSA_VM_TYPE" ]]
}

@test "VM detection reports correctly in text report" {
  # Act
  run ./osa-cli.zsh --report
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Running in VM:"* ]]
}

@test "VM detection reports correctly in JSON report" {
  # Skip if jq is not available
  if ! command -v jq &>/dev/null; then
    skip "jq not installed"
  fi
  
  # Act
  run ./osa-cli.zsh --report-json
  
  # Assert
  [[ "$status" -eq 0 ]]
  local in_vm=$(echo "$output" | jq -r '.environment.in_vm')
  [[ "$in_vm" =~ ^(yes|no)$ ]]
}

# Help Text
# =========

@test "help includes --report option" {
  # Act
  run ./osa-cli.zsh --help
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"--report"* ]]
}

@test "help includes --report-json option" {
  # Act
  run ./osa-cli.zsh --help
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"--report-json"* ]]
}

@test "help includes --report-url option" {
  # Act
  run ./osa-cli.zsh --help
  
  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"--report-url"* ]]
}
