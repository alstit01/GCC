#!/usr/bin/env bash
# gcc-init.sh – Initialize GCC context controller in current git repo
# Usage: gcc-init.sh "<project-name>" "<project-goal>"
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: gcc-init.sh \"<project-name>\" \"<project-goal>\"" >&2
  exit 1
fi

PROJECT_NAME="$1"
PROJECT_GOAL="$2"
GCC_DIR=".GCC"

if [ -d "$GCC_DIR" ]; then
  echo "Error: .GCC already initialized in this directory." >&2
  exit 1
fi

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: Not inside a git repository. Run 'git init' first." >&2
  exit 1
fi

NOW=$(date -u +"%Y-%m-%d %H:%M UTC")

# Create directory structure
mkdir -p "$GCC_DIR/branches/main"

# main.md – global roadmap
cat > "$GCC_DIR/main.md" << EOF
# Project: ${PROJECT_NAME}
**Goal:** ${PROJECT_GOAL}
**Initialized:** ${NOW}

## Milestones
- [ ] (Add milestones here)

## Active Branch: main
**Purpose:** Initial project setup and development

## To-Do
- [ ] (Add next steps here)

## Branch History
(Branches merged into main will be listed here)
EOF

# branches/main/commit.md – milestone summaries
cat > "$GCC_DIR/branches/main/commit.md" << EOF
# Branch: main
**Purpose:** Initial project setup and development
**Created:** ${NOW}

---
EOF

# branches/main/log.md – OTA trace
cat > "$GCC_DIR/branches/main/log.md" << EOF
# OTA Execution Log – Branch: main
**Started:** ${NOW}

---
EOF

# branches/main/metadata.yaml
cat > "$GCC_DIR/branches/main/metadata.yaml" << EOF
# GCC Metadata – Branch: main
# Update this file when structural/architectural changes occur

file_structure: []
  # Example:
  # - path: src/main.py
  #   responsibility: entry point

env_config: {}
  # Example:
  # python: "3.11"
  # node: "20"

dependencies: []
  # Example:
  # - module: utils
  #   used_by: [main, tests]
EOF

# Track active branch
echo "main" > "$GCC_DIR/.current-branch"

# Git commit
git add "$GCC_DIR"
git commit -m "GCC: initialize context controller – ${PROJECT_NAME}"

echo "✓ GCC initialized. Active branch: main"
echo "  Next: Run 'bash scripts/gcc-context.sh' to see project state."
