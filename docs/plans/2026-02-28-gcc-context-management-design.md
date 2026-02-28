# GCC Context Management – Design Document
**Date:** 2026-02-28
**Author:** Alexander (alstit01@gmail.com)
**Status:** Approved
**Reference:** Wu, J. (2025). Git Context Controller: Manage the Context of LLM-based Agents like Git. arXiv:2508.00031

---

## 1. Overview

This document defines the design for implementing the **Git-Context-Controller (GCC)** framework in the `alstit01/GCC` repository. GCC elevates Claude's context from passive token streams into a navigable, versioned memory hierarchy — structured like a Git repository.

**Goal:** A `CLAUDE.md` file instructs Claude to act as a GCC-controlled agent, supported by 5 Bash helper scripts that automate all file I/O and Git operations.

**Chosen Approach:** Balanced (Co-Design)
- `CLAUDE.md` (~250 lines): GCC philosophy, trigger conditions, OTA logging protocol, script reference
- `scripts/`: 5 Bash scripts handling all file creation, formatting, and Git commits
- `.GCC/`: Version-controlled memory directory (fully tracked by Git)

---

## 2. Repository Structure

```
GCC/
├── CLAUDE.md                    ← Agent instructions (GCC protocol)
├── .GCC/                        ← GCC memory directory (git-tracked)
│   ├── main.md                  ← Global roadmap & project overview
│   └── branches/
│       └── <branch-name>/
│           ├── commit.md        ← Milestone summaries (append-only)
│           ├── log.md           ← OTA execution trace (real-time)
│           └── metadata.yaml   ← Architecture, file structure, deps
├── scripts/
│   ├── gcc-init.sh              ← Initialize .GCC/ structure
│   ├── gcc-commit.sh            ← COMMIT: checkpoint + git commit
│   ├── gcc-branch.sh            ← BRANCH: new isolated workspace
│   ├── gcc-merge.sh             ← MERGE: synthesize branch to main
│   └── gcc-context.sh          ← CONTEXT: retrieve memory
├── docs/
│   └── plans/
│       └── 2026-02-28-gcc-context-management-design.md  ← this file
└── 2508.00031.pdf               ← Reference paper
```

---

## 3. .GCC/ File System Design

### 3.1 `main.md` – Global Roadmap

Sits at the root of `.GCC/`. Stores:
- Project name and high-level goal
- Key milestones and their current status
- Active branch and its purpose
- To-do list for next steps

Updated after `COMMIT`, `MERGE`, or when the project roadmap shifts significantly. Shared across all branches — the canonical source of project intent.

**Template:**
```markdown
# Project: <name>
**Goal:** <high-level objective>

## Milestones
- [ ] Milestone 1
- [x] Milestone 2 (completed: <date>)

## Active Branch: <branch-name>
**Purpose:** <current focus>

## To-Do
- [ ] Next step 1
- [ ] Next step 2
```

### 3.2 `branches/<name>/commit.md` – Milestone Summaries

Append-only log. Each entry has three blocks (added by `gcc-commit.sh`):

```markdown
## Commit: <timestamp> | <summary>

**Branch Purpose:** <reiterated from BRANCH command>

**Previous Progress Summary:**
<coarse-grained summary synthesized from previous entry>

**This Commit's Contribution:**
<detailed narrative of what was achieved in this commit>
```

### 3.3 `branches/<name>/log.md` – OTA Execution Trace

Real-time append log. Claude writes every reasoning step as it happens, between commits. Format:

```
[OTA <timestamp>] Thought: <reasoning>
[OTA <timestamp>] Action: <tool/command used>
[OTA <timestamp>] Observation: <result/finding>
```

The most recent slice of this log is used to construct `commit.md` summaries upon COMMIT.

### 3.4 `branches/<name>/metadata.yaml` – Structural Metadata

Updated on demand (during or after COMMIT when structural changes are detected):

```yaml
file_structure:
  - path: src/main.py
    responsibility: entry point, CLI handler
  - path: src/utils.py
    responsibility: shared utilities

env_config:
  python: "3.11"
  dependencies:
    - requests==2.31.0

dependencies:
  - module: utils
    used_by: [main, tests]
```

---

## 4. CLAUDE.md Design

### Structure (~250 lines, 4 sections)

**Section 1 – GCC Philosophy (20 lines)**
Explains to Claude: context is not ephemeral tokens but a navigable, versioned file hierarchy. Claude is an agent with persistent memory.

**Section 2 – Command Trigger Conditions (80 lines)**
Clear, non-ambiguous rules for when Claude autonomously invokes each command:

| Command | Trigger Condition |
|---|---|
| `COMMIT` | Coherent milestone reached: module implemented, test passed, analysis done, document completed, hypothesis validated |
| `BRANCH` | Meaningful direction change: alternative algorithm, parallel hypothesis, experimental approach that shouldn't pollute main |
| `MERGE` | Branch has reached a conclusion with a clear outcome (positive or negative) |
| `CONTEXT` | Session start, before MERGE, uncertainty about project state, resuming after interruption |

**Section 3 – OTA Logging Protocol (50 lines)**
Claude writes to `log.md` continuously during work. Each Observation–Thought–Action cycle is logged before the next action is taken. Upon COMMIT, the log since the last commit is referenced to write the summary.

**Section 4 – Script Reference & Examples (100 lines)**
Full syntax for each script, with 2 examples per command (one coding context, one non-coding context).

---

## 5. Bash Scripts Design

All scripts live in `scripts/` and are executable (`chmod +x`). Scripts handle all file I/O, directory creation, templating, and Git operations. Claude's role is to decide WHEN to invoke them and to supply the semantic content (summaries, branch purposes, log entries).

### `gcc-init.sh`
**Invocation:** `bash scripts/gcc-init.sh "<project-name>" "<project-goal>"`
**Actions:**
1. Creates `.GCC/main.md` with populated template
2. Creates `.GCC/branches/main/` with empty `commit.md`, `log.md`, `metadata.yaml`
3. Sets active branch to `main` in `.GCC/.current-branch`
4. Runs `git add .GCC/ && git commit -m "GCC: initialize context controller"`

### `gcc-commit.sh`
**Invocation:** `bash scripts/gcc-commit.sh "<one-line-summary>"`
**Actions:**
1. Reads active branch from `.GCC/.current-branch`
2. Generates commit entry timestamp
3. Appends new entry to `branches/<active>/commit.md` with template (Branch Purpose from last entry, Previous Progress Summary regenerated, "This Commit's Contribution" placeholder marked for Claude to fill → Claude provides via stdin/argument)
4. Optionally prompts Claude to update `main.md`
5. Runs `git add .GCC/ && git commit -m "GCC: <summary>"`

### `gcc-branch.sh`
**Invocation:** `bash scripts/gcc-branch.sh "<branch-name>" "<branch-purpose>"`
**Actions:**
1. Creates `.GCC/branches/<branch-name>/` directory
2. Creates `commit.md` with Branch Purpose header
3. Creates empty `log.md` and `metadata.yaml` template
4. Updates `.GCC/.current-branch` to new branch name
5. Runs `git add .GCC/ && git commit -m "GCC: branch <branch-name> - <branch-purpose>"`

### `gcc-merge.sh`
**Invocation:** `bash scripts/gcc-merge.sh "<branch-name>"`
**Actions:**
1. Reads `branches/<branch-name>/commit.md` for outcome summary
2. Appends branch outcome to `main.md` milestones
3. Appends merged entries to `main` branch's `commit.md` under `=== Branch <branch-name> ===` tags
4. Appends `log.md` content with origin tags (`== Branch <name> ==`) to main's `log.md`
5. Resets `.GCC/.current-branch` to `main`
6. Runs `git add .GCC/ && git commit -m "GCC: merge branch <branch-name>"`

### `gcc-context.sh`
**Invocation:** `bash scripts/gcc-context.sh [options]`
**Options:**
- (no args) — Displays `main.md` + list of all branches with last commit timestamp
- `--branch <name>` — Shows Branch Purpose + last 10 commit entries from `commit.md`
- `--log [n]` — Shows last 20 (or n) lines of active branch's `log.md`
- `--metadata <segment>` — Extracts named segment from `metadata.yaml` (e.g. `file_structure`)
- `--commit <hash>` — Shows full commit entry matching hash/timestamp prefix

Read-only operation — no file writes, no Git operations.

---

## 6. Workflow Example

```
# Session start:
bash scripts/gcc-context.sh                    # → Claude reads project state

# Claude works on task, appending to log.md as it goes...
# [Claude manually writes OTA entries to .GCC/branches/main/log.md]

# Meaningful milestone reached:
bash scripts/gcc-commit.sh "implement user auth module"

# Alternative approach needed:
bash scripts/gcc-branch.sh "auth-jwt" "Explore JWT vs session-based auth"

# Branch work concludes:
bash scripts/gcc-merge.sh "auth-jwt"

# New session: Claude retrieves context
bash scripts/gcc-context.sh --branch main
bash scripts/gcc-context.sh --log 50
```

---

## 7. Non-Functional Requirements

- **Portability:** Scripts use only POSIX-compliant bash, `date`, `git`. No external dependencies.
- **Idempotency:** Re-running `gcc-init.sh` on an existing `.GCC/` directory should warn and not overwrite.
- **Error handling:** Scripts exit with clear error messages if called with wrong arguments or outside a git repo.
- **Encoding:** All files UTF-8. Supports non-ASCII characters (German, etc.) in summaries.

---

## 8. Out of Scope (YAGNI)

- GUI or web interface for context visualization
- Automatic OTA log writing (Claude writes manually — future enhancement)
- Branch diff / comparison tooling
- Integration with GitHub Issues or PRs
- Vector search / RAG over log history

---

## 9. Success Criteria

1. Claude can be given a new task in the GCC repo, run `gcc-context.sh`, and immediately understand where the project left off.
2. Claude autonomously decides when to COMMIT without being explicitly asked.
3. A fresh Claude session can pick up work from a previous session with zero user re-explanation.
4. All 5 scripts run without errors on macOS and Linux.
5. The `.GCC/` history is fully inspectable via standard `git log`.
