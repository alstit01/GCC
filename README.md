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
