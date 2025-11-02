#!/usr/bin/env zsh
# Pre-commit hook to detect accidental secret commits
# Usage: Add to .git/hooks/pre-commit or run manually before commits

# Patterns that indicate secrets (customize as needed)
SECRET_PATTERNS=(
  'password\s*=\s*["\047][^\s]+["\047]'
  'token\s*=\s*["\047][^\s]+["\047]'
  'api[_-]?key\s*=\s*["\047][^\s]+["\047]'
  'secret\s*=\s*["\047][^\s]+["\047]'
  'AWS_SECRET_ACCESS_KEY\s*=\s*["\047][^\s]+["\047]'
  'GITHUB_TOKEN\s*=\s*["\047][^\s]+["\047]'
  'NPM_TOKEN\s*=\s*["\047][^\s]+["\047]'
  'HOMEBREW_GITHUB_API_TOKEN\s*=\s*["\047][^\s]+["\047]'
  'ghp_[a-zA-Z0-9]{36}'
  'sk_live_[a-zA-Z0-9]{24}'
  'AKIA[0-9A-Z]{16}'
)

# Get staged files if in git context, otherwise check all files
if git rev-parse --git-dir > /dev/null 2>&1; then
  STAGED_FILES=($(git diff --cached --name-only --diff-filter=ACM))
  echo "Scanning staged files for accidental secret commits..."
else
  echo "Not in git repository, scanning all constructor files..."
  STAGED_FILES=(
    "src/zsh/constructors/init.zsh"
    "src/zsh/constructors/final.zsh"
  )
fi

if [[ ${#STAGED_FILES[@]} -eq 0 ]]; then
  echo "No files to scan"
  exit 0
fi

VIOLATIONS=0

for file in "${STAGED_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi
  
  # Skip example files
  if [[ "$file" == *.example ]]; then
    continue
  fi
  
  for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -qE "$pattern" "$file" 2>/dev/null; then
      echo "❌ BLOCKED: Possible secret detected in $file"
      echo "   Pattern matched: $pattern"
      echo ""
      grep -nE "$pattern" "$file" | head -3
      echo ""
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  done
done

if [[ $VIOLATIONS -gt 0 ]]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔒 SECURITY: $VIOLATIONS potential secret(s) detected"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Use OSA's secure credential management instead:"
  echo "  1. Store secret: osa-secrets"
  echo "  2. Use in code:  export TOKEN=\"\$(osa-secret-get service username)\""
  echo ""
  echo "To scan existing files: ./osa-cli.zsh --scan-secrets"
  echo "To migrate secrets:     ./osa-cli.zsh --migrate-secrets"
  echo ""
  exit 1
fi

echo "✓ No secrets detected in scanned files"
exit 0
