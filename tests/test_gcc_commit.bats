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
