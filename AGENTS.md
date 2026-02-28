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
