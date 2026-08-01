# repo-maintenance.sh — design spec

## Purpose

A standalone script (`scripts/repo-maintenance.sh`) that, across every git repo under a
root directory (default `$CODE_DIR`), safely removes local branches whose remote copy is
gone, runs `git maintenance` where warranted, cleans per-project build artifacts/caches
with each tool's own clean command, and reports (with optional interactive delete) the
size of global tool caches.

Separate from the existing `freespace` function in `modules/functions.zsh` — that
function targets `$CODE_DIR` broadly for `node_modules`/`vendor` only and has no git
awareness; this script is git-repo-scoped and covers a superset of artifact types plus
branch/maintenance concerns freespace never touched. No changes to `freespace`.

## CLI

```
scripts/repo-maintenance.sh <branches|maintenance|clean|caches|all> [--root PATH] [--dry-run] [--yes]
```

- `--root PATH` — override the scan root. Default: `${CODE_DIR:-$HOME/Development/code}`
  (same fallback used in `.zprofile:88` and `functions.zsh:580`).
- `--dry-run` — no mutation anywhere (no `git branch -D`, no `rm -rf`, no `cargo clean`
  etc., no cache deletion). Prints what would happen.
- `--yes` — skip all confirm prompts (branch deletion list, per-cache delete prompts).
  For non-interactive/cron use.
- Subcommand `all` runs `maintenance` → `branches` → `clean` → `caches`, each as a
  separate full pass across all repos (not interleaved per-repo) — see Phase Order below.

## Repo discovery

```
find "$root" -maxdepth 3 -type d -name .git
```

Depth 3 covers `$CODE_DIR/<repo>`, `$CODE_DIR/github/<user>/<repo>`,
`$CODE_DIR/bitbucket/<user>/<repo>` — matches the `gg`/`gb` alias layout in
`modules/aliases.zsh`. Prune `node_modules` and `vendor` while walking so the scan
doesn't descend into dependency trees.

## Phase: `branches`

Per repo:

1. `git fetch --all --prune` — this is what marks a local branch's upstream `[gone]`.
2. `git branch -vv | awk '/: gone]/ {print $1}'`, skipping the current branch (never
   delete a checked-out branch) — a local branch qualifies only if its remote tracking
   ref has vanished, which in practice means the remote deleted it (PR merged, branch
   auto-deleted on GitHub/GitLab).
3. For each candidate: print `deleted <branch> at <sha>` (the branch's current tip SHA)
   before deleting, so there's a permanent recovery note even after git's reflog expires
   (default `gc.reflogExpire` ~90 days). Recovery: `git branch <name> <sha>`, as long as
   the SHA stays reachable (it usually is — it's what got merged into the target
   branch).
4. Confirm the full candidate list once per repo (unless `--yes`), then `git branch -D`
   each approved branch.

This never touches remote branches or tags — only removes local refs the remote side
already deleted, so it's non-destructive to shared history.

## Phase: `maintenance`

Per repo: `git maintenance run --auto`. Native Git (2.30+) command — internally checks
its own thresholds (loose object count, pack fragmentation, commit-graph staleness,
etc.) and only performs work when warranted. No custom heuristic needed. Runs before
`branches` in the `all` sequence.

## Phase: `clean`

Per repo, native tool command when the project's manifest is present; `rm -rf` fallback
only for the two ecosystems with no clean verb of their own:

| Detected by | Action |
|---|---|
| `Cargo.toml` | `cargo clean` |
| `pubspec.yaml` | `flutter clean` |
| `go.mod` | `go clean -cache` |
| `node_modules/` present | `rm -rf node_modules` |
| `vendor/` present | `rm -rf vendor` |

Report `du -sk` size freed per repo/artifact, same style as the existing `freespace`
output (`modules/functions.zsh:586`).

## Phase: `caches`

Report-only by default, but prompts per-cache to delete (unless `--dry-run`; auto-yes
under `--yes`). Sizes and paths are **queried from each tool**, not hardcoded, so this
adapts to whatever the user's actual config/install method points at:

| Cache | Path source |
|---|---|
| pnpm store | `pnpm store path` (skip if `pnpm` not on PATH) |
| Go build cache | `go env GOCACHE` |
| Go module cache | `go env GOMODCACHE` |
| Cargo registry | `$CARGO_HOME/registry` (`CARGO_HOME` set by `~/.cargo/env`, sourced in `.zprofile:95`) |
| Flutter/Dart pub cache | `$PUB_CACHE` env var if set, else `~/.pub-cache` |
| Homebrew | `brew --cache` |
| npm | `npm config get cache` |

Each entry: `du -sh` size, listed largest-first, then a y/n prompt to delete
immediately (script deletes on yes — no separate copy-paste step required).

## Output / logging

Stdout only. No persistent log file — user can redirect (`>> file`) if a record is
wanted. Matches existing scripts' style (no logging infra elsewhere in this repo).

## Style / conventions

Bash (`#!/usr/bin/env bash`, `set -euo pipefail`), `--flag value` parsing, `printf`
messaging — matches `scripts/git-setup.sh` and the `freespace` function's own
conventions. Covered by the existing test suite's "bash syntax" check
(`bash -n scripts/repo-maintenance.sh`); no new test-suite requirements beyond that.

## Out of scope

- No changes to `modules/functions.zsh` / `freespace`.
- No scheduling/cron wiring (script is invoked manually or wired up by the user
  separately if desired).
- No handling of repos with uncommitted changes beyond git's own refusal (`git branch
  -D` on the current branch is already blocked by the "skip current branch" rule above;
  no additional dirty-worktree check is added since `cargo clean`/`flutter clean`/`go
  clean -cache` only touch build artifacts, not tracked source).
