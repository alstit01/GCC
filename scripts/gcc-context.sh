#!/usr/bin/env bash
# gcc-context.sh – Retrieve GCC memory at various granularity levels
# Usage:
#   gcc-context.sh                      → main.md + branch list
#   gcc-context.sh --branch <name>      → branch purpose + last 10 commits
#   gcc-context.sh --log [n]            → last 20 (or n) lines of active log.md
#   gcc-context.sh --metadata <segment> → named section from metadata.yaml
set -euo pipefail

GCC_DIR=".GCC"

if [ ! -d "$GCC_DIR" ]; then
  echo "Error: .GCC not initialized. Run 'bash scripts/gcc-init.sh' first." >&2
  exit 1
fi

CURRENT_BRANCH=$(cat "$GCC_DIR/.current-branch" 2>/dev/null || echo "main")

case "${1:-}" in
  "")
    echo "=== GCC CONTEXT: Project Overview ==="
    echo ""
    cat "$GCC_DIR/main.md"
    echo ""
    echo "=== Available Branches ==="
    for branch_dir in "$GCC_DIR/branches"/*/; do
      branch=$(basename "$branch_dir")
      # Get last commit timestamp from commit.md
      last_commit=$(grep "^## Commit:" "$branch_dir/commit.md" 2>/dev/null | tail -1 | sed 's/## Commit: //' || echo "no commits")
      marker=""
      [ "$branch" = "$CURRENT_BRANCH" ] && marker=" ← active"
      echo "  • $branch  ($last_commit)$marker"
    done
    ;;

  --branch)
    BRANCH="${2:-$CURRENT_BRANCH}"
    BRANCH_DIR="$GCC_DIR/branches/$BRANCH"
    if [ ! -d "$BRANCH_DIR" ]; then
      echo "Error: Branch '$BRANCH' not found in .GCC/branches/" >&2
      exit 1
    fi
    echo "=== GCC CONTEXT: Branch '$BRANCH' ==="
    echo ""
    cat "$BRANCH_DIR/commit.md"
    ;;

  --log)
    N="${2:-20}"
    LOG="$GCC_DIR/branches/$CURRENT_BRANCH/log.md"
    echo "=== GCC CONTEXT: OTA Log (last $N lines) – Branch: $CURRENT_BRANCH ==="
    echo ""
    tail -n "$N" "$LOG"
    ;;

  --metadata)
    SEGMENT="${2:-}"
    META="$GCC_DIR/branches/$CURRENT_BRANCH/metadata.yaml"
    echo "=== GCC CONTEXT: Metadata [$SEGMENT] – Branch: $CURRENT_BRANCH ==="
    echo ""
    if [ -z "$SEGMENT" ]; then
      cat "$META"
    else
      # Extract section by name (lines from "segment:" until next top-level key or EOF)
      awk "/^${SEGMENT}:/{found=1} found{print; if(NR>1 && /^[a-z]/ && !/^${SEGMENT}:/) exit}" "$META"
    fi
    ;;

  --commit)
    HASH="${2:-}"
    COMMIT_MD="$GCC_DIR/branches/$CURRENT_BRANCH/commit.md"
    if [ -z "$HASH" ]; then
      echo "Usage: gcc-context.sh --commit <hash-or-timestamp-prefix>" >&2
      exit 1
    fi
    echo "=== GCC CONTEXT: Commit '$HASH' ==="
    # Extract the commit block matching the hash
    awk "/## Commit:.*${HASH}/{found=1} found{print; if(/^---$/ && NR>1){found=0}}" "$COMMIT_MD"
    ;;

  *)
    echo "Usage: gcc-context.sh [--branch <name>] [--log [n]] [--metadata <segment>] [--commit <hash>]" >&2
    exit 1
    ;;
esac
