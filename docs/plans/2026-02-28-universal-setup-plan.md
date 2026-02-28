# GCC Universal Setup – Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the manual 4-step setup with a single `setup.sh` that works for any LLM agent (Claude, Cursor, Windsurf, Copilot, Gemini CLI, Google Antigravity) and any project state (new or existing).

**Architecture:** `AGENTS.md` is created in the GCC repo as the agent-neutral instruction template. `setup.sh` reads it and copies its content into all 7 agent-specific file locations in the target project. All other scripts remain unchanged.

**Tech Stack:** Bash (POSIX-compatible), Git, bats-core for tests. Zero new dependencies.

**Design doc:** `docs/plans/2026-02-28-universal-setup-design.md`

---

## Pre-Flight Checklist

- [ ] In the GCC repo root
- [ ] `git status` is clean
- [ ] `bats --version` works (bats ≥ 1.5)

---

## Task 1: `AGENTS.md` – Agent-neutral instruction file

**Goal:** Create the template that `setup.sh` copies into target projects. Same protocol as `CLAUDE.md`, but with agent-agnostic wording.

**Files:**
- Create: `AGENTS.md`

**Step 1: Create `AGENTS.md`**

```bash
cat > AGENTS.md << 'EOF'
# GCC – Git Context Controller Protocol

This project uses **GCC (Git Context Controller)** — a structured, versioned memory
system for AI agents. Context is not a passive token history — it is a navigable,
persistent memory hierarchy stored in `.GCC/` and tracked by Git.

**At the start of every session, run:**
```bash
bash scripts/gcc-context.sh
```
This gives the full project state before touching anything.

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
- A coherent unit of work is complete
- Before switching to a significantly different task

**How to invoke:**
```bash
bash scripts/gcc-commit.sh "<one-line-summary>" "<detailed contribution>"
```

---

### BRANCH — Explore an alternative approach

**When to invoke:**
- Trying a different algorithm, architecture, or strategy
- Starting a parallel experiment or hypothesis test

**How to invoke:**
```bash
bash scripts/gcc-branch.sh "<branch-name>" "<branch-purpose>"
```

**Branch names:** lowercase-hyphenated, descriptive.

---

### MERGE — Synthesize branch results into main

**When to invoke:**
- A branch has reached a clear conclusion
- Before closing out a branch permanently

**How to invoke:**
```bash
echo "main" > .GCC/.current-branch
bash scripts/gcc-merge.sh "<branch-name>"
```

---

### CONTEXT — Retrieve memory

**When to invoke (REQUIRED):**
- At the start of every new session
- Before executing a MERGE
- When uncertain about the current project state

**Options:**
```bash
bash scripts/gcc-context.sh                       # Full overview
bash scripts/gcc-context.sh --branch <name>       # Branch detail
bash scripts/gcc-context.sh --log [n]             # Last n log lines
bash scripts/gcc-context.sh --metadata <segment>  # Architecture snapshot
```

---

## OTA Logging Protocol

Log every meaningful reasoning step to `log.md` during work.

**Format:**
```
[OTA 2026-02-28 14:03 UTC] Thought: Need to understand the existing auth module
[OTA 2026-02-28 14:03 UTC] Action: Read src/auth.py
[OTA 2026-02-28 14:04 UTC] Observation: Uses session-based auth. Lines 42-67 handle login.
```

**Log:** every Read/Edit/Write/Bash call, key decisions, dead ends, test results.
**Skip:** routine boilerplate, exact file contents.

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

Every GCC operation (COMMIT, BRANCH, MERGE, INIT) automatically creates a Git commit.
Do NOT use `git commit` for `.GCC/` files — always go through the scripts.

---

## Initialization (first time only)

```bash
bash scripts/gcc-init.sh "<project-name>" "<your project goal>"
```

---

*Based on: Wu, J. (2025). Git Context Controller: Manage the Context of LLM-based Agents like Git. arXiv:2508.00031*
EOF
```

**Step 2: Verify content**

```bash
grep -c "^### " AGENTS.md   # expected: ≥ 4
grep -c "gcc-context.sh" AGENTS.md  # expected: ≥ 5
wc -l AGENTS.md             # expected: ~130-160
```

**Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "feat: add AGENTS.md as agent-neutral GCC instruction template"
```

---

## Task 2: `tests/test_setup.bats` – Write failing tests first

**Goal:** Define the full expected behavior of `setup.sh` before implementing it.

**Files:**
- Create: `tests/test_setup.bats`

**Step 1: Create the test file**

```bash
cat > tests/test_setup.bats << 'EOF'
#!/usr/bin/env bats
# Tests for setup.sh – universal GCC project setup

GCC_SOURCE_DIR="$BATS_TEST_DIRNAME/.."

setup() {
  export TARGET_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TARGET_DIR"
}

# ─── Basic happy path ────────────────────────────────────────────────────────

@test "setup exits 0 with valid args" {
  run bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ "$status" -eq 0 ]
}

@test "setup creates .GCC directory in target" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -d "$TARGET_DIR/.GCC" ]
}

@test "setup creates AGENTS.md in target" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -f "$TARGET_DIR/AGENTS.md" ]
}

# ─── Agent-specific files ────────────────────────────────────────────────────

@test "setup creates CLAUDE.md" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -f "$TARGET_DIR/CLAUDE.md" ]
}

@test "setup creates .cursor/rules" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -f "$TARGET_DIR/.cursor/rules" ]
}

@test "setup creates .windsurfrules" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -f "$TARGET_DIR/.windsurfrules" ]
}

@test "setup creates .github/copilot-instructions.md" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -f "$TARGET_DIR/.github/copilot-instructions.md" ]
}

@test "setup creates .gemini/GEMINI.md" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -f "$TARGET_DIR/.gemini/GEMINI.md" ]
}

@test "setup creates .agent/rules/gcc.md" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -f "$TARGET_DIR/.agent/rules/gcc.md" ]
}

@test "all agent files have identical content" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  diff "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/CLAUDE.md"
  diff "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/.cursor/rules"
  diff "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/.windsurfrules"
  diff "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/.github/copilot-instructions.md"
  diff "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/.gemini/GEMINI.md"
  diff "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/.agent/rules/gcc.md"
}

@test "agent files contain GCC protocol content" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  grep -q "gcc-context.sh" "$TARGET_DIR/AGENTS.md"
  grep -q "gcc-commit.sh" "$TARGET_DIR/AGENTS.md"
  grep -q "gcc-branch.sh" "$TARGET_DIR/AGENTS.md"
}

# ─── Scripts ─────────────────────────────────────────────────────────────────

@test "setup copies all 5 scripts into target" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -f "$TARGET_DIR/scripts/gcc-init.sh" ]
  [ -f "$TARGET_DIR/scripts/gcc-context.sh" ]
  [ -f "$TARGET_DIR/scripts/gcc-commit.sh" ]
  [ -f "$TARGET_DIR/scripts/gcc-branch.sh" ]
  [ -f "$TARGET_DIR/scripts/gcc-merge.sh" ]
}

@test "setup makes scripts executable" {
  bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ -x "$TARGET_DIR/scripts/gcc-init.sh" ]
  [ -x "$TARGET_DIR/scripts/gcc-context.sh" ]
  [ -x "$TARGET_DIR/scripts/gcc-commit.sh" ]
  [ -x "$TARGET_DIR/scripts/gcc-branch.sh" ]
  [ -x "$TARGET_DIR/scripts/gcc-merge.sh" ]
}

# ─── Git handling ─────────────────────────────────────────────────────────────

@test "setup initializes git if not present" {
  run bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ "$status" -eq 0 ]
  [ -d "$TARGET_DIR/.git" ]
}

@test "setup skips git init if repo already exists" {
  git init -b main "$TARGET_DIR"
  git -C "$TARGET_DIR" config user.email "test@test.com"
  git -C "$TARGET_DIR" config user.name "Test"
  git -C "$TARGET_DIR" commit --allow-empty -m "initial"
  run bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ "$status" -eq 0 ]
  [ -d "$TARGET_DIR/.GCC" ]
}

@test "setup creates initial commit if git has no commits" {
  git init -b main "$TARGET_DIR"
  git -C "$TARGET_DIR" config user.email "test@test.com"
  git -C "$TARGET_DIR" config user.name "Test"
  # No commits yet
  run bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "TestProject" "Test goal"
  [ "$status" -eq 0 ]
  git -C "$TARGET_DIR" log --oneline | grep -q "initial"
}

# ─── Directory creation ───────────────────────────────────────────────────────

@test "setup creates target directory if it does not exist" {
  NEW_DIR="$TARGET_DIR/brand-new-project"
  run bash "$GCC_SOURCE_DIR/setup.sh" "$NEW_DIR" "TestProject" "Test goal"
  [ "$status" -eq 0 ]
  [ -d "$NEW_DIR" ]
}

# ─── Error handling ───────────────────────────────────────────────────────────

@test "setup fails with wrong number of arguments" {
  run bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "OnlyName"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "setup fails if project name is empty" {
  run bash "$GCC_SOURCE_DIR/setup.sh" "$TARGET_DIR" "" "Some goal"
  [ "$status" -ne 0 ]
}
EOF
```

**Step 2: Run tests to confirm all fail**

```bash
export PATH="/sessions/loving-great-johnson/tools/bats-install/bin:$PATH"
bats tests/test_setup.bats 2>&1 | grep -E "^(ok|not ok)"
```

Expected: all `not ok` (setup.sh doesn't exist yet).

**Step 3: Commit the failing tests**

```bash
git add tests/test_setup.bats
git commit -m "test: add failing tests for setup.sh"
```

---

## Task 3: `setup.sh` – Implement the script

**Goal:** Make all tests from Task 2 pass.

**Files:**
- Create: `setup.sh`

**Step 1: Create `setup.sh`**

```bash
cat > setup.sh << 'SCRIPT'
#!/usr/bin/env bash
# setup.sh – Universal GCC setup for any project, any LLM agent
# Usage:
#   bash setup.sh <target-dir> "<project-name>" "<project-goal>"
#   bash setup.sh          (interactive wizard)
set -euo pipefail

# Locate this script's source directory (the GCC repo)
GCC_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Parse arguments or enter interactive wizard ──────────────────────────────

if [ $# -eq 0 ]; then
  echo "GCC Universal Setup"
  echo "─────────────────────────────────────────"
  printf "Target directory [.]: "
  read -r TARGET_DIR
  TARGET_DIR="${TARGET_DIR:-.}"
  printf "Project name: "
  read -r PROJECT_NAME
  printf "Project goal: "
  read -r PROJECT_GOAL
  echo ""
elif [ $# -eq 3 ]; then
  TARGET_DIR="$1"
  PROJECT_NAME="$2"
  PROJECT_GOAL="$3"
else
  echo "Usage: setup.sh [<target-dir> \"<project-name>\" \"<project-goal>\"]" >&2
  echo "       setup.sh  (interactive mode)" >&2
  exit 1
fi

# ─── Validate inputs ──────────────────────────────────────────────────────────

if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_GOAL" ]; then
  echo "Error: Project name and goal cannot be empty." >&2
  exit 1
fi

# ─── Create target directory if needed ───────────────────────────────────────

if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
  echo "✓ Created directory: $TARGET_DIR"
fi

cd "$TARGET_DIR"

# ─── Git setup ────────────────────────────────────────────────────────────────

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  git init -b main
  if ! git config user.email > /dev/null 2>&1; then
    git config user.email "gcc-setup@local"
    git config user.name "GCC Setup"
  fi
  echo "✓ Initialized git repository"
fi

# Create initial commit if none exists
if ! git rev-parse HEAD > /dev/null 2>&1; then
  git commit --allow-empty -m "initial"
  echo "✓ Created initial commit"
fi

# ─── Copy GCC scripts ─────────────────────────────────────────────────────────

cp -r "$GCC_SOURCE_DIR/scripts" .
chmod +x scripts/*.sh
echo "✓ Copied GCC scripts"

# ─── Initialize GCC memory structure ─────────────────────────────────────────

bash scripts/gcc-init.sh "$PROJECT_NAME" "$PROJECT_GOAL"

# ─── Generate agent instruction files ────────────────────────────────────────

AGENTS_CONTENT=$(cat "$GCC_SOURCE_DIR/AGENTS.md")

# Primary (universal – OpenAI Codex, most open-source agents)
printf '%s\n' "$AGENTS_CONTENT" > AGENTS.md

# Claude (Anthropic)
printf '%s\n' "$AGENTS_CONTENT" > CLAUDE.md

# Cursor
mkdir -p .cursor
printf '%s\n' "$AGENTS_CONTENT" > .cursor/rules

# Windsurf
printf '%s\n' "$AGENTS_CONTENT" > .windsurfrules

# GitHub Copilot
mkdir -p .github
printf '%s\n' "$AGENTS_CONTENT" > .github/copilot-instructions.md

# Gemini CLI
mkdir -p .gemini
printf '%s\n' "$AGENTS_CONTENT" > .gemini/GEMINI.md

# Google Antigravity
mkdir -p .agent/rules
printf '%s\n' "$AGENTS_CONTENT" > .agent/rules/gcc.md

echo "✓ Created agent instruction files (AGENTS.md + 6 agent-specific copies)"

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────"
echo "✓ GCC setup complete!"
echo ""
echo "  Project:  $PROJECT_NAME"
echo "  Location: $(pwd)"
echo ""
echo "  Start your agent – it will find GCC automatically."
echo "  Works with: Claude · Cursor · Windsurf · Copilot · Gemini · Antigravity"
SCRIPT

chmod +x setup.sh
```

**Step 2: Run the tests**

```bash
export PATH="/sessions/loving-great-johnson/tools/bats-install/bin:$PATH"
bats tests/test_setup.bats
```

Expected: all tests PASS.

**Step 3: If any tests fail** – debug with:

```bash
bats tests/test_setup.bats --print-output-on-failure
```

**Step 4: Run full test suite to check for regressions**

```bash
bats tests/
```

Expected: all 40 existing tests + new setup tests pass.

**Step 5: Commit**

```bash
git add setup.sh
git commit -m "feat: add setup.sh – universal one-command GCC setup for any LLM agent"
```

---

## Task 4: Update `README.md`

**Goal:** Simplify the quickstart to 2 steps, add agent compatibility table.

**Files:**
- Modify: `README.md`

**Step 1: Rewrite README.md**

```bash
cat > README.md << 'EOF'
# GCC – Git Context Controller

A context memory framework for AI agents, inspired by Git version control.
Agents manage reasoning memory through COMMIT, BRANCH, MERGE, and CONTEXT operations —
so nothing is lost between sessions.

---

## What is GCC?

AI agents lose all context when a session ends. GCC solves this by storing
agent memory in a `.GCC/` folder tracked by Git. At the start of every session,
the agent reads this folder and knows exactly where it left off.

Think of it like Git for agent memory: every milestone is a commit, every
experiment is a branch, and the full history is always recoverable.

---

## Quickstart

### Prerequisites

- **Git** → [git-scm.com/downloads](https://git-scm.com/downloads)
- **A terminal** — on Windows use **Git Bash** (installed with Git)

### Setup (2 steps)

**Step 1: Clone GCC**

```bash
git clone https://github.com/alstit01/GCC.git
```

**Step 2: Run setup in your project**

```bash
bash GCC/setup.sh /path/to/my-project "My Project Name" "What I want to build"
```

Or run without arguments for the interactive wizard:

```bash
bash GCC/setup.sh
```

That's it. GCC is ready.

---

## Agent Compatibility

`setup.sh` automatically creates instruction files for all major agents:

| Agent | File created |
|---|---|
| Claude (Anthropic) | `CLAUDE.md` |
| OpenAI Codex | `AGENTS.md` |
| Cursor | `.cursor/rules` |
| Windsurf | `.windsurfrules` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Gemini CLI | `.gemini/GEMINI.md` |
| Google Antigravity | `.agent/rules/gcc.md` |

No manual configuration needed — your agent finds GCC automatically.

---

## How it works (day-to-day)

1. **Open a session** in your project with any supported agent
2. **Agent reads `.GCC/`** and knows the full project history
3. **Agent works** and logs steps to `log.md` automatically
4. **Agent commits milestones** to `commit.md` and creates Git commits
5. **Next session:** repeat from step 1 — no context is lost

---

## The four GCC commands

The agent runs these automatically. You don't need to use them yourself.

| Command | What it does |
|---|---|
| `gcc-context.sh` | Reads current memory state — run at start of every session |
| `gcc-commit.sh` | Saves a milestone checkpoint |
| `gcc-branch.sh` | Opens a memory branch for an experiment |
| `gcc-merge.sh` | Merges branch results back into main memory |

---

## Advanced: add GCC to an existing project

```bash
# Works with existing git repos too — setup.sh detects this automatically
bash GCC/setup.sh /path/to/existing-project "Project Name" "Goal"
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `command not found` | Make sure you're in the right directory; use Git Bash on Windows |
| `.GCC already initialized` | GCC is already set up — run `bash scripts/gcc-context.sh` to see status |
| `not a git repository` | setup.sh handles this automatically — just run it again |
| Scripts don't run on Windows | Use **Git Bash**, not PowerShell or CMD |

---

## Development / Tests

```bash
# Run the full test suite (requires bats-core)
bats tests/

# macOS: brew install bats-core
# Linux: apt install bats
```

---

## Reference

Based on: Wu, J. (2025). Git Context Controller: Manage the Context of LLM-based Agents like Git. arXiv:2508.00031
EOF
```

**Step 2: Verify**

```bash
grep -c "^## " README.md   # expected: ≥ 6 sections
grep -c "Antigravity" README.md  # expected: ≥ 1
wc -l README.md  # expected: ~120-160
```

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README with one-command setup and agent compatibility table"
```

---

## Task 5: Final verification

**Step 1: Run full test suite**

```bash
export PATH="/sessions/loving-great-johnson/tools/bats-install/bin:$PATH"
bats tests/
```

Expected: all tests pass (≥ 58 total).

**Step 2: Smoke test the complete setup flow**

```bash
SMOKE_DIR=$(mktemp -d)
bash setup.sh "$SMOKE_DIR" "SmokeTest" "Verify everything works"

# Verify agent files exist and are identical
diff "$SMOKE_DIR/AGENTS.md" "$SMOKE_DIR/CLAUDE.md"
diff "$SMOKE_DIR/AGENTS.md" "$SMOKE_DIR/.cursor/rules"
diff "$SMOKE_DIR/AGENTS.md" "$SMOKE_DIR/.gemini/GEMINI.md"
diff "$SMOKE_DIR/AGENTS.md" "$SMOKE_DIR/.agent/rules/gcc.md"

# Verify GCC context works
cd "$SMOKE_DIR" && bash scripts/gcc-context.sh

echo "✓ All smoke tests passed"
```

Expected: all diffs empty, context output shows "SmokeTest".

**Step 3: Git log review**

```bash
git log --oneline
```

Expected:
```
docs: rewrite README with one-command setup and agent compatibility table
feat: add setup.sh – universal one-command GCC setup for any LLM agent
test: add failing tests for setup.sh
feat: add AGENTS.md as agent-neutral GCC instruction template
docs: add universal setup design document
...
```

---

## Summary

| Task | Deliverable | Tests |
|---|---|---|
| 1 | `AGENTS.md` (agent-neutral template) | — |
| 2 | `tests/test_setup.bats` | ~20 failing tests |
| 3 | `setup.sh` | all ~20 pass |
| 4 | `README.md` updated | — |
| 5 | Full suite + smoke test | ≥ 58 total pass |
