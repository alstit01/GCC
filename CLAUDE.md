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
