# Release Management

This document explains how OSA handles versioning, releases, and changelog management.

## Semantic Versioning

OSA follows [Semantic Versioning](https://semver.org/):

- **Major (X.0.0)**: Breaking changes, incompatible API changes
- **Minor (x.Y.0)**: New features, backwards-compatible additions
- **Patch (x.y.Z)**: Bug fixes, backwards-compatible fixes

## Automatic Releases on PR Merge

Releases are **automatically triggered** when a PR is merged with specific labels:

### Labels for Automatic Release

Add one of these labels to your PR **before merging**:

- `release:major` - Triggers major version bump (e.g., 1.2.3 → 2.0.0)
- `release:minor` - Triggers minor version bump (e.g., 1.2.3 → 1.3.0)

**No label = No automatic release**. You can manually trigger a release later.

### What Happens Automatically

When a PR with `release:major` or `release:minor` is merged:

1. ✅ Version is bumped in `package.json`
2. ✅ Comprehensive changelog is generated from commits
3. ✅ `CHANGELOG.md` is updated with categorized changes
4. ✅ Git tag is created (e.g., `v1.3.0`)
5. ✅ GitHub Release is published with full release notes
6. ✅ Changes are committed back to `main`

## Manual Releases

You can also trigger releases manually via GitHub Actions:

1. Go to **Actions** → **Release** workflow
2. Click **Run workflow**
3. Select:
   - **version_type**: `major`, `minor`, or `patch`
   - **generate_changelog**: `true` for comprehensive notes
4. Click **Run workflow**

This is useful for:
- Patch releases (bug fixes only)
- Emergency releases
- Releases without an associated PR

## Changelog Format

### Comprehensive Changelogs (Major/Minor Releases)

Major and minor releases get detailed, categorized changelogs:

```markdown
## Release 1.3.0

### 📦 Changes since v1.2.0

#### ✨ Features & Enhancements
- Added secure credential management (abc123)
- Introduced secret scanning CLI commands (def456)

#### 🐛 Bug Fixes
- Fixed symlink cleanup script (ghi789)

#### 🔒 Security
- Pre-commit hook blocks secret commits (jkl012)

#### 📚 Documentation
- Updated SETUP-GUIDE.md (mno345)

#### 🔧 Chores & Maintenance
- Standardized file extensions to .zsh (pqr678)

#### 👥 Contributors
- @FrederickEngelhardt
- @contributor2

**Full Changelog**: https://github.com/.../compare/v1.2.0...v1.3.0
```

### Simple Changelogs (Patch Releases)

Patch releases get a simpler format:

```markdown
## Release 1.2.1

### 📦 Changes since v1.2.0

#### Changes:
- Fixed bug in secret scanner (abc123)
- Updated documentation typo (def456)
```

## Commit Message Conventions

To ensure changelogs are accurate, use conventional commit prefixes:

- `feat:` or `feature:` - New features
- `fix:` or `bug:` - Bug fixes
- `security:` - Security improvements
- `docs:` or `doc:` - Documentation changes
- `chore:` or `refactor:` - Maintenance tasks

**Examples:**
```bash
git commit -m "feat: add support for GNOME Keyring"
git commit -m "fix: secret scanner false positive for URLs"
git commit -m "security: block AWS credentials in pre-commit hook"
git commit -m "docs: update README with secret management guide"
```

## CHANGELOG.md

The `CHANGELOG.md` file in the repo root is the **single source of truth** for all releases.

### Structure

```markdown
# Changelog

All notable changes to OSA will be documented in this file.

---

## Unreleased

(Changes not yet released go here)

---

## [1.3.0] - 2025-11-02
(Full release notes)

---

## [1.2.0] - 2025-10-15
(Full release notes)
```

### Automatic Updates

The GitHub Actions workflow automatically:
1. Generates changelog entry from git commits
2. Prepends it to `CHANGELOG.md`
3. Commits the updated file
4. Tags and releases

You should **manually update the "Unreleased" section** as you work on features.

## Workflow Examples

### Example 1: New Feature (Minor Release)

```bash
# 1. Create feature branch
git checkout -b feat/secret-management

# 2. Make changes with conventional commits
git commit -m "feat: add osa-secret-set helper"
git commit -m "feat: add secret scanning CLI command"
git commit -m "docs: document secret management"

# 3. Create PR
gh pr create --title "Add secure credential management"

# 4. Add release label
gh pr edit --add-label "release:minor"

# 5. Merge PR
# ✅ Auto-release triggered: v1.2.0 → v1.3.0
```

### Example 2: Bug Fix (No Auto-Release)

```bash
# 1. Create fix branch
git checkout -b fix/typo

# 2. Make changes
git commit -m "fix: correct typo in help text"

# 3. Create and merge PR (no release label)
gh pr create --title "Fix typo in help"

# 4. Merge PR
# ❌ No auto-release (can release manually later)
```

### Example 3: Breaking Change (Major Release)

```bash
# 1. Create breaking change branch
git checkout -b breaking/new-api

# 2. Make changes
git commit -m "feat!: redesign constructor API"
git commit -m "docs: update migration guide"

# 3. Create PR and add major label
gh pr create --title "BREAKING: New constructor API"
gh pr edit --add-label "release:major"

# 4. Merge PR
# ✅ Auto-release triggered: v1.3.0 → v2.0.0
```

## Release Checklist

Before merging a PR with a release label:

- [ ] All tests pass (`./tests/run-tests.zsh`)
- [ ] No hardcoded secrets (`./osa-cli.zsh --scan-secrets`)
- [ ] Documentation is updated
- [ ] Commit messages follow conventions
- [ ] Appropriate release label is added (`release:major` or `release:minor`)
- [ ] PR description explains the changes clearly

## Troubleshooting

### Release workflow failed

Check GitHub Actions logs for:
- Git tag conflicts (tag already exists)
- Permission issues (GITHUB_TOKEN)
- Syntax errors in commit messages

### CHANGELOG.md conflicts

If `CHANGELOG.md` has conflicts after a release:
1. Pull latest main: `git pull origin main`
2. Resolve conflicts manually
3. Keep the chronological order (newest releases first)

### Manual rollback

If a release was published incorrectly:
1. Delete the tag: `git tag -d v1.3.0 && git push origin :refs/tags/v1.3.0`
2. Delete the GitHub Release from the web UI
3. Revert the version bump commit
4. Re-trigger the release workflow with correct version

## Questions?

- Read: [Keep a Changelog](https://keepachangelog.com/)
- Read: [Semantic Versioning](https://semver.org/)
- Check: GitHub Actions logs in the **Actions** tab
