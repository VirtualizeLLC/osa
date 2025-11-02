#!/usr/bin/env zsh
set -eu
setopt PIPEFAIL

# This script rejects commits that stage any file whose basename begins with "__"
# and fails if any file matching that pattern exists in the git history.
#
# Assumption: "__ files" means files or directories whose name begins with two
# leading underscores (e.g. "__secret", "__MACOSX/"). If you want a different
# rule (for example exempting `__init__.py`), tell me and I'll adjust the
# pattern or whitelist.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$REPO_ROOT" || exit 1

pattern='(^|/)(__[^/]+)(/|$)'

echo "Running double-underscore check (zsh) with include/exclude rules..."

# Include/Exclude semantics:
# - items matching any pattern in 'includes' are considered for blocking
# - items matching any pattern in 'excludes' are skipped (not blocked)
# Default: include matches any path segment that begins with '__'; excludes is empty
includes=( '(^|/)(__[^/]+)(/|$)' )
# Always exclude constructor entrypoints (they are safe/required to exist on machines)
# This prevents the check from flagging `src/zsh/constructors/init.zsh` or
# `src/zsh/constructors/final.zsh` even if a parent path contains a __ segment.
excludes=( '(^|/)(init|final)\.zsh$' )

# Helper: return 0 if subject matches any provided regex patterns
matches_any() {
  local subject="$1"
  shift
  local p
  for p in "$@"; do
    [[ -z "$p" ]] && continue
    if [[ "$subject" =~ $p ]]; then
      return 0
    fi
  done
  return 1
}

# Check staged files (Added, Copied, Modified)
staged=$(git diff --cached --name-only --diff-filter=ACM || true)
typeset -a bad_staged
if [[ -n "$staged" ]]; then
  while IFS=$'\n' read -r f; do
    [[ -z "$f" ]] && continue
    # evaluate the full path for includes/excludes
    if matches_any "$f" "${includes[@]}" && ! matches_any "$f" "${excludes[@]}"; then
      bad_staged+=("$f")
    fi
  done <<< "$staged"
fi

# Check git history for any paths matching includes and not excluded
bad_history_lines=$(git rev-list --all --name-only 2>/dev/null | sort -u || true)
typeset -a bad_history_list
if [[ -n "$bad_history_lines" ]]; then
  while IFS=$'\n' read -r h; do
    [[ -z "$h" ]] && continue
    if matches_any "$h" "${includes[@]}" && ! matches_any "$h" "${excludes[@]}"; then
      bad_history_list+=("$h")
    fi
  done <<< "$bad_history_lines"
fi

bad_history="$(printf "%s\n" "${bad_history_list[@]}" | sort -u || true)"

if (( ${#bad_staged} )) || [[ -n "$bad_history" ]]; then
  echo
  echo "ERROR: Files or directories with names beginning with '__' are not allowed."

  if (( ${#bad_staged} )); then
    echo
    echo "Disallowed staged files (please remove from index or rename):"
    for f in "${bad_staged[@]}"; do
      echo "  $f"
    done
  fi

  if [[ -n "$bad_history" ]]; then
    echo
    echo "Found matching files in git history (examples):"
    echo "$bad_history" | sed -n '1,20p'
    echo
    echo "Note: these files exist in previous commits. To remove them from history"
    echo "you'll need to rewrite history (e.g. with 'git filter-repo' or 'git filter-branch')."
    echo "If you want, I can add a helper that suggests filter-repo commands or"
    echo "attempts to remove them (this rewrites history and will require force-push)."
  fi

  exit 1
fi

echo "No disallowed '__' files found."
exit 0
