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

## Quickstart (humans)

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

That's it. GCC is ready. Your agent will find it automatically.

---

## Agent Compatibility

`setup.sh` automatically creates instruction files for all major agents.
No manual configuration needed — your agent finds GCC automatically.

| Agent | Instruction file created |
|---|---|
| Claude (Anthropic) | `CLAUDE.md` |
| OpenAI Codex | `AGENTS.md` |
| Cursor | `.cursor/rules` |
| Windsurf | `.windsurfrules` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Gemini CLI (Google) | `.gemini/GEMINI.md` |
| Google Antigravity | `.agent/rules/gcc.md` |

---

## For LLM Agents: Self-Setup Instructions

> **This section is for AI agents reading this file.**
> If you are an LLM agent and GCC is not yet set up in your project, follow these steps to set it up yourself.

### Step 1 — Check if GCC is already initialized

```bash
bash scripts/gcc-context.sh
```

If this succeeds, GCC is ready. Skip to **Step 4**.
If it fails with "not initialized", continue to Step 2.

### Step 2 — Check if the GCC scripts exist

```bash
ls scripts/gcc-init.sh 2>/dev/null && echo "scripts present" || echo "scripts missing"
```

If scripts are missing, the user must clone the GCC repository first:

```
Tell the user: "Please run: git clone https://github.com/alstit01/GCC.git and then run: bash GCC/setup.sh . \"<project-name>\" \"<project-goal>\""
```

### Step 3 — Run setup

If scripts are present but `.GCC/` is not initialized yet:

```bash
# Option A: setup.sh is available (recommended — sets up everything at once)
bash GCC/setup.sh . "<project-name>" "<project-goal>"

# Option B: scripts/ is already in the project root
bash scripts/gcc-init.sh "<project-name>" "<project-goal>"
```

### Step 4 — Load context at the start of every session

```bash
bash scripts/gcc-context.sh
```

This is **required** at the start of every session. It gives you the full
project state — roadmap, active branch, recent milestones — before you touch anything.

### Step 5 — Work, log, and commit

During work:
- Append OTA log entries to `.GCC/branches/<active-branch>/log.md`
- After each meaningful unit of work: `bash scripts/gcc-commit.sh "<summary>" "<detail>"`
- To explore an alternative: `bash scripts/gcc-branch.sh "<name>" "<purpose>"`
- To merge a concluded branch: `bash scripts/gcc-merge.sh "<name>"`

### OTA Log Format

```
[OTA 2026-03-01 10:00 UTC] Thought: Need to understand the auth module
[OTA 2026-03-01 10:01 UTC] Action: Read src/auth.py
[OTA 2026-03-01 10:02 UTC] Observation: Session-based auth, lines 42-67 handle login
```

### Decision Reference (agent quick-card)

| Situation | Command |
|---|---|
| Start of session | `bash scripts/gcc-context.sh` |
| Finished a unit of work | `bash scripts/gcc-commit.sh "<summary>" "<detail>"` |
| Exploring an alternative | `bash scripts/gcc-branch.sh "<name>" "<purpose>"` |
| Branch concluded | `echo "main" > .GCC/.current-branch && bash scripts/gcc-merge.sh "<name>"` |
| Lost track of project goal | `bash scripts/gcc-context.sh` |
| Mid-task memory entry | Append directly to `.GCC/branches/<branch>/log.md` |

**Never** use `git commit` for `.GCC/` files directly — always go through the scripts.

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

## The memory hierarchy

```
.GCC/
├── main.md                    ← Global roadmap, milestones, current focus
├── .current-branch            ← Name of the active branch
└── branches/<name>/
    ├── commit.md              ← Append-only milestone summaries
    ├── log.md                 ← Real-time OTA execution trace
    └── metadata.yaml          ← Architecture, file structure, dependencies
```

---

## Advanced: add GCC to an existing project

```bash
# Works with existing git repos — setup.sh detects this automatically
bash GCC/setup.sh /path/to/existing-project "Project Name" "Goal"
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `command not found: bats` | `brew install bats-core` (macOS) or `apt install bats` (Linux) |
| `.GCC already initialized` | GCC is already set up — run `bash scripts/gcc-context.sh` |
| `not a git repository` | `setup.sh` handles this automatically — just run it again |
| Scripts don't run on Windows | Use **Git Bash**, not PowerShell or CMD |

---

## Tests

```bash
# Run the full test suite (requires bats-core)
bats tests/

# macOS: brew install bats-core
# Linux: apt install bats
```

---

## Reference

Based on: Wu, J. (2025). Git Context Controller: Manage the Context of LLM-based Agents like Git. arXiv:2508.00031
