#!/usr/bin/env bash
# gcc-branch.sh – Create isolated GCC workspace for alternative approach
# Usage: gcc-branch.sh "<branch-name>" "<branch-purpose>"
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: gcc-branch.sh \"<branch-name>\" \"<branch-purpose>\"" >&2
  exit 1
fi

GCC_DIR=".GCC"
if [ ! -d "$GCC_DIR" ]; then
  echo "Error: .GCC not initialized. Run 'bash scripts/gcc-init.sh' first." >&2
  exit 1
fi

BRANCH_NAME="$1"
BRANCH_PURPOSE="$2"
BRANCH_DIR="$GCC_DIR/branches/$BRANCH_NAME"
NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

if [ -d "$BRANCH_DIR" ]; then
  echo "Error: Branch '$BRANCH_NAME' already exists in .GCC/branches/" >&2
  exit 1
fi

mkdir -p "$BRANCH_DIR"

# commit.md with branch header
cat > "$BRANCH_DIR/commit.md" << EOF
# Branch: ${BRANCH_NAME}
**Purpose:** ${BRANCH_PURPOSE}
**Created:** ${NOW}
**Branched from:** $(cat "$GCC_DIR/.current-branch")

---
EOF

# log.md
cat > "$BRANCH_DIR/log.md" << EOF
# OTA Execution Log – Branch: ${BRANCH_NAME}
**Purpose:** ${BRANCH_PURPOSE}
**Started:** ${NOW}

---
EOF

# metadata.yaml
cat > "$BRANCH_DIR/metadata.yaml" << EOF
# GCC Metadata – Branch: ${BRANCH_NAME}
# Inherits from parent branch. Update as this branch evolves.

file_structure: []
env_config: {}
dependencies: []
EOF

# Update active branch
echo "$BRANCH_NAME" > "$GCC_DIR/.current-branch"

# Git commit
git add "$GCC_DIR"
git commit -m "GCC: branch ${BRANCH_NAME} – ${BRANCH_PURPOSE}"

echo "✓ Branch '${BRANCH_NAME}' created. Now active."
echo "  Purpose: ${BRANCH_PURPOSE}"
echo "  Run 'bash scripts/gcc-context.sh --branch ${BRANCH_NAME}' to verify."
