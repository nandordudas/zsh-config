# zsh config

> [!NOTE]
> This is an **opinionated** personal zsh configuration. It reflects specific tool choices, aliases, and workflows that suit one developer's daily use. Fork and adapt it rather than using it as-is.

Fast, modular zsh configuration using [Zinit](https://github.com/zdharma-continuum/zinit) turbo mode and cached eval outputs.

**Target startup time:** < 100ms (`time zsh -i -c exit`)

## Structure

```
~/.zshenv                    # XDG base dirs + ZDOTDIR only (not in repo)
~/.config/zsh/
├── .zprofile                # Login shell: PATH, env vars, dir creation
├── .zshrc                   # Orchestrator — sources modules in order
├── modules/
│   ├── options.zsh          # Shell setopt declarations
│   ├── zinit.zsh            # Zinit bootstrap + all plugins (turbo mode)
│   ├── completions.zsh      # Completion zstyle config
│   ├── keybindings.zsh      # All key bindings (manual, no plugin)
│   ├── aliases.zsh          # Aliases
│   ├── functions.zsh        # Custom functions
│   ├── tools.zsh            # External tool init with eval caching
│   └── local.zsh            # Machine-local overrides (gitignored)
└── tmux/
    └── tmux.conf            # tmux config (symlink to ~/.config/tmux/tmux.conf)
```

---

## Prerequisites

Install all tools before cloning. Steps must be followed in this order — each section depends on the previous.

### 1. System packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  zsh \
  bat fd-find ripgrep \
  duf zoxide \
  exiftool \
  tmux \
  unrar p7zip-full
chsh -s $(command -v zsh)
```

| Package | Used as | Notes |
|---|---|---|
| `bat` | `bat` (alias `cat`) | Installed as `batcat` on Debian/Ubuntu |
| `fd-find` | `fd` (alias `find`) | Installed as `fdfind` on Debian/Ubuntu |
| `ripgrep` | background fzf search | — |
| `duf` | `df` replacement | — |
| `zoxide` | `z` (smart `cd`) | — |
| `exiftool` | file metadata viewer | — |
| `unrar`, `p7zip-full` | `extract()` function | Archive format support |

### 2. Rust + cargo tools

Install Rust first — subsequent steps depend on it.

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

Install cargo-based tools (including `fnm`, the Node version manager):

```bash
cargo install du-dust procs cargo-update eza git-delta fnm
```

| Binary | Used as | Notes |
|---|---|---|
| `eza` | `ls`/`ll`/`la`/`lt` | Modern ls with icons and git status |
| `du-dust` | `du` replacement | Visual disk usage |
| `procs` | `pss` alias | Modern `ps` |
| `git-delta` | git pager | Syntax-highlighted diffs |
| `cargo-update` | `cargo install-update` | Updates all cargo-installed binaries |
| `fnm` | `fnm` / `nvm` alias | Node.js version manager |

### 3. Node.js via fnm

```bash
fnm install --lts && fnm default lts-latest && fnm use lts-latest
npm install --global npm@latest pnpm@latest @antfu/{ni,nip} eslint taze npkill
```

### 4. Go version manager (g)

```bash
curl -sSL https://raw.githubusercontent.com/stefanmaric/g/master/bin/install \
  | GOPATH="$HOME/go" GOROOT="$HOME/.go" bash
g install latest && g use latest
```

`GOROOT` (`~/.go`) holds the Go toolchain. `GOPATH` (`~/go`) holds installed binaries and the `g` manager itself.

### 5. Starship prompt

```bash
curl -sS https://starship.rs/install.sh | sh
```

### 6. direnv — per-project environment variables

```bash
curl -sfL https://direnv.net/install.sh | bash
```

Automatically loads and unloads `.envrc` files when entering or leaving a directory.

### 7. fzf — fuzzy finder

Install from git to get the latest version (apt ships an outdated one):

```bash
[[ -d ~/.fzf ]] || git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc
```

> `--no-update-rc` skips modifying `.bashrc`/`.zshrc` — the config handles
> shell integration itself via `modules/tools.zsh`.

### 8. fastfetch — system info

```bash
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update && sudo apt install -y fastfetch
```

### 9. GitHub CLI (gh)

Used as a credential helper for HTTPS git operations and for adding SSH keys to GitHub.

> [!WARNING]
> **WSL users:** `gh auth login` opens a browser for OAuth. If WSLg is not enabled or no browser is available, the interactive flow will hang or fail. Use the token-based alternative instead:
> ```bash
> gh auth login --with-token <<< "YOUR_GITHUB_TOKEN"
> ```
> Generate a token at GitHub → Settings → Developer settings → Personal access tokens.

```bash
(type -p wget >/dev/null || sudo apt install wget -y) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
     | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
     | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
  && sudo apt update && sudo apt install gh -y
gh auth login
```

### 10. Docker (optional)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker
```

### 11. Claude CLI (optional)

Used by the `upgrade()` function to check for updates.

```bash
curl -fsSL https://claude.ai/install.sh | bash
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

### 4. Link the tmux config

```bash
mkdir -p ~/.config/tmux
ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf
```

### 5. Open a new terminal

On first launch Zinit auto-installs all plugins. Subsequent startups load from
cache and are fast.

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
├── github/.gitconfig       # Per-repo identity for ~/code/git_hub/**
└── bitbucket/.gitconfig    # Per-repo identity for ~/code/bit_bucket/**
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

## Post-install verification

> [!TIP]
> Run these checks after a fresh install or after pulling updates to confirm everything is wired up correctly.

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

### Unit tests (no install required)

Validate the repo without touching your real dotfiles:

```bash
bash ~/.config/zsh/scripts/test.sh
```

Checks: bash/zsh syntax, required files, no personal data leaks,
`git-setup.sh` argument parsing, and a full dry-run in an isolated temp home.

### Full install test in Docker

> [!IMPORTANT]
> The Docker build downloads all tools from the internet. It takes several minutes on first run. Subsequent builds reuse cached layers.

Test the complete install on a clean Ubuntu 24.04 environment:

```bash
# From the repo root
docker build -t zsh-config-test .

# Drop into an interactive shell to explore the result
docker run -it --rm zsh-config-test
```

The Dockerfile runs all prerequisite installs in order, copies the config,
and executes `test.sh` as part of the build — a failed test aborts the build.

> **Note:** `gh auth login` and `chsh` are skipped in the container (they require
> interactive authentication and PAM respectively). Docker-in-Docker is also
> excluded — run Docker setup steps on the host.

---

## Cache management

> [!TIP]
> If a tool behaves unexpectedly after an upgrade, clear the eval caches:

```bash
zsh-cache-clear  # removes ~/.cache/zsh/{starship,zoxide,fnm,direnv}.zsh
exec zsh -l      # regenerates caches on next start
```

> [!CAUTION]
> Do not delete `~/.local/share/zinit` unless you intend to reinstall all plugins from scratch. Zinit stores compiled plugin snapshots there; removing it triggers a full re-download on next shell start.
