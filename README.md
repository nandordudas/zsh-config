# zsh-config

Fast, modular zsh configuration using [Zinit](https://github.com/zdharma-continuum/zinit) turbo mode and cached eval outputs.

**Target startup time:** < 100ms (`time zsh -i -c exit`)

## Structure

```
~/.zshenv                    # XDG base dirs + ZDOTDIR only (not in repo)
~/.config/zsh/
├── .zprofile                # Login shell: PATH, env vars, dir creation
├── .zshrc                   # Orchestrator — sources modules in order
└── modules/
    ├── options.zsh          # Shell setopt declarations
    ├── zinit.zsh            # Zinit bootstrap + all plugins (turbo mode)
    ├── completions.zsh      # Completion zstyle config
    ├── keybindings.zsh      # All key bindings (manual, no plugin)
    ├── aliases.zsh          # Aliases
    ├── functions.zsh        # Custom functions
    ├── tools.zsh            # External tool init with eval caching
    └── local.zsh            # Machine-local overrides (gitignored)
```

---

## Prerequisites

### System packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y zsh bat fd-find ripgrep duf zoxide exiftool
chsh -s $(command -v zsh)
```

> **Debian/Ubuntu note:** `bat` is installed as `batcat` and `fd` as `fdfind`.
> The config aliases both to their canonical names.

### direnv — per-project environment variables

```bash
command -v direnv &>/dev/null || curl -sfL https://direnv.net/install.sh | bash
```

### Starship prompt

```bash
command -v starship &>/dev/null || curl -sS https://starship.rs/install.sh | sh
```

### fzf — fuzzy finder

Install from git to get the latest version (apt ships an outdated one):

```bash
[[ -d ~/.fzf ]] || git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc
```

> `--no-update-rc` skips modifying `.bashrc`/`.zshrc` — the config handles
> shell integration itself via `modules/tools.zsh`.

### Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker
```

### fnm — Node.js version manager

```bash
curl -fsSL https://fnm.vercel.app/install | bash
fnm install --lts && fnm default lts-latest
npm install --global pnpm @antfu/ni eslint taze npkill
```

### Go version manager (g)

```bash
curl -sSL https://raw.githubusercontent.com/stefanmaric/g/master/bin/install \
  | GOPATH="$HOME/go" GOROOT="$HOME/.go" bash
g install latest && g set latest
```

### Rust + cargo tools

```bash
command -v rustup &>/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install du-dust procs cargo-update eza git-delta
```

### fastfetch — system info

```bash
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update && sudo apt install -y fastfetch
```

### Claude CLI

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

### GitHub CLI (gh)

Used as a credential helper for HTTPS git operations and for adding SSH keys to GitHub.

```bash
sudo apt install gh -y && gh auth login
```

---

## Git configuration

This repo includes a factory script that applies the full git setup to a new machine. It covers all settings, aliases, delta pager config, per-host identity (GitHub/Bitbucket), and SSH commit signing.

### Apply to a new machine

```bash
~/.config/zsh/scripts/git-setup.sh
# or with explicit values (skips prompts):
~/.config/zsh/scripts/git-setup.sh \
  --name "Your Name" \
  --email "your@email.com"
```

The script is idempotent — safe to re-run after updates.

### What it creates

```
~/.config/git/
├── config                  # Main config (all settings, aliases, delta, signing)
├── ignore                  # Global gitignore (.DS_Store, node_modules, .env, etc.)
├── allowed_signers         # Local SSH signature verification (email + pubkey)
├── github/.gitconfig       # Per-repo identity for ~/Code/GitHub/**
└── bitbucket/.gitconfig    # Per-repo identity for ~/Code/BitBucket/**
```

### SSH commit signing

Since Git 2.34, SSH keys can sign commits and tags — no GPG keyring needed. The same key used for GitHub authentication also signs commits.

**How it works:**

```gitconfig
[gpg]
    format = ssh
[gpg "ssh"]
    allowedSignersFile = ~/.config/git/allowed_signers
[user]
    signingKey = ~/.ssh/id_ed25519.pub
[commit]
    gpgSign = true
[tag]
    gpgSign = true
```

The `allowed_signers` file maps email addresses to public keys for local verification:
```
your@email.com ssh-ed25519 AAAA...
```

**After running the script**, register the SSH key on GitHub to get the "Verified" badge:

```bash
gh auth refresh -s admin:public_key,admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type signing
```

**Verify a signed commit:**

```bash
git log --show-signature -1
# Good "git" signature for your@email.com with ED25519 key SHA256:...
```

### Shell integration

The `.zprofile` sets `GIT_CONFIG_GLOBAL` so git uses the XDG path:

```bash
export GIT_CONFIG_GLOBAL="$HOME/.config/git/config"
```

---

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/nandordudas/zsh-config.git ~/.config/zsh
```

> If `~/.config/zsh` already exists, back it up first:
> ```bash
> mv ~/.config/zsh ~/.config/zsh.bak
> ```

### 2. Create `~/.zshenv`

This file is **not included in the repo** because it must live at `$HOME/.zshenv`.
Create it manually:

```bash
cat > ~/.zshenv << 'EOF'
# ~/.zshenv
# Sourced for ALL zsh invocations (interactive, non-interactive, scripts, git hooks).
# Rule: only what every zsh process needs to locate the real config.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Redirect zsh's dotfile search from $HOME to ~/.config/zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF
```

### 3. Create `modules/local.zsh`

This file is gitignored and holds machine-specific overrides:

```bash
touch ~/.config/zsh/modules/local.zsh
```

### 4. Open a new terminal

On first launch Zinit auto-installs all plugins. Subsequent startups load from
cache and are fast.

---

## Post-install verification

```bash
# Startup time
time zsh -i -c exit

# Check HISTFILE is correct
echo $HISTFILE   # → ~/.local/share/zsh/history

# Check fzf version (requires >= 0.49.0 for forgit)
fzf --version    # → 0.68.x from ~/.fzf/bin

# Check eval caches were created
ls ~/.cache/zsh/ # → starship.zsh  zoxide.zsh  fnm.zsh  direnv.zsh

# Test forgit
glo              # interactive git log with fzf
```

## Testing

Validate the repo without touching your real dotfiles:

```bash
bash ~/.config/zsh/scripts/test.sh
```

Checks: bash/zsh syntax, required files, no personal data leaks,
`git-setup.sh` argument parsing, and a full dry-run in an isolated temp home.

---

## Cache management

If a tool behaves unexpectedly after an upgrade, clear the eval caches:

```bash
zsh-cache-clear  # removes ~/.cache/zsh/{starship,zoxide,fnm,direnv}.zsh
exec zsh -l      # regenerates caches on next start
```
