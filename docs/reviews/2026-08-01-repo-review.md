# Repo review — 2026-08-01

Full read of every tracked file, plus execution-based verification of the shell
startup chain, `install.sh`/`uninstall.sh`, `scripts/test.sh` and the `upgrade`
function. Branch: `fix/repo-review-2026-08-01`.

Baseline before changes: `70 passed, 0 failed`; interactive startup 85 ms
(README targets <100 ms). After changes: `75 passed, 0 failed`; startup 90 ms.

---

## Incident: the test suite deleted real state

Found while verifying the fixes, and it fired for real on this machine.

`scripts/test.sh` ran the install/uninstall round-trip with only `HOME` and
`XDG_CONFIG_HOME` pointed at a temp directory. But `uninstall.sh:32-34` resolves
the rest as `"${XDG_DATA_HOME:-$HOME/.local/share}"`, and every developer running
the suite already has `XDG_DATA_HOME` exported by their own `~/.zshenv`. The
parameter expansion therefore kept the **real** path, and `uninstall.sh:114`:

```bash
rm -rf "$XDG_CACHE_HOME/zsh" "$XDG_DATA_HOME/zinit" "$XDG_STATE_HOME/zsh"
```

deleted the actual `~/.cache/zsh`, `~/.local/share/zinit` and
`~/.local/state/zsh` — not the temp home's. Every `make test` since this landed
has been silently wiping the developer's zinit install.

Damage was recoverable: zinit re-cloned itself and the four eval caches
regenerated on the next interactive shell. `~/.local/state/zsh/interactive-mode`
had to be recreated by hand (`tools.zsh:42` defaults to `on` when the file is
unreadable, so nothing misbehaved in the interim).

Fixed by pinning all four XDG vars to the temp home via an `rt_env` helper, and
guarded by three new assertions that point the ambient XDG vars at a decoy tree
with sentinel files and require the sentinels to survive the round-trip.

---

## Fixed on this branch

### 1. `upgrade --dry-run` performed the upgrade

`modules/functions.zsh` launched every job at what was line 274 and only checked
`dry_run` at line 282. Reproduced with the externals shadowed:

```
BREW RAN: update --quiet
BREW RAN: upgrade
BREW RAN: cleanup --prune=7
RUSTUP RAN: update
MISE RAN: upgrade --yes
BREW RAN: upgrade --cask claude-code@latest
```

`_launch_job` now registers the tool name (so `--dry-run` can still list it) and
returns before forking when `dry_run` is set.

### 2. `install.sh` never installed the npm globals

`npm install --global "$(xargs < ~/.default-npm-packages)"` — the quotes made all
six packages a single argument. Now read line-by-line into an array.

### 3. Two concurrent `brew` processes

The `brew` and `claude` jobs both shelled out to `brew`, which takes a global
lock. Added `_brew_lock`, an `mkdir`-based mutex that every brew invocation goes
through. `--only claude` still works, which `docs/functions.md:119` documents.

`"$@" || rc=$?` inside the lock keeps `errexit` (set in the job subshell) from
skipping the `rmdir`, and a bounded wait means a stale lock can't hang forever.

### 4. Debug echoes in `.zshrc`

`echo "2. Sourcing .zshrc"` / `"...done"` printed on every interactive shell.
The "2." referenced a numbering scheme whose 1 and 3 no longer exist. Removed.

### 5. Machine-local config committed to the repo

`.zshrc` and `acme/.zshrc` both carried Headroom-managed blocks with a hardcoded
`/Users/nandordudas/Library/Application Support/...` path and
`ANTHROPIC_BASE_URL=http://127.0.0.1:6767`. Moved to the gitignored
`modules/local.zsh`, using `$HOME` instead of a literal path.

**Caveat:** Headroom owns those `# >>> headroom:... >>>` markers and may
re-inject them into `.zshrc` on its next update. If that happens, move them back
to `local.zsh` — or point Headroom at `local.zsh` if it supports a target
override.

The old "no personal data" check only grepped one gmail address, so it never saw
this. Added a `git grep` for `/Users/[a-z]` across tracked config.

### 6. `repo-maintenance.sh` advertised four unimplemented subcommands

`branches`, `clean`, `caches` and `all` all resolved to `list_repos_only`, which
printed repo paths and exited 0 — indistinguishable from a completed run, and a
trap for anything scheduled. `all` didn't even call `phase_maintenance`.

They now still list what they would visit, then print "not implemented" and
return 2. The usage text separates implemented from unimplemented, and the
`--root` default renders instead of printing a literal `${CODE_DIR:-...}` (the
heredoc was quoted).

### 7. `ZSH_CONFIG_AUTO_UPDATE` documented in three places, implemented in none

`install.sh`, `README.md` and `CLAUDE.md` all described an opt-in auto-pull with
example output. No code anywhere referenced the variable. Removed all three
mentions rather than shipping the feature — reinstate them alongside an
implementation if it's still wanted.

### 8. Stale `uninstall.sh` header

Claimed it stopped a `dark-notify` process and removed `theme.toml`. Neither has
existed since the alacritty theme-import removal (`6011a85`). Removed.

### Incidental (same functions, fixed while there)

- The `INT`/`TERM` trap ran `kill -- -$_pid`, but `unsetopt MONITOR` keeps
  background jobs in the shell's own process group, so no such process group
  existed and Ctrl-C killed nothing. Now `pkill -P "$_pid"` then `kill "$_pid"`.
- `--dry-run` and "nothing to upgrade" returned before the `unfunction` at the
  end, leaking `_upgrade_*`, `_job_start`, `_job_end`, `_launch_job` into the
  global namespace. Consolidated into `_upgrade_cleanup`, called on every path.
- `.zshrc` left `_zconfig_root` set in every shell. Now unset at the end;
  `modules/aliases.zsh:126` bakes the value in at alias-definition time, so the
  `sysinfo` alias still resolves (verified).

### Test coverage added

Each new assertion was verified to fail when its defect is reintroduced:

| Assertion | Guards |
|---|---|
| `upgrade --dry-run ran no upgrade commands` | fix 1 |
| `No hardcoded home paths in tracked config` | fix 5 |
| `outer XDG_{DATA,CACHE,STATE}_HOME untouched` | the incident above |

---

## Not fixed — still open

Ordered by how much they can bite.

### Git config (`scripts/git-setup.sh`)

| Line | Setting | Problem |
|---|---|---|
| 173 | `core.sparseCheckout = true` | Set **globally**, marking every repo sparse-aware with no sparse-checkout file. Belongs in per-repo `git sparse-checkout init`. |
| 260 | `merge.ff = only` | Any non-fast-forwardable `git merge` hard-fails. Inconsistent with `pull.rebase = merges` on line 196. `ff = false` is the likely intent. |
| 180 | `help.autoCorrect = 10` | Auto-*executes* the guessed command after 1 s. `autoCorrect = prompt` is the safe equivalent. |
| 307 | `commit.cleanup = scissors` | `#`-prefixed lines are **kept** in commit messages rather than stripped. Fine if deliberate, surprising otherwise. |
| 303 | `[diff "exif"] textconv = exiftool` | `exiftool` is in neither Brewfile, so this silently does nothing. |

`git-setup.sh` also rewrites `$GIT_DIR/config` wholesale on every run, discarding
hand edits. Documented, but worth a confirmation prompt or `--force` gate.

### `acme/`

A tracked, undocumented second startup chain: 5 files, a stub `acme/bin/acme`
that only runs `echo "acme"`, and 23 MB of gitignored zinit plugins living inside
the repo tree (which is why `cp -r` in the round-trip is slow and noisy). The only
reference anywhere is `docs/superpowers/plans/2026-07-10-chezmoi-zsh-rebuild.md`;
neither README nor CLAUDE.md mentions it, and `test.sh` never syntax-checks it.

Worse, `acme/.zlogin` defines a second `update()` duplicating `upgrade` and runs
bare `set -e` in the caller's interactive shell — after calling it, the next
failing command closes the terminal. `upgrade` gets this right by confining
`set -e` to a subshell.

Recommendation: delete `acme/`, or move it out of the repo. If it stays, document
it and add it to the syntax loop.

### Robustness

- `modules/functions.zsh` `zsh-cache-clear` hardcodes four filenames while
  `CLAUDE.md` claims it clears `$XDG_CACHE_HOME/zsh/*.zsh`. Add a tool to
  `tools.zsh` and its cache becomes unclearable. Use the glob.
- `_freespace_run`'s body is parsed while the `rm='rm -i'` alias is live, so it
  really runs `rm -i -rf`. Verified. `-f` wins today; it's accidental. Use
  `command rm -rf` to match the neighbouring `command find`.
- `shift 2` on a valueless flag (`install.sh` `--git-name`, `upgrade --only`)
  errors under `set -u`. Guard with `[[ $# -ge 2 ]]`.
- `install.sh` bakes an absolute path into the generated alacritty wrapper, so
  moving the repo breaks it until the installer is re-run.

### Tests / CI

- `test.sh` copies the repo with `cp -r`, pulling in `.git` and `acme/.local`
  (23 MB) and emitting ten `cp: ... is a socket (not copied)` warnings. Use
  `git archive HEAD | tar -x -C`.
- The `check "$HOME/.config/git/..."` descriptions interpolate `$HOME` at
  runtime, so passing output reads `✓ /Users/nandordudas/.config/git/config
  created` when the assertion actually checked the temp home. Single-quote them.
- The zsh syntax loop skips `acme/*` entirely.
- Six successive `trap ... EXIT` overwrites, each re-listing all prior temp dirs.
  One array plus one trap is less error-prone — and adding a directory without
  updating all later traps is exactly how a leak gets in.
- `.github/workflows/test.yml` names a job `syntax-linux` that runs the whole
  suite, not just syntax.

### Docs / hygiene

- `README.md` devotes 423 of its ~920 lines to a VS Code `settings.json` dump.
  Move to `docs/vscode.md`.
- `.gitignore` ignores all of `.claude/`, so a shareable `.claude/settings.json`
  can never be committed. Narrow to `.claude/settings.local.json` and
  `.claude/projects/`.

---

## Verified working, no change needed

- Startup chain and ordering, ~90 ms interactive, silent.
- `_ztool_init` cache invalidation via binary mtime, and the temp-file write that
  prevents a truncated cache from being sourced forever.
- `alias dc-up='UID=$(id -u) GID=$(id -g) docker compose up'` — zsh's `UID` is a
  special parameter, but a command-prefix assignment of the *current* uid is a
  no-op that still exports to the child. Confirmed by test.
- `install.sh`/`uninstall.sh` backup and restore round-trip, including the
  "leave it alone if it isn't our symlink" guards.
- `sed -i.bak` in `git-setup.sh` is BSD-correct.
