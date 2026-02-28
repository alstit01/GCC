# GCC – Git Context Controller

A structured context management framework for Claude, inspired by Git version control.
Claude manages its reasoning memory through COMMIT, BRANCH, MERGE, and CONTEXT operations —
so it never "forgets" what it has done, even across multiple sessions.

---

## What is GCC?

Normally, Claude loses all context when a conversation ends. GCC solves this by storing
Claude's memory in a `.GCC/` folder that is tracked by Git. At the start of every session,
Claude reads this folder and knows exactly where it left off.

Think of it like Git for Claude's brain: every milestone is a commit, every experiment
is a branch, and the full history is always recoverable.

---

## Quickstart: Using GCC in a new project

### Step 1 – Prerequisites

You need:
- **Git** installed → [Download here](https://git-scm.com/downloads)
- **A terminal** (on Windows: use **Git Bash**, which is installed with Git)
- **Claude** (this framework works with Claude in any coding environment)

To check if Git is installed, open a terminal and run:
```bash
git --version
```
You should see something like `git version 2.40.0`. If not, install Git first.

---

### Step 2 – Set up a new project

Open your terminal (Git Bash on Windows), navigate to the folder where you want your project, and run:

```bash
# Create a new folder for your project
mkdir my-project
cd my-project

# Initialize a Git repository
git init -b main
git config user.email "your@email.com"
git config user.name "Your Name"

# Make an initial commit so Git has something to work with
git commit --allow-empty -m "initial"
```

---

### Step 3 – Copy the GCC scripts into your project

Copy the `scripts/` folder from this repository into your project root:

```bash
# Either clone this repo and copy:
cp -r /path/to/GCC/scripts ./scripts

# Or on Windows in Git Bash:
cp -r C:/Users/YourName/Documents/GitHub/GCC/scripts ./scripts
```

Your project folder should now look like this:
```
my-project/
├── scripts/
│   ├── gcc-init.sh
│   ├── gcc-context.sh
│   ├── gcc-commit.sh
│   ├── gcc-branch.sh
│   └── gcc-merge.sh
```

---

### Step 4 – Initialize GCC

```bash
bash scripts/gcc-init.sh "My Project Name" "What I want to achieve with this project"
```

Example:
```bash
bash scripts/gcc-init.sh "Online Shop" "Build a simple webshop with product listings and a cart"
```

This creates a `.GCC/` folder with Claude's memory structure and makes the first Git commit automatically.

---

### Step 5 – Add CLAUDE.md

Copy the `CLAUDE.md` file from this repository into your project root:

```bash
cp /path/to/GCC/CLAUDE.md ./CLAUDE.md
```

This file tells Claude how to use GCC. Without it, Claude won't know to use the memory system.

---

### Step 6 – Start working with Claude

Open Claude (e.g. in Claude.ai, Cursor, or any other Claude-powered editor) and point it to your project folder.

**At the start of every session**, Claude will automatically run:
```bash
bash scripts/gcc-context.sh
```
...and read the full project history before doing anything.

---

## The four GCC commands

You don't need to run these yourself — Claude does it automatically. But it's useful to understand what they do:

| Command | What it does | When Claude uses it |
|---------|-------------|---------------------|
| `gcc-init.sh` | Sets up GCC in a new project | Once, at project start |
| `gcc-context.sh` | Reads the current memory state | At the start of every session |
| `gcc-commit.sh` | Saves a milestone to memory | After finishing a meaningful unit of work |
| `gcc-branch.sh` | Creates a memory branch for an experiment | When exploring an alternative approach |
| `gcc-merge.sh` | Merges a branch back into the main memory | After an experiment is concluded |

---

## Day-to-day workflow

Once GCC is set up, your workflow is simple:

1. **Open a new Claude session** in your project
2. **Claude reads `.GCC/`** and knows everything that happened before
3. **Claude works** and logs its steps to `log.md`
4. **Claude commits** milestones to `commit.md` and creates Git commits automatically
5. **Next session**: repeat from step 1 — no context is lost

---

## Troubleshooting

**"No such file or directory" when running a script**
→ Make sure you are in the project root folder (the one containing `scripts/`).

**Scripts don't execute on Windows**
→ Use **Git Bash** (not PowerShell or CMD). Right-click in your project folder → "Git Bash Here".

**".GCC already initialized" error**
→ GCC is already set up in this folder. Just run `bash scripts/gcc-context.sh` to see the current state.

**Git says "not a git repository"**
→ You forgot step 2. Run `git init -b main` first, then `gcc-init.sh` again.

---

## Development setup (optional)

If you want to run the automated tests:

```bash
# macOS
brew install bats-core

# Linux
apt install bats

# Run all tests
bats tests/
```

---

## Reference

Based on: Wu, J. (2025). Git Context Controller: Manage the Context of LLM-based Agents like Git. arXiv:2508.00031
