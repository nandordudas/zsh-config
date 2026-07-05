# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
make test                        # run the full test suite
bash ./scripts/test.sh           # same, without make

bash -n <file>.sh                # syntax-check a bash script
zsh -n <file>.zsh                # syntax-check a zsh module

install.sh --config-only -y      # apply config changes to a test $HOME without touching packages
```

The test suite covers: bash/zsh syntax, required file presence, no personal data leaks, `git-setup.sh` argument parsing, a full install→uninstall round-trip in an isolated temp `$HOME`.

## Architecture

### Startup file chain

```
~/.zshenv          (not in repo — written by install.sh)
  → sets ZDOTDIR=$XDG_CONFIG_HOME/zsh and XDG_* vars
.zprofile          (login shells only)
  → Homebrew, PATH, persistent env vars
.zshrc             (interactive shells)
  → sources modules in strict order: options → zinit → completions →
    keybindings → aliases → functions → tools → local (gitignored)
```

`~/.config/alacritty/alacritty.toml` and `~/.config/herdr/config.toml` are **not** in this repo — they are created/linked by `install.sh`. The alacritty one is a real file (not a symlink) that imports `alacritty/alacritty.toml` from this repo plus `~/.config/alacritty/theme.toml` (the live theme file). The herdr one is a symlink to `herdr/config.toml`.

`herdr` (https://herdr.dev) is the terminal multiplexer used in place of tmux — same prefix-driven model (`Ctrl+a`), plus native agent-state detection for Claude Code and other coding agents. `install.sh` also runs `herdr integration install claude` when both CLIs are present, wiring up a Claude Code hook so herdr can label panes, prioritize the agent panel, and resume sessions after a restart. See `docs/herdr-guide.md`.


### Performance pattern (tools.zsh)

Every external tool that produces init code (starship, zoxide, mise, fzf) is cached via `_ztool_init()`: it runs `<tool> init zsh` once, writes the output to `$XDG_CACHE_HOME/zsh/<tool>.zsh`, and re-generates only when the binary is newer than the cache file. This turns ~65–85 ms of subprocess forks into ~1–2 ms of file sourcing.

Cache files are deleted by `zsh-cache-clear` (defined in `modules/functions.zsh`). Run `exec zsh` after clearing to regenerate.

### Plugin loading (zinit.zsh)

All plugins load in **turbo mode** (`wait` + `lucid`) so the prompt appears before plugins finish loading. Completion init order is critical: `zsh-completions` loads first via `blockf` (registers functions in `$fpath`), then `zicompinit` runs once via `atload`, then `zicdreplay` replays compdef calls from turbo-loaded plugins.

Plugin config vars (`ZSH_AUTOSUGGEST_*`, `ZSH_HIGHLIGHT_*`, etc.) must be set **before** the plugin loads — they are declared at the top of `modules/zinit.zsh`.

### Headless / automation mode

`toggle_interactive off` writes a flag to `$XDG_STATE_HOME/zsh/interactive-mode`. Both `modules/zinit.zsh` and `modules/tools.zsh` check this flag at load time and skip Zinit plugins and Starship respectively — making the shell start as a bare, fast zsh suitable for scripts or CI.

### Key user-facing functions (modules/functions.zsh)

| Function | Purpose |
|----------|---------|
| `upgrade` | Parallel updater: brew, zinit, rust, mise runtimes, npm globals, claude-code |
| `zsh-health` | Diagnostic: platform, tool presence, PATH correctness |
| `zsh-cache-clear` | Deletes `$XDG_CACHE_HOME/zsh/*.zsh` eval caches |
| `freespace` | Cleans `node_modules`/vendor under `$CODE_DIR`; `--aggressive` also clears package manager caches |
| `toggle_interactive` | Enables/disables Zinit + Starship for headless use |
| `extract` | Universal archive extractor (zip, tar, gz, bz2, 7z, rar, …) |

No `tmux`-style wrapper function exists anymore: bare `herdr` already attaches-or-creates the default session, and herdr's own nested-launch guard prevents `herdr`-inside-`herdr`.

### Machine-local files (gitignored)

| Path | Purpose |
|------|---------|
| `modules/local.zsh` | Per-machine zsh overrides, secrets, `ZSH_CONFIG_AUTO_UPDATE=1` opt-in |
| `~/.config/alacritty/alacritty.toml` | Local Alacritty wrapper with imports + per-machine overrides |

`herdr/config.toml` has no per-machine override file — herdr's TOML config has no `source-file`/include directive (unlike tmux), and the file holds no secrets, so machine-specific tweaks go directly into the tracked file.

