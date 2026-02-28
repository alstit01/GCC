#!/usr/bin/env bats
load 'test_helper'

setup() { setup_repo; }
teardown() { teardown_repo; }

@test "full GCC workflow runs without errors" {
  # Init
  run bash scripts/gcc-init.sh "IntegrationProject" "Full workflow test"
  [ "$status" -eq 0 ]

  # First commit on main
  run bash scripts/gcc-commit.sh "Initial setup done" "Set up project structure"
  [ "$status" -eq 0 ]

  # Branch
  run bash scripts/gcc-branch.sh "alt-approach" "Test alternative strategy"
  [ "$status" -eq 0 ]

  # Commit on branch
  run bash scripts/gcc-commit.sh "Explored alternative" "Found it works better"
  [ "$status" -eq 0 ]

  # Return to main and merge
  echo "main" > .GCC/.current-branch
  run bash scripts/gcc-merge.sh "alt-approach"
  [ "$status" -eq 0 ]

  # Context shows full history
  run bash scripts/gcc-context.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"IntegrationProject"* ]]
}

@test "git log has all GCC commits in order" {
  bash scripts/gcc-init.sh "IntegrationProject" "Full workflow test"
  bash scripts/gcc-commit.sh "Milestone one"
  bash scripts/gcc-branch.sh "experiment" "Try something"
  bash scripts/gcc-commit.sh "Experiment done"
  echo "main" > .GCC/.current-branch
  bash scripts/gcc-merge.sh "experiment"

  run git log --oneline
  [[ "$output" == *"GCC: initialize"* ]]
  [[ "$output" == *"GCC: Milestone one"* ]]
  [[ "$output" == *"GCC: branch experiment"* ]]
  [[ "$output" == *"GCC: merge experiment"* ]]
}

@test "context --branch shows merged branch content after merge" {
  bash scripts/gcc-init.sh "IntegrationProject" "Test"
  bash scripts/gcc-branch.sh "feature-y" "Implement Y"
  bash scripts/gcc-commit.sh "Feature Y complete"
  echo "main" > .GCC/.current-branch
  bash scripts/gcc-merge.sh "feature-y"

  run bash scripts/gcc-context.sh --branch main
  [[ "$output" == *"feature-y"* ]]
}
