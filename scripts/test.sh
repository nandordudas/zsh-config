#!/usr/bin/env bash
# scripts/test.sh
# Validates the zsh-config repository without touching your real dotfiles.
#
# Usage:
#   ./scripts/test.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; PASS=$((PASS + 1)); }
fail() { printf "  \033[31m✗\033[0m %s\n" "$1"; FAIL=$((FAIL + 1)); }
skip() { printf "  \033[33m-\033[0m %s\n" "$1"; }

section() { printf "\n\033[1;36m▸ %s\033[0m\n" "$1"; }

check() {
  local desc="$1"; shift
  if "$@" &>/dev/null; then
    ok "$desc"
  else
    fail "$desc"
  fi
}

# Run cmd, capture combined stdout+stderr. Ignores the command's exit code.
capture() { "$@" 2>&1 || true; }

# -----------------------------------------------------------------------------
# 1. Syntax checks
# -----------------------------------------------------------------------------
section "Syntax"

for f in "$REPO_DIR"/scripts/*.sh; do
  check "bash -n $(basename "$f")" bash -n "$f"
done

if command -v zsh &>/dev/null; then
  for f in "$REPO_DIR"/modules/*.zsh \
            "$REPO_DIR"/.zshrc \
            "$REPO_DIR"/.zprofile; do
    check "zsh -n $(basename "$f")" zsh -n "$f"
  done
else
  skip "zsh not found — skipping zsh syntax checks (install zsh to enable)"
fi

# -----------------------------------------------------------------------------
# 2. Required files exist
# -----------------------------------------------------------------------------
section "File structure"

required_files=(
  .zshrc
  .zprofile
  .gitignore
  modules/options.zsh
  modules/zinit.zsh
  modules/completions.zsh
  modules/keybindings.zsh
  modules/aliases.zsh
  modules/functions.zsh
  modules/tools.zsh
  scripts/git-setup.sh
  README.md
)

for f in "${required_files[@]}"; do
  check "$f exists" test -f "$REPO_DIR/$f"
done

# -----------------------------------------------------------------------------
# 3. No leaked personal data
# -----------------------------------------------------------------------------
section "No personal data"

# Search all tracked source files, excluding this test script itself
# (which contains the pattern as a literal string for detection purposes).
PERSONAL_EMAIL="nandor.dudas""@gmail.com"   # split so grep won't self-match

if grep -r "$PERSONAL_EMAIL" "$REPO_DIR" \
     --include="*.sh" --include="*.zsh" --include="*.md" \
     --exclude="test.sh" \
     --exclude-dir=".git" &>/dev/null; then
  fail "Personal email still present in repo"
else
  ok "No personal email leaked"
fi

if grep -q -- "--github\|--bitbucket" "$REPO_DIR/scripts/git-setup.sh"; then
  fail "--github/--bitbucket flags still present in git-setup.sh"
else
  ok "--github/--bitbucket args removed from git-setup.sh"
fi

# -----------------------------------------------------------------------------
# 4. Removed args are rejected at runtime
# -----------------------------------------------------------------------------
section "git-setup.sh argument parsing"

out=$(capture bash "$REPO_DIR/scripts/git-setup.sh" --github foo)
if echo "$out" | grep -q "Unknown option"; then
  ok "--github rejected with 'Unknown option'"
else
  fail "--github not properly rejected"
fi

out=$(capture bash "$REPO_DIR/scripts/git-setup.sh" --bitbucket foo)
if echo "$out" | grep -q "Unknown option"; then
  ok "--bitbucket rejected with 'Unknown option'"
else
  fail "--bitbucket not properly rejected"
fi

# -----------------------------------------------------------------------------
# 5. Dry-run of git-setup.sh in an isolated temp $HOME
# -----------------------------------------------------------------------------
section "git-setup.sh dry-run (isolated temp home)"

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

# Pre-create a fake SSH key pair so ssh-keygen is not required
mkdir -p "$TMP_HOME/.ssh"
chmod 700 "$TMP_HOME/.ssh"
# Minimal fake keys (not valid for real use — only needed to skip generation)
printf "fake-private-key\n"                        > "$TMP_HOME/.ssh/id_ed25519"
printf "ssh-ed25519 AAAAFAKE test@example.com\n"   > "$TMP_HOME/.ssh/id_ed25519.pub"
chmod 600 "$TMP_HOME/.ssh/id_ed25519"

GIT_SETUP_OUT=$(HOME="$TMP_HOME" XDG_CONFIG_HOME="$TMP_HOME/.config" \
  capture bash "$REPO_DIR/scripts/git-setup.sh" \
    --name "Test User" \
    --email "test@example.com")

if HOME="$TMP_HOME" XDG_CONFIG_HOME="$TMP_HOME/.config" \
   bash "$REPO_DIR/scripts/git-setup.sh" \
     --name "Test User" \
     --email "test@example.com" &>/dev/null; then
  ok "git-setup.sh exited 0"
else
  fail "git-setup.sh exited non-zero"
  printf "    output: %s\n" "$GIT_SETUP_OUT"
fi

GIT_DIR="$TMP_HOME/.config/git"

check "~/.config/git/config created"                test -f "$GIT_DIR/config"
check "~/.config/git/ignore created"                test -f "$GIT_DIR/ignore"
check "~/.config/git/allowed_signers created"       test -f "$GIT_DIR/allowed_signers"
check "~/.config/git/github/.gitconfig created"     test -f "$GIT_DIR/github/.gitconfig"
check "~/.config/git/bitbucket/.gitconfig created"  test -f "$GIT_DIR/bitbucket/.gitconfig"
check "~/.ssh directory created"                    test -d "$TMP_HOME/.ssh"

# Verify name/email injected correctly
if [[ -f "$GIT_DIR/config" ]]; then
  if grep -q "name = Test User"        "$GIT_DIR/config" && \
     grep -q "email = test@example.com" "$GIT_DIR/config"; then
    ok "name/email correctly written to config"
  else
    fail "name/email missing or wrong in config"
  fi

  if grep -q "fsmonitor = false" "$GIT_DIR/config"; then
    ok "fsmonitor = false (WSL safe)"
  else
    fail "fsmonitor not set to false"
  fi

  if grep -q "__GIT_NAME__\|__GIT_EMAIL__" "$GIT_DIR/config"; then
    fail "Unreplaced placeholders left in config"
  else
    ok "No unreplaced placeholders in config"
  fi

  if grep -r "$PERSONAL_EMAIL" "$GIT_DIR" &>/dev/null; then
    fail "Personal email found in generated git config"
  else
    ok "No personal email in generated git config"
  fi
fi

if [[ -f "$GIT_DIR/allowed_signers" ]]; then
  if grep -q "test@example.com" "$GIT_DIR/allowed_signers"; then
    ok "allowed_signers contains correct email"
  else
    fail "allowed_signers missing email"
  fi
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
printf "\n\033[1m%s passed, %s failed\033[0m\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
