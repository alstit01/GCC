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
