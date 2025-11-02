# Contributing to OSA (Open Source Automation)

## Ways to Contribute

### Core OSA Development
- Improve setup scripts and CLI functionality
- Report bugs and suggest features
- Improve documentation
- Review pull requests

### Community Scripts & Helpers
For productivity helpers, utility functions, and shell shortcuts, contribute to **[osa-scripts](https://github.com/VirtualizeLLC/osa-scripts)**:
- Share useful shell functions you've created
- Build helpers for common development tasks
- Improve existing community scripts

Thank you for your interest in contributing to OSA! This guide explains our code standards, development practices, and how to ensure your changes pass our test suite.

## Code Standards

### Shell Environment

**All code must be written for `zsh` only.** We do not support bash, sh, or other shell variants. This allows us to use zsh-specific features and maintain consistency across the codebase.

- **No bash-only syntax** - Don't use `[[` parameter expansion with arithmetic (use `((...))` in zsh)
- **No POSIX-only features** - Use zsh arrays, associative arrays, and other zsh features freely
- **Always use `/usr/bin/env zsh` shebang** - Never `#!/bin/bash` or `#!/bin/sh`

### File Extensions

All shell scripts **must use the `.zsh` extension**:

- ✅ `setup.zsh`, `install.zsh`, `helpers.zsh`
- ✅ `run-tests.zsh`, `cleanup.zsh`
- ❌ `setup.sh`, `install.sh` (don't do this)

This makes it immediately clear what language/environment the file uses.

### Script Template

Use this template for new shell scripts:

```zsh
#!/usr/bin/env zsh
# script-name.zsh - Brief description of what this script does
# 
# Usage:
#   ./script-name.zsh [options]
#
# Options:
#   -h, --help    Show help message
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"

# Color codes
COLOR_RED=$'\033[0;31m'
COLOR_GREEN=$'\033[0;32m'
COLOR_RESET=$'\033[0m'

# Main function
main() {
  echo "Script starting..."
  # Your code here
}

# Run main if script is executed directly
[[ "${(%):-%x}" == "${0}" ]] && main "$@"
```

### Naming Conventions

- **Functions**: Use lowercase with hyphens: `setup-symlinks`, `validate-installation`
- **Variables**: Use UPPERCASE for constants: `OSA_REPO_PATH`, `COLOR_RESET`
- **Variables**: Use lowercase with underscores for locals: `backup_suffix`, `temp_dir`
- **Filenames**: Use lowercase with hyphens: `install-mise.zsh`, `cleanup-symlinks.zsh`

### Code Style

- **Indentation**: Use 2 spaces (not tabs)
- **Line length**: Keep lines under 100 characters when possible
- **Comments**: Use comments to explain *why*, not *what* the code does
- **Error handling**: Always use `set -e` or check return codes
- **Safety checks**: Validate paths, permissions, and user input before destructive operations

### Example: Safe File Operations

```zsh
# ✅ Good: Explicit safety checks
remove_osa_files() {
  local home_dir="$1"
  
  # Safety check: never delete if HOME is root
  if [[ "$home_dir" == "/" ]]; then
    echo "Error: HOME is /" >&2
    return 1
  fi
  
  # Safety check: verify path exists before deleting
  if [[ -L "$home_dir/.osa" ]]; then
    rm -f "$home_dir/.osa"
    echo "✓ Removed OSA symlink"
  fi
}

# ❌ Bad: No validation
remove_osa_files() {
  rm -rf "$HOME/.osa"  # Dangerous!
}
```

### Comments and Documentation

- **Function headers**: Document what the function does, parameters, and return values
- **Complex logic**: Explain non-obvious decisions
- **TODO markers**: Use `# TODO: description` for future work

```zsh
# Calculate backup filename with timestamp
# This ensures unique names if cleanup runs multiple times
get_backup_filename() {
  local original="$1"
  # Use seconds since epoch for uniqueness
  echo "${original}.backup.$(date +%s)"
}
```

## Testing

### Writing Tests

All code changes should include tests. We use [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for shell script testing.

#### Test File Structure

Test files use the `.bats` extension and should follow this structure:

```bash
#!/usr/bin/env bats
# tests/test_feature.bats - Description of what's tested

load helpers  # Load shared helpers and mocks

setup() {
  setup_test_env  # Initialize test environment
}

teardown() {
  teardown_test_env  # Clean up test environment
}

# Group related tests with comments
# Feature Group
# ============

@test "descriptive test name" {
  # Arrange: Set up test data
  local input="test value"
  
  # Act: Call the function
  local result=$(some_function "$input")
  
  # Assert: Verify the result
  [[ "$result" == "expected" ]]
}
```

#### Running Tests

```bash
# Run all tests
./tests/run-tests.zsh

# Run specific test file
bats tests/test_cli_args.bats

# Run with verbose output
bats --verbose tests/

# Watch mode (re-run on changes)
make test-watch
```

#### Mocking in Tests

We provide mocks to prevent destructive operations. Use them to test dangerous functions safely:

```bash
@test "should remove OSA files safely" {
  # Arrange: Mock rm to log calls instead of deleting
  alias rm=mock_rm
  
  # Act: Call function that removes files
  clean_all "true"
  
  # Assert: Verify correct files were targeted
  assert_mock_called "MOCK_RM.*~/.osa"
  assert_mock_not_called "MOCK_RM.*home"
}
```

See `tests/helpers.zsh` for available mocks and assertions.

### Test Coverage Requirements

- **Critical functions**: Must have tests (e.g., `clean_all`, `run_component`)
- **Safety checks**: Must be tested (e.g., HOME validation, symlink verification)
- **Argument parsing**: Must test flag combinations and error cases
- **Integration**: Test how components work together

## Pull Request Checklist

Before submitting a pull request, ensure:

- ✅ All code uses `.zsh` extension and zsh syntax
- ✅ Scripts include shebang: `#!/usr/bin/env zsh`
- ✅ All changes have corresponding tests
- ✅ Tests pass: `./tests/run-tests.zsh`
- ✅ Scripts are syntactically valid: `bash -n script.zsh`
- ✅ Documentation is updated (README, docs/, comments)
- ✅ No secrets or credentials in code (use constructors)
- ✅ Safety checks are in place for destructive operations

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes following code standards**
   - Use `.zsh` extension
   - Include comments for complex logic
   - Add safety checks for destructive operations

3. **Write/update tests**
   ```bash
   # Create test file: tests/test_my_feature.bats
   # Run tests to verify
   ./tests/run-tests.zsh
   ```

4. **Run the test suite**
   ```bash
   make test          # Run all tests
   make lint          # Check syntax
   ```

5. **Commit with clear messages**
   ```bash
   git commit -m "feat: add --unsafe flag to skip prompts"
   ```

6. **Push and create pull request**
   ```bash
   git push origin feature/my-feature
   ```

7. **GitHub Actions will run tests automatically**
   - Tests must pass before merging
   - Workflow runs: `.github/workflows/test.yml`

## Architecture Guidelines

### Component-Based Design

The CLI uses a component registration system. When adding new setup functionality:

1. **Create a setup script** in `src/setup/new-feature.zsh`
2. **Register the component** in `osa-cli.zsh`:
   ```zsh
   register_component "feature-name" "Human-readable description" "macos,linux" "src/setup/new-feature.zsh"
   ```
3. **Use the sourcing pattern** - scripts are sourced, not executed
4. **Respect `OSA_VERBOSE`** flag for output control
5. **Support `OSA_DRY_RUN`** to show what would happen

### Error Handling

- Use `set -e` to exit on errors
- Provide clear error messages
- Return appropriate exit codes (0=success, 1=failure)
- Don't trap errors silently

### Safety Model

OSA prioritizes safety through:
- **Confirmation prompts** for destructive operations (can be skipped with `--unsafe`)
- **Symlink-based architecture** - real config is read-only
- **Backup files** with timestamps before deletion
- **Path validation** - ensure we never escape the OSA scope
- **Dry-run support** - see what would happen before committing

## Questions or Need Help?

- Check existing issues: [GitHub Issues](https://github.com/FrederickEngelhardt/one-setup-anywhere/issues)
- Review similar code: Look at existing setup scripts in `src/setup/`
- Read the architecture docs: See `docs/` for system design

## Code Review Process

When your PR is reviewed:

1. **Syntax check**: Does code follow zsh standards and our style guide?
2. **Functionality**: Does code do what it claims to do?
3. **Safety**: Are there sufficient safety checks? Could this break user systems?
4. **Tests**: Are all changes tested? Do tests verify the code works?
5. **Documentation**: Is documentation updated? Are comments clear?

## Questions About These Guidelines?

If anything is unclear, please ask! We'd rather clarify the standards than reject good contributions.
