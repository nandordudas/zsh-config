# 🚀 zsh-config

> A fast, modular zsh configuration for productive terminal workflows on macOS.

**Target startup time:** < 100ms | **Platform:** macOS (Apple Silicon & Intel)

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 2. Run the installer (bootstraps Homebrew + all tools)
~/.config/zsh/install.sh

# 3. Open a new terminal and verify
zsh-health
```

That's it. The installer:

- Installs **Homebrew** if missing (`/opt/homebrew` on Apple Silicon — all bottles native arm64)
- Installs every tool the config uses via **`brew bundle`** — the package list is declared in [`Brewfile`](Brewfile) (core) and [`Brewfile.dev`](Brewfile.dev) (Node/Go/Rust toolchains)
- Writes `~/.zshenv`, creates `modules/local.zsh`, links the tmux config
- Is **idempotent** — safe to re-run anytime; existing files are backed up, never silently overwritten

### Installer options

| Flag | Effect |
|------|--------|
| `--minimal` | Core tools only — skip Rust/Go/Node toolchains |
| `--config-only` | Only set up config files, install no packages |
| `--yes` / `-y` | Skip confirmation prompts |
| `--git-name "X" --git-email "Y"` | Also configure git identity + SSH commit signing |
| `--help` | Show all options |

```bash
# Examples
~/.config/zsh/install.sh -y
~/.config/zsh/install.sh --git-name "Jane Doe" --git-email "j@d.dev"
```

> [!TIP]
> **New MacBook?** Run the installer first thing — it bootstraps Homebrew and the entire toolchain in one go. macOS already ships zsh as the default shell, so when it finishes, just open a new terminal.

---

## What is this?

A **fully-featured zsh configuration** built with:

- [Zinit](https://github.com/zdharma-continuum/zinit) plugin manager (turbo mode for speed)
- Curated plugins: autosuggestions, syntax highlighting, fzf-tab, forgit, history substring search
- SSH commit signing (no GPG required)
- Parallel tool updater (`upgrade`) and health diagnostics (`zsh-health`)
- XDG base directory spec compliance — `~` stays clean

**Perfect for:** Developers, DevOps engineers, and anyone who lives in the terminal.

**Not for you if:** You want a minimal config. This is **opinionated** — fork it and adapt to your needs.

---

## Features

| Feature | Benefit |
|---------|---------|
| **Fast startup** | Zinit turbo mode + cached tool initialization (~50-100ms) |
| **Smart plugin loading** | Plugins load on-demand, not at startup |
| **Git integration** | SSH commit signing, per-host identities, delta diffs, 80+ git aliases |
| **macOS-tuned git** | FSEvents `fsmonitor`, fetch/index parallelism = CPU cores |
| **Tool auto-updates** | `upgrade` updates brew, rust, node, zinit and claude in parallel |
| **Fuzzy finder** | fzf for file/history search, fzf-tab completion menus, forgit |
| **Diagnostics** | `zsh-health` checks tools, PATH, and config |
| **XDG compliant** | All config in `~/.config`, cache in `~/.cache` |
| **Headless mode** | `toggle_interactive off` disables Starship + plugins for scripts |

---

## Manual Installation

If you'd rather not run the installer, here's what it does:

<details>
<summary><strong>Step-by-step manual setup</strong></summary>

```bash
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone the config (the Brewfiles live in the repo)
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 3. All tools (native arm64 bottles on Apple Silicon)
brew bundle --file=~/.config/zsh/Brewfile       # core tools
brew bundle --file=~/.config/zsh/Brewfile.dev   # Node/Go/Rust toolchains

# 4. Node (global) via mise, Rust via rustup — other runtimes are per-project
printf 'pnpm\n@antfu/ni\ntaze\nnpkill\nccstatusline\neslint\n' > ~/.default-npm-packages
mise use -g node@lts
rustup-init -y --no-modify-path

# 5. Create ~/.zshenv (required — points zsh at the config)
cat > ~/.zshenv << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

# 6. Machine-local config (gitignored, safe for secrets)
touch ~/.config/zsh/modules/local.zsh

# 7. Link tmux config
mkdir -p ~/.config/tmux
ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf

# 8. Open a new terminal — Zinit installs plugins on first start (~1-2 min)
zsh-health
```

</details>

---

## Configuration

### Machine-local settings

File: `~/.config/zsh/modules/local.zsh` (gitignored — safe for secrets)

```bash
# GitHub and BitBucket usernames (for gg/gb navigation aliases)
export GITHUB_USER="your-github-username"
export BITBUCKET_USER="your-bitbucket-username"

# Project root for gg/gb and freespace.
# Default: ~/Developer (Apple's dev folder — gets a hammer icon in Finder)
# export CODE_DIR="$HOME/Development/Code"

# Custom aliases / functions / overrides
alias myproject="cd ~/projects/myproject"
```

### Customize plugins

Edit `modules/zinit.zsh` and restart the shell. See [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins) for ideas; remove plugins you don't use to improve startup time.

### Customize keybindings / aliases

- `modules/keybindings.zsh` — `Ctrl+R` history, `Ctrl+T` files, word navigation
- `modules/aliases.zsh` — `ll` (eza), `gs`/`gco`/`gcm` (git), `tm` (tmux), …

Full reference: [docs/aliases.md](docs/aliases.md), [docs/keybindings.md](docs/keybindings.md), [docs/functions.md](docs/functions.md)

---

## Common Tasks

### Update everything

```bash
upgrade              # brew, zinit, rust, mise (node/go), claude — in parallel
upgrade --dry-run    # see what would run
upgrade --only mise  # update only mise-managed runtimes + npm globals
```

### Check system health

```bash
zsh-health           # platform, tools, PATH, config — with fix hints
```

### Clear caches

```bash
zsh-cache-clear      # removes eval caches (starship, zoxide, mise, direnv, fzf)
exec zsh             # restart shell (regenerates caches)
```

### Free up disk space

```bash
freespace --dry-run              # preview (no changes)
freespace                        # clean node_modules/vendor under ~/Developer
freespace --aggressive           # also clean npm/pip/go/cargo/brew caches
```

Always asks for confirmation before deleting.

### Interactive git (forgit + aliases)

```bash
glo / ga / gcb / grh   # interactive log / add / checkout / reset (fzf)
gs / gco / gcm / gaa   # status / checkout / commit -m / add -A
git alias              # list all 80+ git aliases
```

### fzf shortcuts

- `Ctrl+R` → fuzzy history search
- `Ctrl+T` → fuzzy file finder (with bat preview)
- `Alt+C` → fuzzy directory jump

### Per-project runtimes (mise)

Node is installed **globally** (always-on tools like `ccstatusline` and `taze`
need it). Everything else is pinned **per project**:

```bash
cd myproject
mise use go@1.24 python@3.13   # writes .mise.toml, installs on demand
mise ls                        # what's active here
```

Global npm tools live in `~/.default-npm-packages` — mise re-installs them
automatically into every new node version, so they survive node upgrades.
Rust is per-project too: commit a `rust-toolchain.toml` and rustup obeys it.

### Headless / automation mode

```bash
toggle_interactive off   # disables Starship + Zinit (fast bare shell)
toggle_interactive on    # back to full features
```

---

## Updating

```bash
git -C ~/.config/zsh pull
zsh-cache-clear
exec zsh
```

A daily login check tells you when the repo has new upstream commits.

---

## Testing

```bash
# Validate the repo without touching your dotfiles
bash ~/.config/zsh/scripts/test.sh
# or
make test
```

---

## Troubleshooting

### "zsh-health: command not found"

The config didn't load. Check:

```bash
echo $ZDOTDIR          # expected: /Users/you/.config/zsh
cat ~/.zshenv          # must export ZDOTDIR
source ~/.zshenv && exec zsh
```

### Tools installed but "command not found"

```bash
exec zsh -l            # restart as login shell (rebuilds PATH)
show_path              # inspect PATH entries
zsh-health             # shows which expected dirs are missing from PATH
```

On Apple Silicon, Homebrew must be at `/opt/homebrew` — `zsh-health` flags this.

### Slow shell startup

```bash
time zsh -i -c exit    # expect ~50-100ms after first run
zinit times            # per-plugin load times
```

First start after install/update is slow (plugin downloads + cache generation) — that's normal.

### Git uses the wrong identity

```bash
git whoami             # show active identity (alias from git-setup.sh)
git config user.name   # check per-repo override
```

`includeIf` blocks in `~/.config/git/config` select identities by repo path.

---

## Git Setup (SSH Commit Signing)

```bash
~/.config/zsh/scripts/git-setup.sh --name "Your Name" --email "your@email.com"
```

Creates `~/.config/git/config`, generates `~/.ssh/id_ed25519` if needed, configures SSH signing (no GPG), enables FSEvents `fsmonitor`, and sets fetch/index parallelism to your CPU core count.

Then register the key on GitHub:

```bash
gh auth refresh -s admin:public_key,admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type signing
```

Verify: `git commit --allow-empty -m "test" && git log --show-signature -1`

---

## Uninstall

One command, one confirmation — the mirror image of install:

```bash
~/.config/zsh/uninstall.sh
```

It restores your original `~/.zshenv` and `tmux.conf` from the backups
install.sh made, moves the config to `~/.config/zsh.uninstalled` (kept, in
case `local.zsh` holds secrets), and clears caches/plugins. Brew packages,
mise runtimes, git config, SSH keys, and shell history are left untouched —
the script prints the `brew bundle cleanup` command if you want packages
gone too.

To disable plugins temporarily without uninstalling: `toggle_interactive off`.

---

## Structure

```
~/.zshenv                     # in $HOME, created by install.sh — sets ZDOTDIR
~/.config/zsh/
├── install.sh                # one-command installer (Homebrew-based)
├── uninstall.sh              # one-command uninstaller (restores backups)
├── Brewfile                  # core packages (brew bundle)
├── Brewfile.dev              # dev toolchains: mise, rustup, fastfetch
├── .zprofile                 # login shells: Homebrew, PATH, env vars
├── .zshrc                    # main orchestrator — sources modules in order
├── modules/
│   ├── options.zsh           # shell options (setopt)
│   ├── zinit.zsh             # plugin manager + all plugins
│   ├── completions.zsh       # completion rules + fzf-tab previews
│   ├── keybindings.zsh       # key mappings
│   ├── aliases.zsh           # command aliases
│   ├── functions.zsh         # upgrade, zsh-health, freespace, …
│   ├── tools.zsh             # cached tool init (starship, zoxide, mise, …)
│   └── local.zsh             # machine-local overrides (gitignored)
├── tmux/tmux.conf            # tmux config (linked to ~/.config/tmux/)
├── scripts/
│   ├── git-setup.sh          # git identity + SSH signing factory
│   └── test.sh               # test suite
└── docs/                     # aliases, functions, keybindings, plugins
```

---

## FAQ

**Q: Does this work on Apple Silicon (M-series) Macs?**
A: Yes, first-class. Homebrew at `/opt/homebrew` with native arm64 bottles; git tuned for the core count. No Rosetta needed.

**Q: Does this work on Linux or WSL?**
A: No — this config targets macOS only. Fork an older revision (pre-macOS-only) if you need Linux/WSL support.

**Q: Can I fork this and customize it?**
A: Yes — that's the recommendation. Put machine-specific bits in `modules/local.zsh`, structural changes in your fork.

**Q: Does this include a prompt theme?**
A: Yes, [Starship](https://starship.rs/). Customize in `~/.config/starship.toml`.

**Q: Can I use this with Oh My Zsh or Prezto?**
A: No, it's built around Zinit. Fork and adapt if you prefer another manager.

**Q: Is this security-reviewed?**
A: It's a personal config with sane practices (no `eval` of remote content, confirmation prompts before deletion, gitignored secrets file), but review it yourself before using in sensitive environments.

---

## Resources

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [Starship Prompt](https://starship.rs/)
- [fzf — Fuzzy Finder](https://github.com/junegunn/fzf)

---

## License

MIT — Use, modify, and share freely.

**Questions?** Open an [issue](https://github.com/nandordudas/zsh-config/issues) on GitHub.
