#!/usr/bin/env bash
# setup.sh – Universal GCC setup for any project, any LLM agent
#
# Usage:
#   bash setup.sh <target-dir> "<project-name>" "<project-goal>"
#   bash setup.sh          (interactive wizard)
#
# Supported agents (instruction files created automatically):
#   Claude (Anthropic)      → CLAUDE.md
#   OpenAI Codex            → AGENTS.md
#   Cursor                  → .cursor/rules
#   Windsurf                → .windsurfrules
#   GitHub Copilot          → .github/copilot-instructions.md
#   Gemini CLI (Google)     → .gemini/GEMINI.md
#   Antigravity (Google)    → .agent/rules/gcc.md
#
set -euo pipefail

# ─── Locate this script's source directory (the GCC repo) ────────────────────

GCC_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Parse arguments or enter interactive wizard ──────────────────────────────

if [ $# -eq 0 ]; then
  echo ""
  echo "GCC – Git Context Controller"
  echo "Universal Setup Wizard"
  echo "─────────────────────────────────────────"
  printf "Target directory [.]: "
  read -r TARGET_DIR
  TARGET_DIR="${TARGET_DIR:-.}"
  printf "Project name: "
  read -r PROJECT_NAME
  printf "Project goal (one sentence): "
  read -r PROJECT_GOAL
  echo ""
elif [ $# -eq 3 ]; then
  TARGET_DIR="$1"
  PROJECT_NAME="$2"
  PROJECT_GOAL="$3"
else
  echo "Usage: bash setup.sh <target-dir> \"<project-name>\" \"<project-goal>\"" >&2
  echo "       bash setup.sh  (interactive wizard)" >&2
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
  # Set placeholder identity if not globally configured
  if ! git config user.email > /dev/null 2>&1; then
    git config user.email "gcc-setup@local"
    git config user.name "GCC Setup"
  fi
  echo "✓ Initialized git repository"
fi

# Create initial commit if none exists
if ! git rev-parse HEAD > /dev/null 2>&1; then
  git commit --allow-empty -m "initial"
  echo "✓ Created initial git commit"
fi

# ─── Copy GCC scripts ─────────────────────────────────────────────────────────

cp -r "$GCC_SOURCE_DIR/scripts" .
chmod +x scripts/*.sh
echo "✓ Copied GCC scripts"

# ─── Initialize GCC memory structure ─────────────────────────────────────────

bash scripts/gcc-init.sh "$PROJECT_NAME" "$PROJECT_GOAL"

# ─── Generate agent instruction files ────────────────────────────────────────

AGENTS_SRC="$GCC_SOURCE_DIR/AGENTS.md"

if [ ! -f "$AGENTS_SRC" ]; then
  echo "Error: AGENTS.md not found in GCC source directory: $GCC_SOURCE_DIR" >&2
  exit 1
fi

AGENTS_CONTENT=$(cat "$AGENTS_SRC")

_write_agent_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$AGENTS_CONTENT" > "$path"
}

# Primary (universal – OpenAI Codex, most open-source agents)
_write_agent_file "AGENTS.md"

# Claude (Anthropic) – reads CLAUDE.md
_write_agent_file "CLAUDE.md"

# Cursor – reads .cursor/rules
_write_agent_file ".cursor/rules"

# Windsurf – reads .windsurfrules
_write_agent_file ".windsurfrules"

# GitHub Copilot – reads .github/copilot-instructions.md
_write_agent_file ".github/copilot-instructions.md"

# Gemini CLI – reads .gemini/GEMINI.md
_write_agent_file ".gemini/GEMINI.md"

# Google Antigravity – reads .agent/rules/
_write_agent_file ".agent/rules/gcc.md"

echo "✓ Created agent instruction files (AGENTS.md + 6 agent-specific copies)"

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────"
echo "✓ GCC setup complete!"
echo ""
echo "  Project : $PROJECT_NAME"
echo "  Goal    : $PROJECT_GOAL"
echo "  Location: $(pwd)"
echo ""
echo "  Supported agents:"
echo "    Claude · OpenAI Codex · Cursor · Windsurf"
echo "    GitHub Copilot · Gemini CLI · Antigravity"
echo ""
echo "  Start your agent — it will find GCC automatically."
echo "  First thing it will run: bash scripts/gcc-context.sh"
echo ""
