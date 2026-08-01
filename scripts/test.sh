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

for f in "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/install.sh "$REPO_DIR"/uninstall.sh; do
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
  install.sh
  uninstall.sh
  Brewfile
  Brewfile.dev
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

# Hardcoded /Users/<name> paths belong in the gitignored modules/local.zsh.
# This caught the committed Headroom PATH block in .zshrc.
if git -C "$REPO_DIR" grep -nI -- '/Users/[a-z]' -- \
     '*.sh' '*.zsh' '.zshrc' '.zprofile' '*.toml' \
     ':!scripts/test.sh' &>/dev/null; then
  fail "Hardcoded /Users/<name> path in a tracked config file"
  git -C "$REPO_DIR" grep -nI -- '/Users/[a-z]' -- \
    '*.sh' '*.zsh' '.zshrc' '.zprofile' '*.toml' ':!scripts/test.sh' | sed 's/^/    /'
else
  ok "No hardcoded home paths in tracked config"
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

check "$HOME/.config/git/config created"                test -f "$GIT_DIR/config"
check "$HOME/.config/git/ignore created"                test -f "$GIT_DIR/ignore"
check "$HOME/.config/git/allowed_signers created"       test -f "$GIT_DIR/allowed_signers"
check "$HOME/.config/git/github/.gitconfig created"     test -f "$GIT_DIR/github/.gitconfig"
check "$HOME/.config/git/bitbucket/.gitconfig created"  test -f "$GIT_DIR/bitbucket/.gitconfig"
check "$HOME/.ssh directory created"                    test -d "$TMP_HOME/.ssh"

# Verify name/email injected correctly
if [[ -f "$GIT_DIR/config" ]]; then
  if grep -q "name = Test User"        "$GIT_DIR/config" && \
     grep -q "email = test@example.com" "$GIT_DIR/config"; then
    ok "name/email correctly written to config"
  else
    fail "name/email missing or wrong in config"
  fi

  # Query the parsed config, not the file text — robust against formatting
  if [[ "$(git config --file "$GIT_DIR/config" --get core.fsmonitor)" == "true" ]]; then
    ok "core.fsmonitor = true (macOS native FS monitoring)"
  else
    fail "core.fsmonitor not enabled"
  fi

  if git config --file "$GIT_DIR/config" --get core.longpaths &>/dev/null; then
    fail "NTFS-only core.longpaths present in config"
  else
    ok "No NTFS-only settings in config"
  fi

  cores_val="$(git config --file "$GIT_DIR/config" --get fetch.parallel || echo "")"
  if [[ "$cores_val" =~ ^[0-9]+$ ]] && (( cores_val >= 1 )); then
    ok "fetch.parallel = $cores_val (numeric, placeholder replaced)"
  else
    fail "fetch.parallel not a valid number: '$cores_val'"
  fi

  # Per-host identities only work if includeIf directives actually exist
  if [[ "$(git config --file "$GIT_DIR/config" --get 'includeif.gitdir:~/Development/code/github/.path')" == *"github/.gitconfig" ]]; then
    ok "includeIf for github identity present"
  else
    fail "includeIf for github identity missing — per-host config never loads"
  fi
  if [[ "$(git config --file "$GIT_DIR/config" --get 'includeif.gitdir:~/Development/code/bitbucket/.path')" == *"bitbucket/.gitconfig" ]]; then
    ok "includeIf for bitbucket identity present"
  else
    fail "includeIf for bitbucket identity missing — per-host config never loads"
  fi

  if grep -q "__GIT_NAME__\|__GIT_EMAIL__\|__CORES__" "$GIT_DIR/config"; then
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
# 6. install → uninstall round-trip (config files only, isolated temp home)
# -----------------------------------------------------------------------------
section "install/uninstall round-trip (isolated temp home)"

RT_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$RT_HOME"' EXIT

# install.sh and uninstall.sh both resolve XDG dirs as "${XDG_DATA_HOME:-$HOME/...}".
# Overriding only HOME is NOT enough: whoever runs the tests almost certainly has
# XDG_DATA_HOME/XDG_CACHE_HOME/XDG_STATE_HOME exported by their own ~/.zshenv, and
# uninstall.sh does `rm -rf "$XDG_DATA_HOME/zinit"` — which wiped the real zinit
# install, eval caches, and interactive-mode toggle. Pin all four to the temp home.
# Stand-ins for the caller's real XDG dirs. They are exported around the
# round-trip so that anything reading the ambient XDG_* vars hits these instead
# of the developer's actual ~/.local/share; the checks below assert they survive.
DECOY_XDG="$(mktemp -d)"
mkdir -p "$DECOY_XDG"/{share/zinit,cache/zsh,state/zsh}
touch "$DECOY_XDG"/share/zinit/sentinel \
      "$DECOY_XDG"/cache/zsh/sentinel \
      "$DECOY_XDG"/state/zsh/sentinel
export XDG_DATA_HOME="$DECOY_XDG/share"
export XDG_CACHE_HOME="$DECOY_XDG/cache"
export XDG_STATE_HOME="$DECOY_XDG/state"
trap 'rm -rf "$TMP_HOME" "$RT_HOME" "$DECOY_XDG"' EXIT

rt_env() {
  env HOME="$RT_HOME" \
      XDG_CONFIG_HOME="$RT_HOME/.config" \
      XDG_CACHE_HOME="$RT_HOME/.cache" \
      XDG_DATA_HOME="$RT_HOME/.local/share" \
      XDG_STATE_HOME="$RT_HOME/.local/state" \
      "$@"
}

# Pre-existing user files that must survive the round-trip
printf '# my original zshenv\n' > "$RT_HOME/.zshenv"
mkdir -p "$RT_HOME/.config/herdr"
printf '# my original herdr config.toml\n' > "$RT_HOME/.config/herdr/config.toml"

# Install (config-only — no packages, no network beyond the local repo copy)
mkdir -p "$RT_HOME/.config"
cp -r "$REPO_DIR" "$RT_HOME/.config/zsh"
if rt_env SHELL=/bin/zsh \
   bash "$RT_HOME/.config/zsh/install.sh" --config-only -y &>/dev/null; then
  ok "install.sh --config-only exited 0"
else
  fail "install.sh --config-only exited non-zero"
fi

check "$HOME/.zshenv written"                grep -q ZDOTDIR "$RT_HOME/.zshenv"
check "original ~/.zshenv backed up"     grep -q "my original zshenv" "$RT_HOME/.zshenv.bak"
check "original herdr config backed up"  grep -q "my original herdr config.toml" "$RT_HOME/.config/herdr/config.toml.bak"
check "herdr config.toml is now a symlink" test -L "$RT_HOME/.config/herdr/config.toml"
check "local.zsh created"                test -f "$RT_HOME/.config/zsh/modules/local.zsh"

# Uninstall
if rt_env bash "$RT_HOME/.config/zsh/uninstall.sh" -y &>/dev/null; then
  ok "uninstall.sh exited 0"
else
  fail "uninstall.sh exited non-zero"
fi

check "outer XDG_DATA_HOME/zinit untouched"   test -e "$DECOY_XDG/share/zinit/sentinel"
check "outer XDG_CACHE_HOME/zsh untouched"    test -e "$DECOY_XDG/cache/zsh/sentinel"
check "outer XDG_STATE_HOME/zsh untouched"    test -e "$DECOY_XDG/state/zsh/sentinel"

check "original ~/.zshenv restored"      grep -q "my original zshenv" "$RT_HOME/.zshenv"
check "original herdr config restored"   grep -q "my original herdr config.toml" "$RT_HOME/.config/herdr/config.toml"
check "config moved to .uninstalled"     test -d "$RT_HOME/.config/zsh.uninstalled"
if [[ -d "$RT_HOME/.config/zsh" ]]; then
  fail "$HOME/.config/zsh still present after uninstall"
else
  ok "$HOME/.config/zsh removed"
fi

# -----------------------------------------------------------------------------
# 7. repo-maintenance.sh
# -----------------------------------------------------------------------------
section "repo-maintenance.sh: argument parsing"

RM="$REPO_DIR/scripts/repo-maintenance.sh"

out=$(capture bash "$RM")
if echo "$out" | grep -q "Usage"; then
  ok "no subcommand prints usage"
else
  fail "no subcommand should print usage"
fi

out=$(capture bash "$RM" bogus)
if echo "$out" | grep -q "Unknown subcommand"; then
  ok "unknown subcommand rejected"
else
  fail "unknown subcommand not rejected"
fi

out=$(capture bash "$RM" branches --bogus-flag)
if echo "$out" | grep -q "Unknown option"; then
  ok "unknown option rejected"
else
  fail "unknown option not rejected"
fi

section "repo-maintenance.sh: repo discovery"

DISCOVER_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$RT_HOME" "$DECOY_XDG" "$DISCOVER_ROOT"' EXIT

mkdir -p "$DISCOVER_ROOT/github/testuser/repo-a/.git"
mkdir -p "$DISCOVER_ROOT/github/testuser/repo-b/.git"
mkdir -p "$DISCOVER_ROOT/github/testuser/repo-b/node_modules/some-dep/.git"

DISCOVER_OUT=$(capture bash "$RM" branches --root "$DISCOVER_ROOT" --dry-run --yes)

if echo "$DISCOVER_OUT" | grep -q "repo-a"; then
  ok "discovers nested repo at depth 4"
else
  fail "did not discover repo-a"
fi

if echo "$DISCOVER_OUT" | grep -q "some-dep"; then
  fail "descended into node_modules (should be pruned)"
else
  ok "node_modules pruned during discovery"
fi

# -----------------------------------------------------------------------------
# 8. repo-maintenance.sh: maintenance phase
# -----------------------------------------------------------------------------
section "repo-maintenance.sh: maintenance phase"

MAINT_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$RT_HOME" "$DECOY_XDG" "$DISCOVER_ROOT" "$MAINT_ROOT"' EXIT

MAINT_REPO="$MAINT_ROOT/github/testuser/maint-repo"
mkdir -p "$MAINT_REPO"
git init -q "$MAINT_REPO"
(
  cd "$MAINT_REPO"
  git config user.email "test@example.com"
  git config user.name "Test User"
  git commit -q --allow-empty -m "init"
)

if bash "$RM" maintenance --root "$MAINT_ROOT" --yes &>/dev/null; then
  ok "maintenance subcommand exits 0"
else
  fail "maintenance subcommand exited non-zero"
fi

DRYRUN_OUT=$(capture bash "$RM" maintenance --root "$MAINT_ROOT" --dry-run)
if echo "$DRYRUN_OUT" | grep -q "(dry-run) git maintenance run --auto"; then
  ok "maintenance --dry-run prints without executing"
else
  fail "maintenance --dry-run did not print expected line"
fi

# -----------------------------------------------------------------------------
# 9. upgrade --dry-run must not touch anything
# -----------------------------------------------------------------------------
section "upgrade --dry-run is side-effect free"

if command -v zsh &>/dev/null; then
  DRY_LOG="$(mktemp)"
  DRY_SCRIPT="$(mktemp)"
  trap 'rm -rf "$TMP_HOME" "$RT_HOME" "$DECOY_XDG" "$DISCOVER_ROOT" "$MAINT_ROOT" "$DRY_LOG" "$DRY_SCRIPT"' EXIT

  # Shadow every external command the upgrade jobs shell out to, so a job that
  # actually runs leaves a trace instead of upgrading the developer's machine.
  cat > "$DRY_SCRIPT" <<ZEOF
source "$REPO_DIR/modules/functions.zsh"
brew()   { print -r -- "brew \$*"   >>"$DRY_LOG" }
mise()   { print -r -- "mise \$*"   >>"$DRY_LOG" }
npm()    { print -r -- "npm \$*"    >>"$DRY_LOG" }
rustup() { print -r -- "rustup \$*" >>"$DRY_LOG" }
claude() { :; }
upgrade --dry-run >/dev/null 2>&1
wait
ZEOF

  zsh "$DRY_SCRIPT" &>/dev/null || true

  if [[ -s "$DRY_LOG" ]]; then
    fail "upgrade --dry-run executed real commands"
    sed 's/^/    /' "$DRY_LOG"
  else
    ok "upgrade --dry-run ran no upgrade commands"
  fi
else
  skip "zsh not found — skipping upgrade --dry-run check"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
printf "\n\033[1m%s passed, %s failed\033[0m\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
