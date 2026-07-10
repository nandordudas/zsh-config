# Chezmoi-managed zsh rebuild — design

## Goal

Rebuild the zsh config from scratch under chezmoi, so it's reproducible on any
new Mac with one command, while keeping the current `~/.config/zsh` setup
fully working and untouched throughout the build.

## Why chezmoi

- Single static binary, git-backed source, templating available if we ever
  need per-machine differences (not required today — macOS only).
- Alternatives considered: GNU Stow (no templating, more manual), yadm (less
  common, thinner docs). Chezmoi wins on templating headroom without adding
  complexity now.

## Reference source

`acme/.zprofile`, `acme/.zshrc`, `acme/.zlogin`, `acme/.zlogout` in this repo
are the active, leaner variant of the dotfile chain (vs. the older root-level
`.zprofile`/`.zshrc`). They are the templates for the new build. Old
root-level dotfiles, `install.sh`, `uninstall.sh`, and `docs/` are left in
place, untouched — no deletions as part of this work.

## Build location: sandbox first, cutover later

Chezmoi source lives at its default `~/.local/share/chezmoi` (its own git
repo, independent of this one). It targets a **new, separate directory**,
`~/.config/zsh-acme`, not the current live `~/.config/zsh`. This avoids two
tools (this git repo + chezmoi apply) writing into the same directory during
the build.

Cutover (repointing `ZDOTDIR` at `~/.config/zsh-acme`, retiring the old
setup) is an explicit, separate decision made later, once the sandboxed
build is proven — not part of this design.

## Layout

```
~/.local/share/chezmoi/
  dot_zshenv                          → ~/.zshenv (sets ZDOTDIR=~/.config/zsh-acme)
  private_dot_config/
    zsh-acme/
      dot_zprofile   (from acme/.zprofile)
      dot_zshrc      (from acme/.zshrc)
      dot_zlogin     (from acme/.zlogin)
      dot_zlogout    (from acme/.zlogout)
```

`modules/*.zsh` (options, zinit, completions, keybindings, aliases,
functions, tools) are **not** migrated up front. They're added one at a time
in later steps, each tested before moving to the next — per "add these
things step by step."

## Testing each step

No step touches the real interactive shell. After each `chezmoi apply`,
verify with a throwaway shell:

```bash
ZDOTDIR=~/.config/zsh-acme zsh -i
```

## GitHub repo

The chezmoi source becomes its own new public GitHub repo, `dotfiles`,
independent of this zsh repo. Chezmoi's default model — source repo separate
from target files.

## App configs folded in (added step by step, not all at once)

- `~/.config/alacritty/alacritty.toml` — as-is, no personal data.
- `~/.config/herdr/config.toml` only — **not** the sibling runtime files in
  that directory (`sessions/`, `*.log`, `*.sock`, `session*.json`), which are
  local state, not config.
- `~/.config/git/config` — templated (`.tmpl`), since it hardcodes email and
  local absolute paths. Real values come from a local, gitignored chezmoi
  data file (`~/.local/share/chezmoi/.chezmoidata.yaml` or `chezmoi init`
  prompts), keeping the public repo free of personal data — matching this
  repo's existing "no personal data leaks" convention.

## Non-goals (for this spec)

- Deleting or migrating old root-level files, `install.sh`, `uninstall.sh`.
- Deciding the final cutover mechanism.
- Multi-machine/OS templating beyond what's needed to de-personalize git config.
- Migrating anything beyond zsh dotfiles + alacritty + herdr + git config in
  this first pass.
