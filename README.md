# 🚀 zsh-config

> A fast, modular zsh configuration for productive terminal workflows — on macOS (Apple Silicon & Intel), Ubuntu/Debian, and WSL2.

**Target startup time:** < 100ms

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 2. Run the installer (detects your OS, installs everything)
~/.config/zsh/install.sh

# 3. Open a new terminal and verify
zsh-health
```

That's it. The installer:

- **macOS** — installs Homebrew (if missing) and all tools as native bottles (arm64 on Apple Silicon)
- **Ubuntu/Debian/WSL2** — installs via apt + rustup/cargo for tools not packaged
- Writes `~/.zshenv`, creates `modules/local.zsh`, links the tmux config, and offers to make zsh your default shell
- Is **idempotent** — safe to re-run anytime; existing files are backed up, never silently overwritten

### Installer options

| Flag | Effect |
|------|--------|
| `--minimal` | Core tools only — skip Rust/Go/Node toolchains (good for servers) |
| `--config-only` | Only set up config files, install no packages |
| `--yes` / `-y` | Skip confirmation prompts (CI / automation) |
| `--git-name "X" --git-email "Y"` | Also configure git identity + SSH commit signing |
| `--help` | Show all options |

```bash
# Examples
~/.config/zsh/install.sh --minimal -y                                  # server
~/.config/zsh/install.sh --git-name "Jane Doe" --git-email "j@d.dev"   # full + git
```

> [!TIP]
> **New MacBook?** Run the installer first thing — it bootstraps Homebrew and the entire toolchain in one go. macOS already ships zsh as the default shell, so after `install.sh` finishes, just open a new terminal.

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

## Platform Support

| Platform | Status | Package source |
|----------|--------|----------------|
| macOS (Apple Silicon) | ✅ first-class | Homebrew (`/opt/homebrew`) |
| macOS (Intel) | ✅ | Homebrew (`/usr/local`) |
| Ubuntu 22.04+ / Debian 12+ | ✅ | apt + cargo |
| WSL2 (Ubuntu) | ✅ | apt + cargo, Windows clipboard integration |
| Other Linux (Fedora, Arch, …) | ⚙️ manual | install tools yourself, then `install.sh --config-only` |

Platform differences are handled automatically at runtime by `modules/platform.zsh`:

- `bat`/`fd` vs Debian's `batcat`/`fdfind` — resolved once, used everywhere (aliases, fzf previews, health check)
- Clipboard: native `pbcopy`/`pbpaste` on macOS, `clip.exe` on WSL, `wl-copy`/`xclip` on Linux
- `ports` uses `ss` on Linux, `lsof` on macOS
- `upgrade` uses `brew` on macOS, `apt` on Debian — never assumes either
- Homebrew is added to `PATH` automatically on login (Apple Silicon and Intel paths)

---

## Features

| Feature | Benefit |
|---------|---------|
| **Fast startup** | Zinit turbo mode + cached tool initialization (~50-100ms) |
| **Smart plugin loading** | Plugins load on-demand, not at startup |
| **Git integration** | SSH commit signing, per-host identities, delta diffs, 80+ git aliases |
| **Tool auto-updates** | `upgrade` updates brew/apt, rust, node, go, zinit and claude in parallel |
| **Fuzzy finder** | fzf for file/history search, fzf-tab completion menus, forgit |
| **Diagnostics** | `zsh-health` checks platform, tools, PATH, and config |
| **XDG compliant** | All config in `~/.config`, cache in `~/.cache` |
| **Server mode** | `toggle_interactive off` disables Starship + plugins for headless use |

---

## Manual Installation

If you'd rather not run the installer, here's what it does:

<details>
<summary><strong>macOS (Homebrew)</strong></summary>

```bash
# 1. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. All tools (native arm64 bottles on Apple Silicon)
brew install git tmux fzf bat fd ripgrep eza zoxide starship direnv gh \
             git-delta dust duf procs sevenzip fnm go fastfetch

# 3. Node.js via fnm
fnm install --lts && fnm default lts-latest

# 4. Rust (optional, for cargo development)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 5. Clone config + create ~/.zshenv (see "Config files" below)
```

</details>

<details>
<summary><strong>Ubuntu / Debian / WSL2</strong></summary>

```bash
# 1. System packages
sudo apt update
sudo apt install -y zsh git tmux curl wget unzip bat fd-find ripgrep zoxide \
                    duf p7zip-full

# 2. Rust + cargo tools
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo install eza git-delta du-dust procs fnm cargo-update

# 3. Node.js via fnm
fnm install --lts && fnm default lts-latest

# 4. Go version manager
curl -sSL https://raw.githubusercontent.com/stefanmaric/g/master/bin/install | \
  GOPATH="$HOME/go" GOROOT="$HOME/.go" bash

# 5. Starship, direnv, fzf
curl -sS https://starship.rs/install.sh | sh
curl -sfL https://direnv.net/install.sh | bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc

# 6. GitHub CLI — see https://github.com/cli/cli/blob/trunk/docs/install_linux.md
```

</details>

<details>
<summary><strong>Config files (all platforms)</strong></summary>

```bash
# 1. Clone the config
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 2. Create ~/.zshenv (required — points zsh at the config)
cat > ~/.zshenv << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

# 3. Machine-local config (gitignored, safe for secrets)
touch ~/.config/zsh/modules/local.zsh

# 4. Link tmux config
mkdir -p ~/.config/tmux
ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf

# 5. Make zsh the default shell (Linux/WSL; macOS already defaults to zsh)
chsh -s "$(command -v zsh)"

# 6. Open a new terminal — Zinit installs plugins on first start (~1-2 min)
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
upgrade              # brew/apt, zinit, rust, node, go, claude — in parallel
upgrade --dry-run    # see what would run
upgrade --only node  # update only Node.js
```

### Check system health

```bash
zsh-health           # platform, tools, PATH, config — with fix hints
```

### Clear caches

```bash
zsh-cache-clear      # removes eval caches (starship, zoxide, fnm, direnv)
exec zsh             # restart shell (regenerates caches)
```

### Free up disk space

```bash
freespace --dry-run              # preview (no changes)
freespace                        # clean node_modules/vendor under ~/code
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

---

## Server / Headless Use

Use `--minimal` at install time, and toggle off interactive features at runtime:

```bash
toggle_interactive off   # disables Starship + Zinit (fast shell for automation)
toggle_interactive on    # back to full features
```

Server-safe functions: `mkcd`, `extract`, `confirm`, `ports`, `show_path`, `tmpcd`, `toggle_interactive`. Functions needing a terminal/fzf (`upgrade`, `interactive_kill`, `freespace`) work over SSH but not in cron.

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

# Full install test in a clean Ubuntu 24.04 container
make docker-run
```

---

## Troubleshooting

### "zsh-health: command not found"

The config didn't load. Check:

```bash
echo $ZDOTDIR          # expected: /Users/you/.config/zsh (or /home/you/…)
cat ~/.zshenv          # must export ZDOTDIR
source ~/.zshenv && exec zsh
```

### Tools installed but "command not found"

```bash
exec zsh -l            # restart as login shell (rebuilds PATH)
show_path              # inspect PATH entries
zsh-health             # shows which expected dirs are missing from PATH
```

On Apple Silicon: Homebrew must be at `/opt/homebrew` — `zsh-health` flags this.

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

Creates `~/.config/git/config`, generates `~/.ssh/id_ed25519` if needed, configures SSH signing (no GPG), and applies platform-specific tuning automatically (FSEvents monitoring + full-core parallelism on macOS, NTFS long paths on WSL).

Then register the key on GitHub:

```bash
gh auth refresh -s admin:public_key,admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type signing
```

Verify: `git commit --allow-empty -m "test" && git log --show-signature -1`

---

## Uninstall

```bash
chsh -s /bin/bash                       # or your original shell (skip on macOS)
mv ~/.config/zsh ~/.config/zsh.bak      # keep a backup
rm ~/.zshenv ~/.config/tmux/tmux.conf
# open a new terminal
```

To disable plugins temporarily without uninstalling: `toggle_interactive off`.

---

## Structure

```
~/.zshenv                     # in $HOME, created by install.sh — sets ZDOTDIR
~/.config/zsh/
├── install.sh                # one-command installer (macOS / Ubuntu / WSL)
├── .zprofile                 # login shells: PATH, Homebrew, env vars
├── .zshrc                    # main orchestrator — sources modules in order
├── modules/
│   ├── platform.zsh          # OS detection, portable command names (bat/fd)
│   ├── options.zsh           # shell options (setopt)
│   ├── zinit.zsh             # plugin manager + all plugins
│   ├── completions.zsh       # completion rules + fzf-tab previews
│   ├── keybindings.zsh       # key mappings
│   ├── aliases.zsh           # command aliases (platform-aware)
│   ├── functions.zsh         # upgrade, zsh-health, freespace, …
│   ├── tools.zsh             # cached tool init (starship, zoxide, fnm, …)
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
A: Yes, first-class. The installer uses Homebrew at `/opt/homebrew` with native arm64 bottles, and `git-setup.sh` tunes git for the core count. No Rosetta needed.

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
