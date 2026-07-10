# Chezmoi zsh Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a chezmoi-managed dotfiles source (pushed to a new public GitHub repo `dotfiles`) that reproduces the zsh startup chain from `acme/`, plus alacritty/herdr/git configs, entirely in a sandbox directory that never touches the live `~/.config/zsh` setup.

**Architecture:** Chezmoi source lives at `~/.local/share/chezmoi` (its own git repo). It manages a sandbox target `~/.config/zsh-acme` for the zsh chain, plus `~/.config/alacritty`, `~/.config/herdr` (config file only), and a templated `~/.config/git/config`. Every `chezmoi apply` in this plan is scoped to a specific target path — never a bare `chezmoi apply` — so `~/.zshenv` (which zsh always reads regardless of `$ZDOTDIR`) is never touched, keeping the live setup untouched throughout.

**Tech Stack:** chezmoi, zsh, git, GitHub (`gh` CLI)

## Global Constraints

- No deletion or modification of any file in the existing `~/.config/zsh` repo.
- No file in the new public `dotfiles` repo may contain personal data (email, real absolute home paths) — templated instead, per this repo's own "no personal data leaks" convention.
- Every verification step uses a throwaway shell (`ZDOTDIR=~/.config/zsh-acme zsh -i`) or `chezmoi diff`/`--dry-run` — never applied against the real interactive session.
- `chezmoi apply` commands are always scoped to one target path, never run bare.

---

### Task 1: Install chezmoi and initialize an empty source repo

**Files:**
- Create: `~/.local/share/chezmoi/` (chezmoi source dir, its own git repo)

**Interfaces:**
- Produces: a working `chezmoi` binary on `$PATH`, an initialized git repo at `~/.local/share/chezmoi` with no files yet.

- [ ] **Step 1: Install chezmoi via Homebrew**

```bash
brew install chezmoi
```

- [ ] **Step 2: Verify install**

Run: `chezmoi --version`
Expected: prints a version string (e.g. `chezmoi version v2.x.x`)

- [ ] **Step 3: Initialize the source directory**

```bash
chezmoi init
```

Expected: creates `~/.local/share/chezmoi` and runs `git init` inside it.

- [ ] **Step 4: Verify the source repo**

Run: `git -C ~/.local/share/chezmoi status`
Expected: `On branch main` (or `master`), no commits yet, working tree clean (empty).

- [ ] **Step 5: Commit the empty repo baseline**

```bash
git -C ~/.local/share/chezmoi commit --allow-empty -m "chore: initialize chezmoi source"
```

---

### Task 2: Add sandbox `.zprofile`

**Files:**
- Create: `~/.local/share/chezmoi/private_dot_config/zsh-acme/dot_zprofile`

**Interfaces:**
- Consumes: nothing (first file in the sandbox chain).
- Produces: `~/.config/zsh-acme/.zprofile`, setting up `HISTFILE`, `PATH`, `Homebrew` env, matching `acme/.zprofile`'s structure but scoped to `zsh-acme` data/cache dirs so it never collides with the live setup's history/cache files.

- [ ] **Step 1: Write the source file**

```bash
mkdir -p ~/.local/share/chezmoi/private_dot_config/zsh-acme
cat > ~/.local/share/chezmoi/private_dot_config/zsh-acme/dot_zprofile <<'EOF'
[[ -o interactive ]] || return

[[ -d "$XDG_DATA_HOME/zsh-acme" ]] || mkdir -p "$XDG_DATA_HOME/zsh-acme"
[[ -d "$XDG_CACHE_HOME/zsh-acme/compcache" ]] || mkdir -p "$XDG_CACHE_HOME/zsh-acme/compcache"

export HISTFILE="${XDG_DATA_HOME}/zsh-acme/history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE="${XDG_CACHE_HOME}/lesshst"

if [[ -z "$HOMEBREW_PREFIX" ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$_brew" ]]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi

typeset -U PATH path
path=(
  "$HOME/.local/bin"
  $path
)
export PATH

export LANG="${LANG:-en_US.UTF-8}"
(( $+commands[code] )) && export EDITOR='code --wait'
export VISUAL="$EDITOR"
EOF
```

*(Note: Homebrew/tool-specific PATH entries beyond the essentials are added later, one at a time, per the "step by step" scope — this is deliberately a trimmed-down `.zprofile`, not a full copy of `acme/.zprofile`.)*

- [ ] **Step 2: Preview the target before applying**

Run: `chezmoi diff ~/.config/zsh-acme/.zprofile`
Expected: shows a diff creating a new file (target doesn't exist yet), no errors.

- [ ] **Step 3: Apply, scoped to this one path**

```bash
chezmoi apply ~/.config/zsh-acme/.zprofile
```

- [ ] **Step 4: Verify the target file exists and is correct**

Run: `cat ~/.config/zsh-acme/.zprofile`
Expected: matches the source content written in Step 1.

- [ ] **Step 5: Commit**

```bash
git -C ~/.local/share/chezmoi add private_dot_config/zsh-acme/dot_zprofile
git -C ~/.local/share/chezmoi commit -m "feat: add sandbox .zprofile"
```

---

### Task 3: Add sandbox `.zshrc`

**Files:**
- Create: `~/.local/share/chezmoi/private_dot_config/zsh-acme/dot_zshrc`

**Interfaces:**
- Consumes: nothing new from Task 2 (independent file in the same chain).
- Produces: `~/.config/zsh-acme/.zshrc`, which sources this existing repo's `modules/*.zsh` by absolute path — module migration itself is out of scope for this plan (per spec, modules are ported later, one at a time).

- [ ] **Step 1: Write the source file**

```bash
cat > ~/.local/share/chezmoi/private_dot_config/zsh-acme/dot_zshrc <<'EOF'
_zconfig_root="/Users/nandordudas/.config/zsh"

source "$_zconfig_root/modules/options.zsh"      # Core zsh settings
source "$_zconfig_root/modules/zinit.zsh"        # Plugin manager
source "$_zconfig_root/modules/completions.zsh"  # Completions
source "$_zconfig_root/modules/keybindings.zsh"
source "$_zconfig_root/modules/aliases.zsh"
source "$_zconfig_root/modules/functions.zsh"
source "$_zconfig_root/modules/tools.zsh"

[[ -f "$_zconfig_root/modules/local.zsh" ]] && source "$_zconfig_root/modules/local.zsh"

unset _zconfig_root
EOF
```

- [ ] **Step 2: Preview**

Run: `chezmoi diff ~/.config/zsh-acme/.zshrc`
Expected: diff creating the new file.

- [ ] **Step 3: Apply, scoped**

```bash
chezmoi apply ~/.config/zsh-acme/.zshrc
```

- [ ] **Step 4: Boot a throwaway shell to verify it works**

Run: `ZDOTDIR=~/.config/zsh-acme zsh -i -c 'echo SANDBOX_OK'`
Expected: prints `SANDBOX_OK` with no errors sourcing the modules.

- [ ] **Step 5: Commit**

```bash
git -C ~/.local/share/chezmoi add private_dot_config/zsh-acme/dot_zshrc
git -C ~/.local/share/chezmoi commit -m "feat: add sandbox .zshrc sourcing existing modules"
```

---

### Task 4: Add sandbox `.zlogin` and `.zlogout`

**Files:**
- Create: `~/.local/share/chezmoi/private_dot_config/zsh-acme/dot_zlogin`
- Create: `~/.local/share/chezmoi/private_dot_config/zsh-acme/dot_zlogout`

**Interfaces:**
- Consumes: nothing new.
- Produces: `~/.config/zsh-acme/.zlogin` (no-op placeholder for now — the live `acme/.zlogin`'s self-update trigger is tool-specific and deferred), `~/.config/zsh-acme/.zlogout` (clears the sandbox's own `.zcompdump`).

- [ ] **Step 1: Write `.zlogin`**

```bash
cat > ~/.local/share/chezmoi/private_dot_config/zsh-acme/dot_zlogin <<'EOF'
# Sandbox placeholder — login-shell hooks (e.g. self-update triggers) are added later.
EOF
```

- [ ] **Step 2: Write `.zlogout`**

```bash
cat > ~/.local/share/chezmoi/private_dot_config/zsh-acme/dot_zlogout <<'EOF'
[[ -f "$ZDOTDIR/.zcompdump" ]] && rm -f "$ZDOTDIR/.zcompdump"
EOF
```

- [ ] **Step 3: Preview both**

Run: `chezmoi diff ~/.config/zsh-acme/.zlogin ~/.config/zsh-acme/.zlogout`
Expected: diff creating both new files.

- [ ] **Step 4: Apply, scoped**

```bash
chezmoi apply ~/.config/zsh-acme/.zlogin ~/.config/zsh-acme/.zlogout
```

- [ ] **Step 5: Verify with a login-shell test**

Run: `ZDOTDIR=~/.config/zsh-acme zsh -i -l -c 'echo LOGIN_OK'`
Expected: prints `LOGIN_OK`, no errors.

- [ ] **Step 6: Commit**

```bash
git -C ~/.local/share/chezmoi add private_dot_config/zsh-acme/dot_zlogin private_dot_config/zsh-acme/dot_zlogout
git -C ~/.local/share/chezmoi commit -m "feat: add sandbox .zlogin and .zlogout"
```

---

### Task 5: Add `.zshenv` to source (not applied — deferred cutover)

**Files:**
- Create: `~/.local/share/chezmoi/dot_zshenv`

**Interfaces:**
- Consumes: nothing.
- Produces: source content only. **This file is deliberately never applied in this plan** — applying it would overwrite the live `~/.zshenv`, which zsh reads unconditionally regardless of `$ZDOTDIR`. Cutover is an explicit future decision, out of scope here (per spec's non-goals).

- [ ] **Step 1: Write the source file**

```bash
cat > ~/.local/share/chezmoi/dot_zshenv <<'EOF'
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh-acme"
EOF
```

- [ ] **Step 2: Verify chezmoi sees it but do NOT apply**

Run: `chezmoi managed | grep zshenv`
Expected: prints `.zshenv` — confirms chezmoi tracks it as a managed target.

Run: `chezmoi diff` (full, unscoped — read-only, safe)
Expected: shows `.zshenv` would be created at `~/.zshenv` if ever applied. **Do not run `chezmoi apply .zshenv` or bare `chezmoi apply` as part of this task.**

- [ ] **Step 3: Commit**

```bash
git -C ~/.local/share/chezmoi add dot_zshenv
git -C ~/.local/share/chezmoi commit -m "feat: add .zshenv to source (unapplied, cutover deferred)"
```

---

### Task 6: Add alacritty config

**Files:**
- Create: `~/.local/share/chezmoi/private_dot_config/alacritty/alacritty.toml`

**Interfaces:**
- Consumes: nothing.
- Produces: `~/.config/alacritty/alacritty.toml` managed by chezmoi (parallel copy — the live file at the same path is untouched until this is applied, and applying this one is safe since it's a 146-byte wrapper file, not part of the zsh chain).

- [ ] **Step 1: Copy the live file into chezmoi source**

```bash
mkdir -p ~/.local/share/chezmoi/private_dot_config/alacritty
cp ~/.config/alacritty/alacritty.toml ~/.local/share/chezmoi/private_dot_config/alacritty/alacritty.toml
```

- [ ] **Step 2: Preview**

Run: `chezmoi diff ~/.config/alacritty/alacritty.toml`
Expected: no diff (source now matches the live target byte-for-byte).

- [ ] **Step 3: Verify content has no personal data**

Run: `cat ~/.local/share/chezmoi/private_dot_config/alacritty/alacritty.toml`
Expected: only import lines / theme reference, no absolute home paths with a username, no secrets.

- [ ] **Step 4: Commit**

```bash
git -C ~/.local/share/chezmoi add private_dot_config/alacritty/alacritty.toml
git -C ~/.local/share/chezmoi commit -m "feat: add alacritty config"
```

---

### Task 7: Add herdr config (config file only, not runtime state)

**Files:**
- Create: `~/.local/share/chezmoi/private_dot_config/herdr/config.toml`

**Interfaces:**
- Consumes: nothing.
- Produces: `~/.config/herdr/config.toml` tracked by chezmoi. The sibling runtime files (`sessions/`, `*.log`, `*.sock`, `session*.json`) in `~/.config/herdr/` are never added to chezmoi source — only this one file is copied in.

- [ ] **Step 1: Copy only the config file**

```bash
mkdir -p ~/.local/share/chezmoi/private_dot_config/herdr
cp ~/.config/herdr/config.toml ~/.local/share/chezmoi/private_dot_config/herdr/config.toml
```

- [ ] **Step 2: Preview**

Run: `chezmoi diff ~/.config/herdr/config.toml`
Expected: no diff (matches live file).

- [ ] **Step 3: Verify no runtime files were pulled in**

Run: `ls ~/.local/share/chezmoi/private_dot_config/herdr/`
Expected: only `config.toml` — no `.log`, `.sock`, `.json`, or `sessions/` entries.

- [ ] **Step 4: Commit**

```bash
git -C ~/.local/share/chezmoi add private_dot_config/herdr/config.toml
git -C ~/.local/share/chezmoi commit -m "feat: add herdr config (config file only)"
```

---

### Task 8: Add templated git config

**Files:**
- Create: `~/.local/share/chezmoi/private_dot_config/git/config.tmpl`
- Create (outside source repo, not committed): `~/.config/chezmoi/chezmoi.toml`

**Interfaces:**
- Consumes: nothing from prior tasks.
- Produces: `~/.config/git/config` rendered from the template using `.email` and `.name` data supplied by the local, uncommitted `~/.config/chezmoi/chezmoi.toml` — the public `dotfiles` repo contains no real email or username.

- [ ] **Step 1: Create the local (uncommitted) data file**

```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
[data]
    email = "nandor.dudas@gmail.com"
    name = "Nandor Dudas"
EOF
```

This file lives outside `~/.local/share/chezmoi` (the source repo), so it is never committed or pushed.

- [ ] **Step 2: Write the templated git config**

Only the `[user]` block is templated; the rest is copied verbatim from the current `~/.config/git/config`'s non-personal sections, trimmed to what matters for reproducibility (aliases/settings beyond `[user]` carry no personal data and can be ported wholesale later — kept minimal here per the step-by-step scope):

```bash
mkdir -p ~/.local/share/chezmoi/private_dot_config/git
cat > ~/.local/share/chezmoi/private_dot_config/git/config.tmpl <<'EOF'
[user]
	name = {{ .name }}
	email = {{ .email }}
	signingKey = ~/.ssh/id_ed25519.pub

[gpg]
	format = ssh

[init]
	defaultBranch = main
EOF
```

- [ ] **Step 3: Render and verify the template resolves correctly**

Run: `chezmoi execute-template < ~/.local/share/chezmoi/private_dot_config/git/config.tmpl`
Expected output:
```
[user]
	name = Nandor Dudas
	email = nandor.dudas@gmail.com
	signingKey = ~/.ssh/id_ed25519.pub

[gpg]
	format = ssh

[init]
	defaultBranch = main
```

- [ ] **Step 4: Confirm the source file itself has no personal data**

Run: `grep -E 'nandor|Nandor' ~/.local/share/chezmoi/private_dot_config/git/config.tmpl`
Expected: no matches (only `{{ .name }}` / `{{ .email }}` placeholders are present in the committed file).

- [ ] **Step 5: Commit (source repo only — chezmoi.toml is not part of this repo)**

```bash
git -C ~/.local/share/chezmoi add private_dot_config/git/config.tmpl
git -C ~/.local/share/chezmoi commit -m "feat: add templated git config"
```

---

### Task 9: Push chezmoi source to a new public GitHub repo

**Files:**
- None created — this task wires up the remote for the existing `~/.local/share/chezmoi` repo.

**Interfaces:**
- Consumes: the full chezmoi source tree built in Tasks 1–8.
- Produces: `github.com/nandordudas/dotfiles`, public, with the chezmoi source pushed to `main`.

- [ ] **Step 1: Confirm no personal data anywhere in the source tree before pushing**

```bash
grep -rE 'nandor\.dudas@gmail\.com|/Users/nandordudas' ~/.local/share/chezmoi --include='*' \
  --exclude-dir=.git
```

Expected: no matches. (If `Nandor Dudas` the display name shows up, that's fine — it's a name, not a secret; only the raw email and absolute home path are the hard stop.)

- [ ] **Step 2: Create the GitHub repo**

```bash
gh repo create dotfiles --public --source=~/.local/share/chezmoi --remote=origin
```

- [ ] **Step 3: Push**

```bash
git -C ~/.local/share/chezmoi push -u origin main
```

- [ ] **Step 4: Verify**

Run: `gh repo view nandordudas/dotfiles --json visibility,url`
Expected: `"visibility":"PUBLIC"` and the correct URL.

---

## What's deliberately not in this plan

- Migrating `modules/*.zsh` into chezmoi (sourced from the existing repo path for now, per spec).
- Any cutover of the real `~/.zshenv` / `ZDOTDIR` to the sandbox.
- Deleting or modifying anything in the existing `~/.config/zsh` repo.
- Porting the rest of `~/.config/git/config` (aliases, delta settings, etc.) — only the personal-data-bearing `[user]` block plus a couple of essentials were templated, as a first pass.
