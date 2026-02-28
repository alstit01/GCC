#!/usr/bin/env bats
load 'test_helper'

setup() { setup_repo; }
teardown() { teardown_repo; }

@test "gcc-init creates .GCC/main.md" {
  run bash scripts/gcc-init.sh "TestProject" "Test goal"
  [ "$status" -eq 0 ]
  [ -f ".GCC/main.md" ]
}

@test "gcc-init creates main branch directory" {
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  [ -d ".GCC/branches/main" ]
  [ -f ".GCC/branches/main/commit.md" ]
  [ -f ".GCC/branches/main/log.md" ]
  [ -f ".GCC/branches/main/metadata.yaml" ]
}

@test "gcc-init writes project name to main.md" {
  bash scripts/gcc-init.sh "MyProject" "My goal"
  grep -q "MyProject" .GCC/main.md
}

@test "gcc-init sets .current-branch to main" {
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  [ -f ".GCC/.current-branch" ]
  run cat .GCC/.current-branch
  [ "$output" = "main" ]
}

@test "gcc-init makes a git commit" {
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  run git log --oneline
  [[ "$output" == *"GCC: initialize"* ]]
}

@test "gcc-init fails if .GCC already exists" {
  bash scripts/gcc-init.sh "TestProject" "Test goal"
  run bash scripts/gcc-init.sh "TestProject" "Test goal"
  [ "$status" -ne 0 ]
  [[ "$output" == *"already initialized"* ]]
}

@test "gcc-init requires exactly 2 arguments" {
  run bash scripts/gcc-init.sh "OnlyOne"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}
