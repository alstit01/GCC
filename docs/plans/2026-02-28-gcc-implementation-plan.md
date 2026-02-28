# GCC Context Management – Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the Git-Context-Controller (GCC) framework as a CLAUDE.md + 5 Bash scripts that enable Claude to manage its context like a version-controlled memory system across sessions.

**Architecture:** A `CLAUDE.md` file (~250 lines) instructs Claude about GCC philosophy and trigger conditions; 5 Bash scripts handle all file I/O, directory management, and Git commits; a `.GCC/` directory (tracked by Git) stores the three-tier memory hierarchy (main.md, commit.md, log.md, metadata.yaml).

**Tech Stack:** Bash (POSIX-compatible), Git, YAML (manual, no parser required), Markdown. Testing via [bats-core](https://github.com/bats-core/bats-core).

**Reference:** See `docs/plans/2026-02-28-gcc-context-management-design.md` for full design rationale.

---

## Pre-Flight Checklist

Before starting:
- [ ] You are in the `GCC/` repository root
- [ ] `git status` shows a clean working tree (only `docs/` and `2508.00031.pdf`)
- [ ] `git --version` works (Git ≥ 2.30)
- [ ] `bash --version` works (Bash ≥ 4.0)

---

## Task 1: Repository Bootstrap

**Goal:** Set up .gitignore, README, and test infrastructure.

**Files:**
- Create: `.gitignore`
- Create: `README.md`
- Create: `tests/` directory with bats setup

**Step 1: Create .gitignore**

```bash
cat > .gitignore << 'EOF'
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
*.swp
*.swo

# Test artifacts
tests/tmp/
*.bak
EOF
```

**Step 2: Create README.md**

```bash
cat > README.md << 'EOF'
# GCC – Git Context Controller

A structured context management framework for Claude, inspired by Git version control.
Claude manages its reasoning memory through COMMIT, BRANCH, MERGE, and CONTEXT operations.

## Setup

```bash
# Install test runner (optional, for development)
brew install bats-core   # macOS
# or: apt install bats   # Linux

# Initialize GCC in your project
bash scripts/gcc-init.sh "My Project" "Describe your project goal here"
```

## Usage

Claude will automatically use GCC during work. See `CLAUDE.md` for protocol details.

## Reference

Based on: Wu, J. (2025). Git Context Controller. arXiv:2508.00031
EOF
```

**Step 3: Create tests directory and helper**

```bash
mkdir -p tests/tmp

cat > tests/test_helper.bash << 'EOF'
# Common setup/teardown for GCC tests
# Creates an isolated temp git repo for each test

setup_repo() {
  export TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -b main
  git config user.email "test@test.com"
  git config user.name "Test"
  # Make scripts available
  cp -r "$BATS_TEST_DIRNAME/../scripts" .
  # Initial empty commit (needed for git operations)
  git commit --allow-empty -m "initial"
}

teardown_repo() {
  rm -rf "$TEST_DIR"
}
EOF
```

**Step 4: Commit**

```bash
git add .gitignore README.md tests/
git commit -m "chore: bootstrap repository with gitignore, README, test infrastructure"
```

Expected: `1 file changed` or `3 files changed`

---

## Task 2: `gcc-init.sh`

**Goal:** Initialize the `.GCC/` directory structure with templates and make the first GCC git commit.

**Files:**
- Create: `scripts/gcc-init.sh`
- Create: `tests/test_gcc_init.bats`

**Step 1: Write the failing test**

```bash
cat > tests/test_gcc_init.bats << 'EOF'
#!/usr/bin/env bats
load 'test_helper'

setup() { setup_repo; }
teardown() { teardown_repo; }

@test "gcc-init creates .GCC/main.md" {
  run bash scripts/gcc-init.sh "TestProject" "Test goal"
  [ "$status" -eq 0 ]
  [ -f ".GCC/main.md" ]
}

@test "gcc-init creates main branch directory" {
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  [ -d ".GCC/branches/main" ]
  [ -f ".GCC/branches/main/commit.md" ]
  [ -f ".GCC/branches/main/log.md" ]
  [ -f ".GCC/branches/main/metadata.yaml" ]
}

@test "gcc-init writes project name to main.md" {
  bash scripts/gcc-init.sh "MyProject" "My goal"
  grep -q "MyProject" .GCC/main.md
}

@test "gcc-init sets .current-branch to main" {
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  [ -f ".GCC/.current-branch" ]
  run cat .GCC/.current-branch
  [ "$output" = "main" ]
}

@test "gcc-init makes a git commit" {
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  run git log --oneline
  [[ "$output" == *"GCC: initialize"* ]]
}

@test "gcc-init fails if .GCC already exists" {
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  run bash scripts/gcc-init.sh "TestProject" "Test goal"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already initialized"* ]]
}

@test "gcc-init requires exactly 2 arguments" {
  run bash scripts/gcc-init.sh "OnlyOne"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}
EOF
```

**Step 2: Run test to verify it fails**

```bash
bats tests/test_gcc_init.bats
```

Expected: All tests FAIL with "No such file or directory" (script doesn't exist yet).
*(If bats is not installed: `brew install bats-core` or `apt install bats`)*

**Step 3: Create `scripts/gcc-init.sh`**

```bash
mkdir -p scripts

cat > scripts/gcc-init.sh << 'SCRIPT'
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
SCRIPT

chmod +x scripts/gcc-init.sh
```

**Step 4: Run tests to verify they pass**

```bash
bats tests/test_gcc_init.bats
```

Expected: All 7 tests PASS.

**Step 5: Commit**

```bash
git add scripts/gcc-init.sh tests/test_gcc_init.bats
git commit -m "feat: add gcc-init.sh with tests"
```

---

## Task 3: `gcc-context.sh`

**Goal:** Read-only script to display GCC memory at multiple granularity levels.
*(Build context retrieval before commit, so we can test state inspection in later tasks.)*

**Files:**
- Create: `scripts/gcc-context.sh`
- Create: `tests/test_gcc_context.bats`

**Step 1: Write the failing test**

```bash
cat > tests/test_gcc_context.bats << 'EOF'
#!/usr/bin/env bats
load 'test_helper'

setup() {
  setup_repo
  bash scripts/gcc-init.sh "TestProject" "Test goal"
}
teardown() { teardown_repo; }

@test "gcc-context without args shows main.md content" {
  run bash scripts/gcc-context.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"TestProject"* ]]
}

@test "gcc-context without args shows branch list" {
  run bash scripts/gcc-context.sh
  [[ "$output" == *"main"* ]]
}

@test "gcc-context --branch main shows commit.md" {
  run bash scripts/gcc-context.sh --branch main
  [ "$status" -eq 0 ]
  [[ "$output" == *"Branch: main"* ]]
}

@test "gcc-context --log shows log.md tail" {
  run bash scripts/gcc-context.sh --log
  [ "$status" -eq 0 ]
  [[ "$output" == *"OTA Execution Log"* ]]
}

@test "gcc-context --log N shows last N lines" {
  run bash scripts/gcc-context.sh --log 5
  [ "$status" -eq 0 ]
}

@test "gcc-context --metadata file_structure works" {
  run bash scripts/gcc-context.sh --metadata file_structure
  [ "$status" -eq 0 ]
}

@test "gcc-context fails gracefully if .GCC not initialized" {
  rm -rf .GCC
  run bash scripts/gcc-context.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"not initialized"* ]]
}

@test "gcc-context --branch with unknown branch shows error" {
  run bash scripts/gcc-context.sh --branch nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}
EOF
```

**Step 2: Run test to verify it fails**

```bash
bats tests/test_gcc_context.bats
```

Expected: All FAIL.

**Step 3: Create `scripts/gcc-context.sh`**

```bash
cat > scripts/gcc-context.sh << 'SCRIPT'
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
SCRIPT

chmod +x scripts/gcc-context.sh
```

**Step 4: Run tests**

```bash
bats tests/test_gcc_context.bats
```

Expected: All 8 tests PASS.

**Step 5: Commit**

```bash
git add scripts/gcc-context.sh tests/test_gcc_context.bats
git commit -m "feat: add gcc-context.sh with tests"
```

---

## Task 4: `gcc-commit.sh`

**Goal:** Checkpoint meaningful progress — append to `commit.md`, git commit.

**Files:**
- Create: `scripts/gcc-commit.sh`
- Create: `tests/test_gcc_commit.bats`

**Step 1: Write the failing test**

```bash
cat > tests/test_gcc_commit.bats << 'EOF'
#!/usr/bin/env bats
load 'test_helper'

setup() {
  setup_repo
  bash scripts/gcc-init.sh "TestProject" "Test goal"
}
teardown() { teardown_repo; }

@test "gcc-commit requires summary argument" {
  run bash scripts/gcc-commit.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "gcc-commit appends entry to commit.md" {
  bash scripts/gcc-commit.sh "Implemented feature X"
  run grep "Implemented feature X" .GCC/branches/main/commit.md
  [ "$status" -eq 0 ]
}

@test "gcc-commit entry contains Branch Purpose block" {
  bash scripts/gcc-commit.sh "Test commit"
  run grep "Branch Purpose" .GCC/branches/main/commit.md
  [ "$status" -eq 0 ]
}

@test "gcc-commit entry contains This Commit Contribution block" {
  bash scripts/gcc-commit.sh "Test commit"
  run grep "This Commit" .GCC/branches/main/commit.md
  [ "$status" -eq 0 ]
}

@test "gcc-commit creates a git commit with GCC prefix" {
  bash scripts/gcc-commit.sh "My progress"
  run git log --oneline
  [[ "$output" == *"GCC: My progress"* ]]
}

@test "gcc-commit multiple commits accumulate in commit.md" {
  bash scripts/gcc-commit.sh "First milestone"
  bash scripts/gcc-commit.sh "Second milestone"
  run grep -c "^## Commit:" .GCC/branches/main/commit.md
  [ "$output" -eq 2 ]
}

@test "gcc-commit fails gracefully if not initialized" {
  rm -rf .GCC
  run bash scripts/gcc-commit.sh "test"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not initialized"* ]]
}
EOF
```

**Step 2: Run test to verify it fails**

```bash
bats tests/test_gcc_commit.bats
```

Expected: All FAIL.

**Step 3: Create `scripts/gcc-commit.sh`**

```bash
cat > scripts/gcc-commit.sh << 'SCRIPT'
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
BRANCH_PURPOSE=$(grep -m1 "^**Purpose:**" "$COMMIT_MD" 2>/dev/null | sed 's/\*\*Purpose:\*\* //' || echo "(see branch header)")

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
SCRIPT

chmod +x scripts/gcc-commit.sh
```

**Step 4: Run tests**

```bash
bats tests/test_gcc_commit.bats
```

Expected: All 7 tests PASS.

**Step 5: Commit**

```bash
git add scripts/gcc-commit.sh tests/test_gcc_commit.bats
git commit -m "feat: add gcc-commit.sh with tests"
```

---

## Task 5: `gcc-branch.sh`

**Goal:** Create an isolated workspace for exploring alternative approaches.

**Files:**
- Create: `scripts/gcc-branch.sh`
- Create: `tests/test_gcc_branch.bats`

**Step 1: Write the failing test**

```bash
cat > tests/test_gcc_branch.bats << 'EOF'
#!/usr/bin/env bats
load 'test_helper'

setup() {
  setup_repo
  bash scripts/gcc-init.sh "TestProject" "Test goal"
}
teardown() { teardown_repo; }

@test "gcc-branch requires name and purpose" {
  run bash scripts/gcc-branch.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "gcc-branch creates branch directory" {
  bash scripts/gcc-branch.sh "feature-x" "Explore feature X approach"
  [ -d ".GCC/branches/feature-x" ]
}

@test "gcc-branch creates commit.md with purpose" {
  bash scripts/gcc-branch.sh "feature-x" "Explore feature X approach"
  run grep "Explore feature X approach" .GCC/branches/feature-x/commit.md
  [ "$status" -eq 0 ]
}

@test "gcc-branch creates empty log.md" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  [ -f ".GCC/branches/feature-x/log.md" ]
}

@test "gcc-branch creates metadata.yaml" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  [ -f ".GCC/branches/feature-x/metadata.yaml" ]
}

@test "gcc-branch updates .current-branch" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  run cat .GCC/.current-branch
  [ "$output" = "feature-x" ]
}

@test "gcc-branch creates a git commit" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  run git log --oneline
  [[ "$output" == *"GCC: branch feature-x"* ]]
}

@test "gcc-branch fails if branch already exists" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  run bash scripts/gcc-branch.sh "feature-x" "Try again"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already exists"* ]]
}
EOF
```

**Step 2: Run test to verify it fails**

```bash
bats tests/test_gcc_branch.bats
```

Expected: All FAIL.

**Step 3: Create `scripts/gcc-branch.sh`**

```bash
cat > scripts/gcc-branch.sh << 'SCRIPT'
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
SCRIPT

chmod +x scripts/gcc-branch.sh
```

**Step 4: Run tests**

```bash
bats tests/test_gcc_branch.bats
```

Expected: All 8 tests PASS.

**Step 5: Commit**

```bash
git add scripts/gcc-branch.sh tests/test_gcc_branch.bats
git commit -m "feat: add gcc-branch.sh with tests"
```

---

## Task 6: `gcc-merge.sh`

**Goal:** Synthesize a branch's results back into the main trajectory.

**Files:**
- Create: `scripts/gcc-merge.sh`
- Create: `tests/test_gcc_merge.bats`

**Step 1: Write the failing test**

```bash
cat > tests/test_gcc_merge.bats << 'EOF'
#!/usr/bin/env bats
load 'test_helper'

setup() {
  setup_repo
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  bash scripts/gcc-branch.sh "experiment-a" "Test experimental approach"
  bash scripts/gcc-commit.sh "Finished experiment"
  # Switch back to main manually for merge test
  echo "main" > .GCC/.current-branch
}
teardown() { teardown_repo; }

@test "gcc-merge requires branch name" {
  run bash scripts/gcc-merge.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "gcc-merge updates main.md with branch outcome" {
  bash scripts/gcc-merge.sh "experiment-a"
  run grep "experiment-a" .GCC/main.md
  [ "$status" -eq 0 ]
}

@test "gcc-merge appends to main commit.md with origin tags" {
  bash scripts/gcc-merge.sh "experiment-a"
  run grep "=== Branch experiment-a ===" .GCC/branches/main/commit.md
  [ "$status" -eq 0 ]
}

@test "gcc-merge appends log with origin tags" {
  bash scripts/gcc-merge.sh "experiment-a"
  run grep "== Branch experiment-a ==" .GCC/branches/main/log.md
  [ "$status" -eq 0 ]
}

@test "gcc-merge resets active branch to main" {
  bash scripts/gcc-merge.sh "experiment-a"
  run cat .GCC/.current-branch
  [ "$output" = "main" ]
}

@test "gcc-merge creates a git commit" {
  bash scripts/gcc-merge.sh "experiment-a"
  run git log --oneline
  [[ "$output" == *"GCC: merge experiment-a"* ]]
}

@test "gcc-merge fails if branch does not exist" {
  run bash scripts/gcc-merge.sh "nonexistent"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}
EOF
```

**Step 2: Run test to verify it fails**

```bash
bats tests/test_gcc_merge.bats
```

Expected: All FAIL.

**Step 3: Create `scripts/gcc-merge.sh`**

```bash
cat > scripts/gcc-merge.sh << 'SCRIPT'
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
LAST_COMMIT=$(grep "^## Commit:" "$BRANCH_DIR/commit.md" | tail -1 | sed 's/## Commit: [^ ]* | //')

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
git commit -m "GCC: merge branch ${BRANCH_NAME} – ${LAST_COMMIT}"

echo "✓ Branch '${BRANCH_NAME}' merged into main."
echo "  Run 'bash scripts/gcc-context.sh' to see updated project overview."
SCRIPT

chmod +x scripts/gcc-merge.sh
```

**Step 4: Run tests**

```bash
bats tests/test_gcc_merge.bats
```

Expected: All 7 tests PASS.

**Step 5: Commit**

```bash
git add scripts/gcc-merge.sh tests/test_gcc_merge.bats
git commit -m "feat: add gcc-merge.sh with tests"
```

---

## Task 7: `CLAUDE.md`

**Goal:** Write the agent instruction file that makes Claude act as a GCC-controlled agent.

**Files:**
- Create: `CLAUDE.md`

**Step 1: Create `CLAUDE.md`**

```bash
cat > CLAUDE.md << 'EOF'
# GCC – Git Context Controller Protocol

You are operating with a structured, versioned context management system called
**Git Context Controller (GCC)**. Your context is not a passive token history —
it is a navigable, persistent memory hierarchy stored in `.GCC/` and tracked by Git.

**At the start of every session, run:**
```bash
bash scripts/gcc-context.sh
```
This gives you the full project state before you touch anything.

---

## The Memory Hierarchy

```
.GCC/
├── main.md                    ← Global roadmap, milestones, current focus
└── branches/<name>/
    ├── commit.md              ← Append-only milestone summaries
    ├── log.md                 ← Real-time OTA execution trace
    └── metadata.yaml         ← Architecture, file structure, dependencies
```

**Three tiers of memory:**
1. `main.md` — High-level: what is the project, where are we, what's next
2. `commit.md` — Mid-level: what milestones have been reached, in what order
3. `log.md` — Fine-grained: every reasoning step, observation, and action

---

## The Four Commands

### COMMIT — Checkpoint meaningful progress

**When to invoke:**
- A coherent unit of work is complete: module implemented, test passing, analysis finished, document drafted, hypothesis validated, design decision made
- You would naturally "save your work" at this point
- Before switching to a significantly different task

**How to invoke:**
```bash
bash scripts/gcc-commit.sh "<one-line-summary>" "<detailed contribution>"
```

**Examples:**
- `bash scripts/gcc-commit.sh "implement user authentication" "Added JWT-based auth with bcrypt password hashing. Tests pass."`
- `bash scripts/gcc-commit.sh "complete market analysis" "Analyzed 5 competitors, identified 3 positioning gaps, drafted recommendations."`

---

### BRANCH — Explore an alternative approach

**When to invoke:**
- You want to try a different algorithm, architecture, or strategy without affecting the current trajectory
- You are starting a parallel experiment or hypothesis test
- A user asks you to explore an alternative without committing to it
- You detect a meaningful divergence in direction

**How to invoke:**
```bash
bash scripts/gcc-branch.sh "<branch-name>" "<branch-purpose>"
```

**Examples:**
- `bash scripts/gcc-branch.sh "auth-oauth" "Explore OAuth2 as alternative to JWT"`
- `bash scripts/gcc-branch.sh "report-pdf" "Try PDF format instead of HTML for the deliverable"`

**Branch names:** lowercase-hyphenated, descriptive (not "test1" or "experiment").

---

### MERGE — Synthesize branch results into main

**When to invoke:**
- A branch has reached a clear conclusion (positive or negative outcome)
- The branch work should inform or update the main trajectory
- Before closing out a branch permanently

**How to invoke:**
```bash
# First, make sure active branch is set back to main:
echo "main" > .GCC/.current-branch
# Then merge:
bash scripts/gcc-merge.sh "<branch-name>"
```

**Always:** Run `gcc-context.sh --branch <name>` before merging to review what you are bringing in.

---

### CONTEXT — Retrieve memory

**When to invoke (REQUIRED):**
- At the start of every new session
- Before executing a MERGE
- When you are uncertain about the current project state
- When resuming after an interruption

**When to invoke (PROACTIVE):**
- Whenever you feel you are losing track of the larger goal
- When about to make an architectural decision

**Options:**
```bash
bash scripts/gcc-context.sh                       # Full overview: main.md + branches
bash scripts/gcc-context.sh --branch <name>       # Branch detail: purpose + commits
bash scripts/gcc-context.sh --log [n]             # Last n lines of OTA log (default 20)
bash scripts/gcc-context.sh --metadata <segment>  # Architecture snapshot
```

---

## OTA Logging Protocol

You **must** log every meaningful reasoning step to `log.md` as you work. This is your
fine-grained memory — the commit summaries are built from it.

**Format — append to `.GCC/branches/<active-branch>/log.md`:**
```
[OTA 2026-02-28 14:03 UTC] Thought: Need to understand the existing auth module before modifying it
[OTA 2026-02-28 14:03 UTC] Action: Read src/auth.py
[OTA 2026-02-28 14:04 UTC] Observation: Uses session-based auth, no JWT. Lines 42-67 handle login.
```

**What to log:**
- Every `Read`, `Bash`, `Edit`, `Write` tool call and its result
- Key decisions and their rationale
- Dead ends and why they were abandoned
- Test results

**What NOT to log:**
- Routine boilerplate (e.g. "Created directory")
- Exact file contents (too verbose) — log the key observation instead

---

## Decision Reference Card

| Situation | Action |
|---|---|
| Starting a new session | `gcc-context.sh` |
| Finished a meaningful unit of work | `gcc-commit.sh` |
| Wanting to try an alternative | `gcc-branch.sh` |
| Branch experiment concluded | `gcc-merge.sh` |
| Lost track of project goals | `gcc-context.sh` |
| Before a major architectural decision | `gcc-context.sh --branch main` |
| Mid-task log entry | Append to `log.md` directly |

---

## Important: Git Commits

Every GCC operation (COMMIT, BRANCH, MERGE, INIT) automatically creates a Git commit
in `.GCC/`. Do NOT use `git commit` for GCC memory files yourself — always go through
the scripts. Use regular `git commit` only for project source files.

---

## Initialization (first time only)

```bash
bash scripts/gcc-init.sh "<project-name>" "<your project goal>"
```

---

*Based on: Wu, J. (2025). Git Context Controller: Manage the Context of LLM-based Agents like Git. arXiv:2508.00031*
EOF
```

**Step 2: Verify CLAUDE.md renders correctly (spot check)**

```bash
# Check it exists and has expected sections
grep -c "^### " CLAUDE.md   # should be >= 4 sections
grep -c "gcc-context.sh" CLAUDE.md  # should be >= 5 references
wc -l CLAUDE.md             # should be ~220-260 lines
```

Expected: Section count ≥ 4, gcc-context references ≥ 5, line count 220–260.

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add CLAUDE.md with GCC protocol instructions"
```

---

## Task 8: Integration Test

**Goal:** Verify that a complete GCC workflow (init → log → commit → branch → commit → merge → context) works end-to-end.

**Files:**
- Create: `tests/test_integration.bats`

**Step 1: Write the integration test**

```bash
cat > tests/test_integration.bats << 'EOF'
#!/usr/bin/env bats
load 'test_helper'

setup() { setup_repo; }
teardown() { teardown_repo; }

@test "full GCC workflow runs without errors" {
  # Init
  run bash scripts/gcc-init.sh "IntegrationProject" "Full workflow test"
  [ "$status" -eq 0 ]

  # First commit on main
  run bash scripts/gcc-commit.sh "Initial setup done" "Set up project structure"
  [ "$status" -eq 0 ]

  # Branch
  run bash scripts/gcc-branch.sh "alt-approach" "Test alternative strategy"
  [ "$status" -eq 0 ]

  # Commit on branch
  run bash scripts/gcc-commit.sh "Explored alternative" "Found it works better"
  [ "$status" -eq 0 ]

  # Return to main and merge
  echo "main" > .GCC/.current-branch
  run bash scripts/gcc-merge.sh "alt-approach"
  [ "$status" -eq 0 ]

  # Context shows full history
  run bash scripts/gcc-context.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"IntegrationProject"* ]]
}

@test "git log has all GCC commits in order" {
  bash scripts/gcc-init.sh "IntegrationProject" "Full workflow test"
  bash scripts/gcc-commit.sh "Milestone one"
  bash scripts/gcc-branch.sh "experiment" "Try something"
  bash scripts/gcc-commit.sh "Experiment done"
  echo "main" > .GCC/.current-branch
  bash scripts/gcc-merge.sh "experiment"

  run git log --oneline
  [[ "$output" == *"GCC: initialize"* ]]
  [[ "$output" == *"GCC: Milestone one"* ]]
  [[ "$output" == *"GCC: branch experiment"* ]]
  [[ "$output" == *"GCC: merge experiment"* ]]
}

@test "context --branch shows merged branch content after merge" {
  bash scripts/gcc-init.sh "IntegrationProject" "Test"
  bash scripts/gcc-branch.sh "feature-y" "Implement Y"
  bash scripts/gcc-commit.sh "Feature Y complete"
  echo "main" > .GCC/.current-branch
  bash scripts/gcc-merge.sh "feature-y"

  run bash scripts/gcc-context.sh --branch main
  [[ "$output" == *"feature-y"* ]]
}
EOF
```

**Step 2: Run integration tests**

```bash
bats tests/test_integration.bats
```

Expected: All 3 tests PASS.

**Step 3: Run full test suite**

```bash
bats tests/
```

Expected: All tests PASS (≥ 33 tests total across all files).

**Step 4: Commit**

```bash
git add tests/test_integration.bats
git commit -m "test: add end-to-end integration tests"
```

---

## Task 9: GitHub Remote & Final Polish

**Goal:** Push to GitHub, add remote, verify README links correctly.

**Step 1: Set up GitHub remote**

```bash
git remote add origin https://github.com/alstit01/GCC.git
git branch -M main
```

**Step 2: Final git log review**

```bash
git log --oneline
```

Expected output (all commits present, in order):
```
<hash> test: add end-to-end integration tests
<hash> feat: add CLAUDE.md with GCC protocol instructions
<hash> feat: add gcc-merge.sh with tests
<hash> feat: add gcc-branch.sh with tests
<hash> feat: add gcc-commit.sh with tests
<hash> feat: add gcc-context.sh with tests
<hash> feat: add gcc-init.sh with tests
<hash> chore: bootstrap repository with gitignore, README, test infrastructure
<hash> docs: add GCC design document and reference paper
```

**Step 3: Push to GitHub**

*(Requires user confirmation — only run when ready)*

```bash
git push -u origin main
```

**Step 4: Smoke test from scratch**

In a fresh terminal or temp directory, clone and test:

```bash
cd /tmp
git clone https://github.com/alstit01/GCC.git gcc-test
cd gcc-test
bash scripts/gcc-init.sh "SmokeTest" "Verify GCC works after clone"
bash scripts/gcc-context.sh
```

Expected: `.GCC/` created, `main.md` displayed, no errors.

---

## Summary

| Task | Deliverable | Tests |
|---|---|---|
| 1 | `.gitignore`, `README.md`, `tests/test_helper.bash` | — |
| 2 | `scripts/gcc-init.sh` | 7 tests |
| 3 | `scripts/gcc-context.sh` | 8 tests |
| 4 | `scripts/gcc-commit.sh` | 7 tests |
| 5 | `scripts/gcc-branch.sh` | 8 tests |
| 6 | `scripts/gcc-merge.sh` | 7 tests |
| 7 | `CLAUDE.md` | (manual verify) |
| 8 | `tests/test_integration.bats` | 3 tests |
| 9 | GitHub remote + smoke test | — |

**Total automated tests: ≥ 40**
