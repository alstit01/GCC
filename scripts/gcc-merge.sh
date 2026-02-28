#!/usr/bin/env bash
# gcc-merge.sh – Synthesize branch results back into main trajectory
# Usage: gcc-merge.sh "<branch-name>"
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: gcc-merge.sh \"<branch-name>\"" >&2
  exit 1
fi

GCC_DIR=".GCC"
if [ ! -d "$GCC_DIR" ]; then
  echo "Error: .GCC not initialized." >&2
  exit 1
fi

BRANCH_NAME="$1"
BRANCH_DIR="$GCC_DIR/branches/$BRANCH_NAME"
MAIN_DIR="$GCC_DIR/branches/main"
NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

if [ ! -d "$BRANCH_DIR" ]; then
  echo "Error: Branch '$BRANCH_NAME' not found in .GCC/branches/" >&2
  exit 1
fi

# Get branch purpose for main.md update
BRANCH_PURPOSE=$(grep "^\*\*Purpose:\*\*" "$BRANCH_DIR/commit.md" | head -1 | sed 's/\*\*Purpose:\*\* //')
# Get last commit summary from branch
LAST_COMMIT=$(grep "^## Commit:" "$BRANCH_DIR/commit.md" | tail -1 | sed 's/## Commit: .* | //')

# Update main.md – append branch outcome to Branch History section
cat >> "$GCC_DIR/main.md" << EOF

### Merged: ${BRANCH_NAME} (${NOW})
**Purpose:** ${BRANCH_PURPOSE}
**Outcome:** ${LAST_COMMIT}
EOF

# Merge commit.md entries into main branch with origin tags
{
  echo ""
  echo "=== Branch ${BRANCH_NAME} ==="
  echo "**Merged:** ${NOW}"
  echo ""
  cat "$BRANCH_DIR/commit.md"
  echo "=== End Branch ${BRANCH_NAME} ==="
  echo ""
} >> "$MAIN_DIR/commit.md"

# Merge log.md with origin tags
{
  echo ""
  echo "== Branch ${BRANCH_NAME} =="
  cat "$BRANCH_DIR/log.md"
  echo "== End Branch ${BRANCH_NAME} =="
  echo ""
} >> "$MAIN_DIR/log.md"

# Reset active branch to main
echo "main" > "$GCC_DIR/.current-branch"

# Git commit
git add "$GCC_DIR"
git commit -m "GCC: merge ${BRANCH_NAME} – ${LAST_COMMIT}"

echo "✓ Branch '${BRANCH_NAME}' merged into main."
echo "  Run 'bash scripts/gcc-context.sh' to see updated project overview."
