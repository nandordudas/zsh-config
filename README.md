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
curl -sSL https://raw.githubusercontent.com/stefanmaric/g/refs/heads/next/bin/g-install \
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

## Cache management

If a tool behaves unexpectedly after an upgrade, clear the eval caches:

```bash
zsh-cache-clear  # removes ~/.cache/zsh/{starship,zoxide,fnm,direnv}.zsh
exec zsh -l      # regenerates caches on next start
```
