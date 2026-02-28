#!/usr/bin/env bats
load 'test_helper'

setup() {
  setup_repo
  bash scripts/gcc-init.sh "TestProject" "Test goal"
}
teardown() { teardown_repo; }

@test "gcc-context without args shows main.md content" {
  run bash scripts/gcc-context.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"TestProject"* ]]
}

@test "gcc-context without args shows branch list" {
  run bash scripts/gcc-context.sh
  [[ "$output" == *"main"* ]]
}

@test "gcc-context --branch main shows commit.md" {
  run bash scripts/gcc-context.sh --branch main
  [ "$status" -eq 0 ]
  [[ "$output" == *"Branch: main"* ]]
}

@test "gcc-context --log shows log.md tail" {
  run bash scripts/gcc-context.sh --log
  [ "$status" -eq 0 ]
  [[ "$output" == *"OTA Execution Log"* ]]
}

@test "gcc-context --log N shows last N lines" {
  run bash scripts/gcc-context.sh --log 5
  [ "$status" -eq 0 ]
}

@test "gcc-context --metadata file_structure works" {
  run bash scripts/gcc-context.sh --metadata file_structure
  [ "$status" -eq 0 ]
}

@test "gcc-context fails gracefully if .GCC not initialized" {
  rm -rf .GCC
  run bash scripts/gcc-context.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *"not initialized"* ]]
}

@test "gcc-context --branch with unknown branch shows error" {
  run bash scripts/gcc-context.sh --branch nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}
