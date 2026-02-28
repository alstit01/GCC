# Common setup/teardown for GCC tests
# Creates an isolated temp git repo for each test

setup_repo() {
  export TEST_DIR="$(mktemp -d)"
  cd "$TEST_DIR"
  git init -b main
  git config user.email "test@test.com"
  git config user.name "Test"
  # Make scripts available
  cp -r "$BATS_TEST_DIRNAME/../scripts" .
  # Initial empty commit (needed for git operations)
  git commit --allow-empty -m "initial"
}

teardown_repo() {
  rm -rf "$TEST_DIR"
}
