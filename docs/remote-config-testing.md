# Remote Configuration Testing Guide

This document explains how to test and validate the remote configuration feature in OSA.

## Feature Overview

OSA can download and execute configuration files from remote URLs, enabling teams to easily share standardized development environment setups.

## How It Works

1. User runs `./osa-cli.zsh --config-url <URL>`
2. OSA downloads the JSON config to `/tmp/osa-remote-config-$$.json`
3. Validates the JSON structure using `jq`
4. Shows a preview of what will be installed (components & runtimes)
5. Asks for user confirmation (unless `--dry-run` is used)
6. Delegates to `load_json_config()` for processing
7. Cleans up the temporary file

## Security Features

- **HTTPS Only**: HTTP URLs are rejected with an error message (prevents MITM attacks)
- **User Confirmation**: Shows preview and requires confirmation before installation
- **JSON Validation**: Verifies the file is valid JSON before processing
- **Input Validation**: Version strings are validated with regex (only alphanumeric, dots, dashes, underscores)
- **No eval()**: Uses `typeset -g` instead of `eval` to prevent command injection
- **Temp File Cleanup**: Automatically removes downloaded files
- **Dry-Run Support**: Test configurations without making changes

## Supported URL Sources

### GitHub Raw Files
```bash
./osa-cli.zsh --config-url https://raw.githubusercontent.com/org/repo/main/config.json
```

### GitHub Gists
```bash
./osa-cli.zsh --config-url https://gist.githubusercontent.com/user/abc123/raw/config.json
```

### Any HTTPS URL
```bash
./osa-cli.zsh --config-url https://yourcompany.com/osa/standard-config.json
```

## Testing Checklist

### 1. Local File Test (Baseline)
```bash
# Verify local config still works
./osa-cli.zsh --config-file configs/minimal.json --dry-run
```

Expected: Should show components from minimal.json without errors.

### 2. Remote Config Test (GitHub Raw)
```bash
# Test with a real GitHub raw URL (example)
./osa-cli.zsh --config-url https://raw.githubusercontent.com/FrederickEngelhardt/one-setup-anywhere/main/configs/minimal.json --dry-run
```

Expected:
- Downloads config to temp file
- Shows configuration description
- Displays preview of components
- Asks for confirmation (auto-skipped in dry-run)
- Processes config successfully
- Cleans up temp file

### 3. Invalid URL Test
```bash
# Test with invalid URL
./osa-cli.zsh --config-url https://example.com/nonexistent.json
```

Expected: Should fail gracefully with error message.

### 4. Invalid JSON Test
```bash
# Test with non-JSON content
./osa-cli.zsh --config-url https://example.com/index.html
```

Expected: Should detect invalid JSON and exit with error.

### 5. User Confirmation Test
```bash
# Test confirmation prompt (without --dry-run)
./osa-cli.zsh --config-url https://raw.githubusercontent.com/.../config.json
```

Expected:
- Shows preview
- Prompts "Proceed with this configuration? (y/n)"
- Waits for user input before proceeding

## Manual Testing Steps

### Step 1: Create a Test Gist
1. Go to https://gist.github.com
2. Create a new gist with the content of `configs/minimal.json`
3. Name it `osa-test-config.json`
4. Click "Create public gist"
5. Copy the "Raw" URL

### Step 2: Test with Dry-Run
```bash
./osa-cli.zsh --config-url <YOUR_GIST_RAW_URL> --dry-run
```

### Step 3: Verify Output
Check that:
- [ ] Config downloads successfully
- [ ] JSON is validated
- [ ] Description is displayed
- [ ] Components are listed
- [ ] No actual installation happens (dry-run)
- [ ] Temp file is cleaned up (`ls /tmp/osa-remote-config-* 2>/dev/null`)

### Step 4: Test Without Dry-Run
```bash
./osa-cli.zsh --config-url <YOUR_GIST_RAW_URL>
```

Verify:
- [ ] Confirmation prompt appears
- [ ] Typing 'n' cancels without error
- [ ] Typing 'y' proceeds with installation

## Troubleshooting

### "curl: command not found" and "wget: command not found"
Install curl: `brew install curl` (macOS) or `apt-get install curl` (Linux)

### "jq: command not found"
Install jq: `brew install jq` (macOS) or `apt-get install jq` (Linux)

### Download Fails
- Check internet connection
- Verify URL is accessible in browser
- Ensure URL uses HTTPS (not HTTP)
- Check for firewall/proxy issues

### Invalid JSON Error
- Verify the remote file is valid JSON
- Test with `curl <URL> | jq .` to validate manually
- Check for BOM or encoding issues

## Code References

### Main Function
`load_remote_config()` in `osa-cli.zsh` (lines ~300-360)

### Key Files Modified
- `osa-cli.zsh` - Added `load_remote_config()` function and `--config-url` handler
- `README.md` - Added remote config examples
- `configs/README.md` - Added remote config documentation

### Dependencies
- `curl` (primary) or `wget` (fallback) for HTTP downloads
- `jq` for JSON validation
- `load_json_config()` for config processing

## Team Workflow Example

### 1. Create Team Config Repository
```bash
git clone https://github.com/yourorg/osa-configs
cd osa-configs
vim frontend-team.json
git add frontend-team.json
git commit -m "Add frontend team config"
git push
```

### 2. Share with Team
New team members run:
```bash
git clone https://github.com/FrederickEngelhardt/one-setup-anywhere.git ~/osa
cd ~/osa
./osa-cli.zsh --config-url https://raw.githubusercontent.com/yourorg/osa-configs/main/frontend-team.json
```

### 3. Version Control Benefits
- Update config in one place
- Team members pull latest version via URL
- Use git tags/branches for versioned configs
- Track changes via commit history

## Best Practices

1. **Always test with `--dry-run` first**
2. **Use HTTPS URLs only**
3. **Include clear "description" field in configs**
4. **Version your configs in git**
5. **Use semantic versioning in URLs** (e.g., `/v1.0.0/config.json`)
6. **Document your team's config location**
7. **Review configs before sharing with team**

## Next Steps

- [ ] Test with real GitHub gist URL
- [ ] Test with GitHub raw file URL
- [ ] Create team config repository example
- [ ] Add integration tests for `load_remote_config()`
- [ ] Document security best practices in main README
