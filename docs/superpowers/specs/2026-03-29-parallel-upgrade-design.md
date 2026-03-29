# Parallel Upgrade Function — Design Spec

**Date:** 2026-03-29
**File:** `modules/functions.zsh` — rewrite of `upgrade()`

## Overview

Rewrite the existing sequential `upgrade()` function to run independent update groups in parallel, with live per-job status display, full logs printed after completion, and a version summary table.

## Architecture

Four phases:

```
1. Setup    — sudo -v (cache credentials), create tmpdir
2. Launch   — start 6 background subshells, record PIDs
3. Display  — foreground polling loop redraws status block until all PIDs exit
4. Teardown — print logs in fixed order, print version summary, rm tmpdir
```

Each background job owns two files in `$tmpdir`:
- `<name>.status` — one word: `running` | `done`
- `<name>.log`    — full stdout+stderr of that job

## Parallel Job Groups

All six groups run concurrently. Internal ordering within each group is preserved:

| Job    | Internal sequence |
|--------|-------------------|
| apt    | `apt update` → `apt-get upgrade -y --autoremove --purge` → `apt-get autoclean` |
| zinit  | `zinit self-update` → `zinit update --all` |
| rust   | `rustup update` → `cargo install-update -a` |
| go     | version check → `g install latest && g use latest` (skipped if already current) |
| node   | `fnm install --lts` → `fnm default lts-latest` → `fnm use lts-latest` → `npm install -g ...` |
| claude | `claude update` |

Each job is only launched if the relevant command exists (`command -v` / `${+functions[...]}` guard).

## Live Status Display

The foreground polling loop redraws a fixed-height status block in-place every 0.5s using ANSI escape codes:
- `\033[<N>A` — move cursor up N lines
- `\033[2K\r` — clear line

Example display while running:

```
  [apt]    running...
  [zinit]  done
  [rust]   running...
  [go]     done
  [node]   running...
  [claude] done
```

Loop exits once all background PIDs have exited (checked via `wait $pid` with WNOHANG or by tracking exit).

## Error Handling

Failures are silently swallowed:
- Each job always writes `done` to its status file, even if commands fail
- Full output (including errors) is captured in the log file
- No job blocks or kills other jobs on failure

`sudo -v` runs in the foreground before any backgrounding to cache credentials for the apt job.

## Teardown

After all PIDs exit:
1. Print logs in fixed order: apt → zinit → rust → go → node → claude
2. Print version summary table (OS, Kernel, Go, Rust, Cargo, Node, npm, Claude, Docker, Git)
3. `rm -rf $tmpdir`

## Out of Scope

- Retry logic for failed jobs
- Configurable job selection (e.g. skip apt)
- Timeout per job
