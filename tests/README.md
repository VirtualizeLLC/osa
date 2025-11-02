# OSA CLI Tests

This directory contains automated tests for the OSA (Open Source Automation) CLI scripts.

## Testing Approach

Tests use a combination of techniques to avoid actual system modifications:

1. **Mocking** - Critical system commands (rm, ln, mv) are mocked to capture calls instead of executing
2. **Temporary Directories** - File operations use isolated temp directories, not real home or system paths
3. **Dry-Run Mode** - Tests verify the CLI's `--dry-run` flag works correctly
4. **Function Isolation** - Individual functions are tested with controlled inputs and mocked dependencies

## Running Tests

### Setup

```bash
# Install test dependencies
brew install bats-core

# Or on Linux:
sudo apt-get install bats
```

### Run All Tests

```bash
cd /Users/fre/dev/osa
bats tests/
```

### Run Specific Test File

```bash
bats tests/test_cli_args.bats
bats tests/test_clean_function.bats
```

### Run with Verbose Output

```bash
bats --verbose tests/
```

### Watch Mode (re-run on changes)

```bash
# Using entr (brew install entr)
ls tests/*.bats | entr bats tests/
```

## Test Files

- `test_cli_args.bats` - Argument parsing, flag handling, action selection
- `test_clean_function.bats` - clean_all() function with mocked filesystem
- `test_component_execution.bats` - Component registration and execution
- `fixtures/` - Test data and helper scripts
- `helpers.zsh` - Shared test utilities and mocks

## Test Structure

Each test file includes:

1. **Setup** - Initialize test environment, create temp directories, mock commands
2. **Teardown** - Clean up temp files, restore original commands
3. **Tests** - Individual test cases with clear naming and assertions

### Example Test

```bash
@test "should parse --clean flag" {
  # Arrange
  local result

  # Act
  result=$( is_flag_set "--clean" "--verbose --clean --minimal" )

  # Assert
  [[ "$result" == "true" ]]
}
```

## Mocking Strategy

### Mocked Commands

To prevent destructive operations, these commands are mocked in tests:

- `rm` - Logs deletion calls instead of deleting
- `ln` - Logs symlink creation instead of creating
- `mv` - Logs move operations instead of moving
- `mkdir` - Logs directory creation
- `readlink` - Returns test data instead of reading actual symlinks

### Example Mock

```bash
# In tests/helpers.zsh
mock_rm() {
  echo "MOCK: rm $@" >> "$TEST_LOG"
  return 0
}

# Use in test
@test "should remove symlinks safely" {
  alias rm=mock_rm
  
  # Run function that calls rm
  clean_all true
  
  # Verify calls
  grep "MOCK: rm /home/user/.osa" "$TEST_LOG"
}
```

## Safety Checks

Tests verify these safety mechanisms:

1. **Home directory validation** - Rejects if $HOME is "/" or unset
2. **Symlink target validation** - Only removes OSA symlinks, not user files
3. **Confirmation skipping** - --unsafe flag bypasses prompts
4. **Dry-run prevention** - --clean rejects --dry-run combination
5. **Argument order independence** - Flags work in any order

## CI/CD Integration

To run tests in CI/CD pipelines:

```zsh
#!/bin/zsh
set -e

# Install bats
brew install bats-core 2>/dev/null || apt-get install -y bats

# Run tests with exit code
bats tests/ --tap

# Exit with test result code
exit $?
```

## Adding New Tests

1. Create new `.bats` file in `tests/` directory
2. Source helpers and setup mocks in the file header
3. Use `@test "description"` for each test case
4. Follow AAA pattern: Arrange, Act, Assert
5. Use assertions from helpers.bash
6. Clean up any temp files in `@test teardown` block

## Known Limitations

- Tests don't actually create/remove symlinks (they're mocked)
- Network operations (curl for mise installer) are stubbed
- Platform detection can be mocked for cross-platform testing
- Some integration tests require manual verification

## Debugging Tests

To debug a failing test:

```bash
# Run single test with debugging
bats tests/test_clean_function.bats --verbose --filter "should remove symlinks"

# Add set -x for shell tracing
bats -x tests/test_cli_args.bats
```

To inspect test environment:

```bash
# Source the test helpers in an interactive shell
source tests/helpers.bash
source /Users/fre/dev/osa/osa-cli.zsh

# Call functions manually
should_clean=true
unsafe_mode=true
clean_all "$unsafe_mode"
```

## Resources

- [BATS Documentation](https://github.com/bats-core/bats-core)
- [BATS Tutorial](https://github.com/bats-core/bats-core/wiki/Background:-What-is-BATS%3F)
- [Shell Script Testing Best Practices](https://github.com/bats-core/bats-core/wiki/Background:-Bash-Testing-Best-Practices)
