# Parallel Upgrade Function Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `upgrade()` in `modules/functions.zsh` to run all independent update groups in parallel, with live per-job status display, full logs printed after completion, and a version summary table.

**Architecture:** Six update groups (apt, zinit, rust, go, node, claude) each run as background subshells writing status and log files to a tmpdir. A foreground polling loop redraws a fixed-height status block every 0.5s using ANSI escape codes. After all PIDs exit, logs are printed in fixed order followed by the version summary.

**Tech Stack:** zsh, ANSI escape codes, background subshells (`&`), `mktemp`, `wait`

---

### Task 1: Create feature branch

**Files:**
- No file changes — git operation only

- [ ] **Step 1: Create and switch to feature branch**

```bash
git checkout -b feat/parallel-upgrade
```

Expected output:
```
Switched to a new branch 'feat/parallel-upgrade'
```

---

### Task 2: Replace upgrade() with parallel implementation

**Files:**
- Modify: `modules/functions.zsh:83-166` (full `upgrade()` function replacement)

- [ ] **Step 1: Replace the entire upgrade() function**

In `modules/functions.zsh`, replace everything from line 83 (`# Comprehensive system upgrade function`) through line 166 (closing `}`) with:

```zsh
# Comprehensive system upgrade function — parallel execution
upgrade() {
  local tmpdir
  tmpdir=$(mktemp -d)

  # Cache sudo credentials before backgrounding — apt job needs them
  sudo -v || { rm -rf "$tmpdir"; return 1; }

  # Track which jobs were launched (in display order)
  local -a names=()
  local -a pids=()

  # --- apt ---
  {
    printf 'running' > "$tmpdir/apt.status"
    sudo apt update \
      && sudo apt-get upgrade -y --autoremove --purge \
      && sudo apt-get autoclean
    printf 'done' > "$tmpdir/apt.status"
  } > "$tmpdir/apt.log" 2>&1 &
  pids+=($!)
  names+=(apt)

  # --- zinit ---
  if (( ${+functions[zinit]} )); then
    {
      printf 'running' > "$tmpdir/zinit.status"
      zinit self-update --quiet
      zinit update --all --quiet
      printf 'done' > "$tmpdir/zinit.status"
    } > "$tmpdir/zinit.log" 2>&1 &
    pids+=($!)
    names+=(zinit)
  fi

  # --- rust (rustup must precede cargo) ---
  if command -v rustup &>/dev/null || command -v cargo &>/dev/null; then
    {
      printf 'running' > "$tmpdir/rust.status"
      command -v rustup &>/dev/null && rustup update
      command -v cargo  &>/dev/null && cargo install-update -a
      printf 'done' > "$tmpdir/rust.status"
    } > "$tmpdir/rust.log" 2>&1 &
    pids+=($!)
    names+=(rust)
  fi

  # --- go ---
  if command -v "$HOME/go/bin/g" &>/dev/null; then
    {
      printf 'running' > "$tmpdir/go.status"
      local LOCAL_GO REMOTE_GO
      LOCAL_GO=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
      REMOTE_GO=$(curl -sf 'https://go.dev/VERSION?m=text' 2>/dev/null | head -1 | sed 's/go//')
      if [[ -n "$REMOTE_GO" && "$LOCAL_GO" != "$REMOTE_GO" ]]; then
        "$HOME/go/bin/g" install latest && "$HOME/go/bin/g" use latest
      fi
      printf 'done' > "$tmpdir/go.status"
    } > "$tmpdir/go.log" 2>&1 &
    pids+=($!)
    names+=(go)
  fi

  # --- node (fnm must precede npm) ---
  if command -v fnm &>/dev/null; then
    {
      printf 'running' > "$tmpdir/node.status"
      fnm install --lts && fnm default lts-latest && fnm use lts-latest
      npm install --global npm@latest pnpm@latest @antfu/ni eslint taze npkill
      printf 'done' > "$tmpdir/node.status"
    } > "$tmpdir/node.log" 2>&1 &
    pids+=($!)
    names+=(node)
  fi

  # --- claude ---
  if command -v claude &>/dev/null; then
    {
      printf 'running' > "$tmpdir/claude.status"
      claude update
      printf 'done' > "$tmpdir/claude.status"
    } > "$tmpdir/claude.log" 2>&1 &
    pids+=($!)
    names+=(claude)
  fi

  # --- Display loop ---
  local n=${#names[@]}

  # Print initial status block
  for name in $names; do
    printf '  [%-8s] running...\n' "$name"
  done

  # Poll status files; redraw block in-place until all jobs report done
  local all_done=0
  while (( ! all_done )); do
    sleep 0.5
    # Move cursor up n lines
    printf '\033[%dA' "$n"
    all_done=1
    for name in $names; do
      local s
      s=$(cat "$tmpdir/${name}.status" 2>/dev/null)
      if [[ "$s" == 'done' ]]; then
        printf '\033[2K\r  [%-8s] done\n' "$name"
      else
        printf '\033[2K\r  [%-8s] running...\n' "$name"
        all_done=0
      fi
    done
  done

  # Reap background jobs
  for pid in $pids; do
    wait "$pid" 2>/dev/null
  done

  printf '\n'

  # --- Print logs in fixed order ---
  for name in apt zinit rust go node claude; do
    [[ -f "$tmpdir/${name}.log" ]] || continue
    local log
    log=$(cat "$tmpdir/${name}.log")
    [[ -n "$log" ]] && printf '=== %s ===\n%s\n\n' "$name" "$log"
  done

  # --- Version summary ---
  printf '📋 Installed versions:\n'
  printf '  %-12s %s\n' 'OS:'     "$(lsb_release -ds 2>/dev/null)"
  printf '  %-12s %s\n' 'Kernel:' "$(uname -r)"
  printf '  %-12s %s\n' 'Go:'     "$(go version 2>/dev/null | awk '{print $3}' || echo 'not found')"
  printf '  %-12s %s\n' 'Rust:'   "$(rustc --version 2>/dev/null | awk '{print $2}' || echo 'not found')"
  printf '  %-12s %s\n' 'Cargo:'  "$(cargo --version 2>/dev/null | awk '{print $2}' || echo 'not found')"
  printf '  %-12s %s\n' 'Node:'   "$(node --version 2>/dev/null || echo 'not found')"
  printf '  %-12s %s\n' 'npm:'    "$(npm --version 2>/dev/null || echo 'not found')"
  printf '  %-12s %s\n' 'Claude:' "$(claude --version 2>/dev/null || echo 'not found')"
  printf '  %-12s %s\n' 'Docker:' "$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo 'not found')"
  printf '  %-12s %s\n' 'Git:'    "$(git --version 2>/dev/null | awk '{print $3}' || echo 'not found')"

  rm -rf "$tmpdir"
  printf '🎉 All done!\n'
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/functions.zsh
git commit -m "feat: rewrite upgrade() with parallel job execution"
```

---

### Task 3: Smoke test the display loop in isolation

**Files:**
- No file changes — verification only

Before running the full upgrade (which touches system packages), verify the display loop works correctly with a harmless mock.

- [ ] **Step 1: Source the config and run a mock parallel test**

In your terminal:

```zsh
source ~/.config/zsh/modules/functions.zsh

# Mock: two background jobs that sleep then write done
tmpdir=$(mktemp -d)
names=(job1 job2)
pids=()

{ printf 'running' > "$tmpdir/job1.status"; sleep 1; printf 'done' > "$tmpdir/job1.status"; } &
pids+=($!)
{ printf 'running' > "$tmpdir/job2.status"; sleep 2; printf 'done' > "$tmpdir/job2.status"; } &
pids+=($!)

n=2
for name in $names; do printf '  [%-8s] running...\n' "$name"; done

all_done=0
while (( ! all_done )); do
  sleep 0.5
  printf '\033[%dA' "$n"
  all_done=1
  for name in $names; do
    s=$(cat "$tmpdir/${name}.status" 2>/dev/null)
    if [[ "$s" == 'done' ]]; then
      printf '\033[2K\r  [%-8s] done\n' "$name"
    else
      printf '\033[2K\r  [%-8s] running...\n' "$name"
      all_done=0
    fi
  done
done

for pid in $pids; do wait "$pid" 2>/dev/null; done
rm -rf "$tmpdir"
```

Expected: `[job1]` updates to `done` after ~1s while `[job2]` still shows `running...`, then `[job2]` updates to `done` after ~2s. Both lines update in-place without scrolling.

---

### Task 4: Commit the plan doc and push the branch

**Files:**
- No function changes — git operations only

- [ ] **Step 1: Commit the plan document**

```bash
git add docs/superpowers/plans/2026-03-29-parallel-upgrade.md
git commit -m "docs: add parallel upgrade implementation plan"
```

- [ ] **Step 2: Push the branch**

```bash
git push -u origin feat/parallel-upgrade
```

Expected:
```
Branch 'feat/parallel-upgrade' set up to track remote branch 'feat/parallel-upgrade' from 'origin'.
```
