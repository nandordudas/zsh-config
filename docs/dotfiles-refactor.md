# dotfiles refactor — planning doc

Status: exploring, no code changes yet. Living doc — edit freely as decisions change.

## Goal

Expand from a zsh-only repo into one repo that owns all of `~/.config/*`,
while keeping the properties that already work today:

- **Idempotent** — running install twice produces the same state.
- **Deterministic** — same inputs (repo + flags) always produce the same output.
- **Testable** — every behavior above has a test in `scripts/test.sh`, run
  against an isolated temp `$HOME`, never the real one.
- **Single-file toggle** — removing one file from `$HOME` fully deactivates
  the config (repo and all other files untouched); restoring that file fully
  reactivates it.

## Current state (baseline, already working)

- Repo lives at `~/.config/zsh`, activated via `ZDOTDIR` set in `~/.zshenv`
  (the *only* file install.sh writes into `$HOME` — there is no `~/.zprofile`
  or similar; `.zprofile` lives inside the repo and is only reached through
  `ZDOTDIR`).
- `install.sh` also directly manages two other apps' configs:
  - `herdr/config.toml` → real symlink into the repo.
  - `alacritty/alacritty.toml` → real *file* (not symlink) that `import`s the
    repo's base config, so machine-local overrides can follow the import.
- Everything else under `~/.config/` (btop, git, gh, mise, colima, iterm2,
  swiftpm, zed, starship.toml, tool_state, settings, ...) is untracked.
- `uninstall.sh` restores `~/.zshenv` (or removes it), un-symlinks herdr,
  restores/removes the alacritty wrapper, and moves the repo to
  `~/.config/zsh.uninstalled` (kept, not deleted).
- `scripts/test.sh` covers: syntax checks, personal-data leak checks,
  `git-setup.sh` arg parsing, a full install→uninstall round trip in a temp
  `$HOME` (via `uninstall.sh`, not the minimal single-file toggle).

## Gap found

The single-file-toggle property already *holds by construction* (delete
`~/.zshenv` → stock zsh, repo untouched → recreate → fully restored) but is
**not tested**. The existing round-trip test exercises the heavier
`uninstall.sh` path (moves the repo, clears caches, touches herdr/alacritty),
not this minimal scenario in isolation.

- [ ] Add a test case: delete `~/.zshenv` only → assert no `ZDOTDIR`
      leak into a fresh shell, repo directory and all its files still present
      byte-for-byte → recreate `~/.zshenv` (or re-run
      `install.sh --config-only -y`) → assert deterministic output.

## Target structure (draft — under discussion)

```
~/dotfiles/                      # renamed from zsh-config; "dotfiles" matches
                                 # community convention (~/dotfiles, ~/.dotfiles)
├── zsh/       .config/zsh/...
├── git/       .config/git/...
├── alacritty/ .config/alacritty/alacritty.toml
├── herdr/     .config/herdr/config.toml
├── tmux/      .config/tmux/...
├── mise/      .config/mise/config.toml
├── starship.toml  (own package or under a small "misc" package)
├── install.sh
├── uninstall.sh
├── Brewfile / Brewfile.dev
├── scripts/
└── docs/
```

**Excluded from the repo entirely** (secrets or app-managed runtime state,
not hand-edited config):

- `gh/` — `config.yml` / `hosts.yml` are mode `600`, contain the GitHub auth
  token.
- `colima/` — mostly live VM runtime state (`docker.sock`, `_store`,
  `default/`), not hand-edited config.
- `swiftpm/`, `iterm2/` — already just symlinks the apps themselves generate
  into `~/Library/...`; nothing to track.

**Not yet triaged** (config vs. runtime state mixed in, check individually):
`homebrew/`, `intelephense/`, `linearmouse/`, `ccstatusline/`, `tool_state`,
`settings`.

## Open decisions

1. **Linking mechanism** — leaning toward GNU Stow (community standard,
   symlink-farm-per-package model) over generalizing the current hand-rolled
   `ln -sf` blocks in `install.sh`, but not committed yet. Curious to explore
   further before deciding — not convinced yet either way.
2. **Repo name/location** — leaning `~/dotfiles`, replacing `zsh-config`.
   Cost: repo URL, clone instructions, docs, `CLAUDE.md` all currently say
   `zsh-config`.
3. **Migration path for existing machine** — first `stow` run can't proceed
   while real files already occupy the target paths (`alacritty.toml`,
   `git/config`, `mise/config.toml`, `zed/settings.json`, `starship.toml`,
   `tool_state`, and `~/.config/zsh` itself, which is currently the repo root
   and not a symlink target). Needs a scripted backup-then-remove step before
   the first `stow */`, and a way to verify nothing was lost (diff against
   backups).

## Next steps

- [ ] Decide on Stow vs. generalized `install.sh` linking (try both against
      `--config-only` in a temp `$HOME`, compare complexity/test coverage).
- [ ] Triage the "not yet triaged" apps above.
- [ ] Write the migration script for the existing machine (backup real files
      → move repo → link → verify).
- [ ] Add the missing single-file-toggle test.
- [ ] Decide repo rename timing (before or after the Stow decision).
