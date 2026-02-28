#!/usr/bin/env bash
# gcc-commit.sh – Checkpoint meaningful progress into GCC memory
# Usage: gcc-commit.sh "<one-line-summary>" ["<detailed-contribution>"]
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: gcc-commit.sh \"<summary>\" [\"<detailed contribution>\"]" >&2
  exit 1
fi

GCC_DIR=".GCC"
if [ ! -d "$GCC_DIR" ]; then
  echo "Error: .GCC not initialized. Run 'bash scripts/gcc-init.sh' first." >&2
  exit 1
fi

SUMMARY="$1"
DETAIL="${2:-$SUMMARY}"
NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
CURRENT_BRANCH=$(cat "$GCC_DIR/.current-branch")
COMMIT_MD="$GCC_DIR/branches/$CURRENT_BRANCH/commit.md"

# Read Branch Purpose from first commit entry (or header)
BRANCH_PURPOSE=$(grep -m1 "^\*\*Purpose:\*\*" "$COMMIT_MD" 2>/dev/null | sed 's/\*\*Purpose:\*\* //' || echo "(see branch header)")

# Read previous progress summary from last commit entry
PREV_SUMMARY=$(awk '/^## Commit:/,/^---/' "$COMMIT_MD" 2>/dev/null | \
  grep "Previous Progress Summary" -A3 | tail -3 | grep -v "Previous Progress" | \
  head -1 || echo "(first commit)")

# Append new commit entry
cat >> "$COMMIT_MD" << EOF

## Commit: ${NOW} | ${SUMMARY}

**Branch Purpose:** ${BRANCH_PURPOSE}

**Previous Progress Summary:**
${PREV_SUMMARY}

**This Commit's Contribution:**
${DETAIL}

---
EOF

# Git commit
git add "$GCC_DIR"
git commit -m "GCC: ${SUMMARY}"

echo "✓ Committed: '${SUMMARY}' on branch '${CURRENT_BRANCH}'"
echo "  Run 'bash scripts/gcc-context.sh --branch ${CURRENT_BRANCH}' to review."
