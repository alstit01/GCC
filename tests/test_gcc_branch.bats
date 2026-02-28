#!/usr/bin/env bats
load 'test_helper'

setup() {
  setup_repo
  bash scripts/gcc-init.sh "TestProject" "Test goal"
}
teardown() { teardown_repo; }

@test "gcc-branch requires name and purpose" {
  run bash scripts/gcc-branch.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "gcc-branch creates branch directory" {
  bash scripts/gcc-branch.sh "feature-x" "Explore feature X approach"
  [ -d ".GCC/branches/feature-x" ]
}

@test "gcc-branch creates commit.md with purpose" {
  bash scripts/gcc-branch.sh "feature-x" "Explore feature X approach"
  run grep "Explore feature X approach" .GCC/branches/feature-x/commit.md
  [ "$status" -eq 0 ]
}

@test "gcc-branch creates empty log.md" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  [ -f ".GCC/branches/feature-x/log.md" ]
}

@test "gcc-branch creates metadata.yaml" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  [ -f ".GCC/branches/feature-x/metadata.yaml" ]
}

@test "gcc-branch updates .current-branch" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  run cat .GCC/.current-branch
  [ "$output" = "feature-x" ]
}

@test "gcc-branch creates a git commit" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  run git log --oneline
  [[ "$output" == *"GCC: branch feature-x"* ]]
}

@test "gcc-branch fails if branch already exists" {
  bash scripts/gcc-branch.sh "feature-x" "Explore X"
  run bash scripts/gcc-branch.sh "feature-x" "Try again"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already exists"* ]]
}
