# 🚀 zsh-config

> A fast, modular zsh configuration for productive terminal workflows.

**Target startup time:** < 100ms | **Current version:** v1.1.0

---

> [!TIP]
> **Use Claude Code for setup:**  
> 1. Clone: `git clone https://github.com/nandordudas/zsh-config ~/.config/zsh`  
> 2. Open `~/.config/zsh` in [Claude Code](https://claude.ai/code)  
> 3. Ask Claude: *"Help me finish setting up this zsh config. What prerequisites do I need for my OS, and what installation steps should I follow?"*
> 
> Or follow [Quick Start](#quick-start-5-minutes) manually below.

---

## What is this?

A **fully-featured zsh configuration** built with:
- [Zinit](https://github.com/zdharma-continuum/zinit) plugin manager (turbo mode for speed)
- 50+ curated plugins and tools (fuzzy search, git integration, syntax highlighting)
- SSH commit signing (no GPG required)
- Auto-updating tools and diagnostics
- XDG base directory spec compliance

**Perfect for:** Developers, DevOps engineers, and anyone who lives in the terminal.

**Not for you if:** You want a minimal config. This is **opinionated** — fork it and adapt to your needs.

---

## Quick Start (5 minutes)

For experienced users with Rust, Go, and Node already installed:

```bash
# 1. Clone the config
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# (Optional: use npx tiged if you prefer)
# npx tiged nandordudas/zsh-config ~/.config/zsh --disable-cache

# 2. Create ~/.zshenv (required)
cat > ~/.zshenv << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

# 3. Setup machine-local config (empty)
touch ~/.config/zsh/modules/local.zsh

# 4. Link tmux config
mkdir -p ~/.config/tmux
ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf

# 5. Open new terminal and verify
zsh-health
```

**Next steps:**
- Run `zsh-health` to diagnose issues
- Review `modules/local.zsh` for customization
- See "[Configuration](#configuration)" section below

---

## Features

| Feature | Benefit |
|---------|---------|
| **Fast startup** | Zinit turbo mode + cached tool initialization (~50-100ms) |
| **Smart plugin loading** | Plugins load on-demand, not at startup |
| **Git integration** | SSH commit signing, per-host identities, fast diffs |
| **Tool auto-updates** | `upgrade` function checks for newer versions |
| **Fuzzy finder** | fzf for file/history search, git operations |
| **Language support** | Auto-install Node.js (fnm), Go (g), Rust (cargo) |
| **Diagnostics** | `zsh-health` checks all critical tools and config |
| **XDG compliant** | All config in `~/.config`, cache in `~/.cache` |

---

## Prerequisites

You'll install these tools before cloning the config. Choose your system:

> **Platform notes:** Config tested on **Ubuntu 22.04+**, **macOS 12+**, and **WSL2**. Core tools work anywhere, but some features (fastfetch, native font rendering) are WSL-only. See notes below.

<details>
<summary><strong>Ubuntu/Debian/WSL (all platforms)</strong></summary>

```bash
# 1. System packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y zsh bat fd-find ripgrep duf zoxide exiftool tmux unrar p7zip-full

# 2. Change default shell to zsh
chsh -s $(command -v zsh)
# Log out and log in for shell change to take effect

# 3. Rust + cargo tools
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo install du-dust procs cargo-update eza git-delta fnm

# 4. Node.js via fnm
fnm install --lts && fnm default lts-latest && fnm use lts-latest
npm install --global npm@latest pnpm@latest @antfu/{ni,nip} eslint taze npkill

# 5. Go version manager
curl -sSL https://raw.githubusercontent.com/stefanmaric/g/master/bin/install | \
  GOPATH="$HOME/go" GOROOT="$HOME/.go" bash
g install latest && g use latest

# 6. Starship prompt
curl -sS https://starship.rs/install.sh | sh

# 7. direnv (environment variables per-directory)
curl -sfL https://direnv.net/install.sh | bash

# 8. fzf (fuzzy finder)
[[ -d ~/.fzf ]] || git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc

# 9. fastfetch (system info) — WSL2 only, optional on other systems
# Skip on servers or if you don't need fast system info
# Note: Ubuntu 24+ doesn't ship fastfetch in default repos
if grep -q 'VERSION_ID="24\.' /etc/os-release 2>/dev/null; then
  # Ubuntu 24+: use PPA
  sudo add-apt-repository ppa:zhangsongcui3371/fastfetch 2>/dev/null || true
fi
sudo apt update && sudo apt install -y fastfetch 2>/dev/null || true

# 10. GitHub CLI (required for git operations)
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt update && sudo apt install -y gh

# 11. Authenticate with GitHub (interactive)
gh auth login
```

**Platform-specific notes:**
- **WSL2**: All tools work. fastfetch shows accurate system info. Git and tmux render properly.
- **Native Linux**: Works identically to WSL. Tested on Ubuntu 22.04+.
- **macOS**: Use Homebrew section below for easier installation.

</details>

<details>
<summary><strong>macOS (with Homebrew)</strong></summary>

```bash
# 1. Install Homebrew if you haven't
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. System packages
brew install zsh bat fd ripgrep duf zoxide exiftool tmux unrar p7zip

# 3. Change default shell
chsh -s $(which zsh)

# 4. Rust + cargo tools
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo install du-dust procs cargo-update eza git-delta fnm

# 5. Node.js via fnm
fnm install --lts && fnm default lts-latest && fnm use lts-latest
npm install --global npm@latest pnpm@latest @antfu/{ni,nip} eslint taze npkill

# 6. Go
brew install go

# 7. Starship
brew install starship

# 8. direnv
brew install direnv

# 9. fzf
brew install fzf

# 10. fastfetch
brew install fastfetch

# 11. GitHub CLI
brew install gh
gh auth login
```

</details>

<details>
<summary><strong>Other systems (Fedora, Arch, etc.)</strong></summary>

Adjust package names for your distro. Core requirements:
- `zsh`, `git`, `tmux`, `ripgrep` (system packages)
- `rustup` → `cargo` tools (eza, du-dust, procs, fnm)
- `go` or Go version manager
- `starship`, `direnv`, `fzf`, `fastfetch` (install via package manager or from source)
- `gh` (GitHub CLI)

See [Starship docs](https://starship.rs/guide/#🚀-installation) for distribution-specific instructions.

</details>

**After prerequisites:**
- Verify all tools are in PATH: `zsh-health` (or wait until after installing the config)
- Close and reopen your terminal

---

## Server-Only Setup (Production)

Minimal zsh config for production servers (no dev tools, smaller footprint):

### Installation

```bash
# 1. System packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y zsh git tmux ripgrep fd-find bat zoxide

# 2. Change shell
chsh -s $(command -v zsh)

# 3. Rust + git-delta only
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
cargo install git-delta

# 4. fzf
[[ -d ~/.fzf ]] || git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc

# 5. Clone config
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# 6. Create ~/.zshenv
cat > ~/.zshenv << 'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF

# 7. Create empty local.zsh (optional customizations)
touch ~/.config/zsh/modules/local.zsh

# 8. Link tmux config (optional)
mkdir -p ~/.config/tmux && ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf

# 9. Verify
zsh-health
```

### Interactive Mode Toggle

Starship and Zinit can be toggled for headless vs. interactive use:

**`toggle_interactive on`** — Enable Starship + Zinit (for interactive SSH sessions)  
**`toggle_interactive off`** — Disable both (for headless tasks, cron, scripts)

```bash
# On server, you can switch modes anytime:
toggle_interactive off   # Fast shell for automation
toggle_interactive on    # Full features for interactive work
```

**Why toggle?**
- **Starship:** Re-evaluates git status on every prompt (~100-200ms overhead). Useful interactively; wasteful in automation.
- **Zinit:** Loads 50+ plugins (syntax highlighting, git info, completions). Great for development; unnecessary for scripts.

### What's Included

| Tool | Why |
|------|-----|
| **zsh** | Better scripting than bash, familiar workflow |
| **git** | Version control, CI/CD integration |
| **tmux** | Session persistence for long-running tasks |
| **ripgrep/fd/bat** | Fast log searching, better tools |
| **zoxide** | Smart directory navigation |
| **fzf** | Interactive scripts, Ctrl+R history search |
| **git-delta** | Better git diffs |

### What's NOT Included

- **Node.js, Go version managers** — Only if you build/run these services
- **Starship, Fastfetch** — Development tools; unnecessary on headless servers
- **Claude, npm dev tools** — Security/relevance risk on production

### Available Functions (Server-Safe)

✓ **Always work:** `mkcd`, `extract`, `confirm`, `bootstrap`, `ports`, `show_path`, **`toggle_interactive`**  
⚠ **Interactive only:** `upgrade`, `interactive_kill`, `freespace` (need terminal/fzf)

### Quick Tests

```bash
zsh-health                    # Verify installation
time zsh -i -c exit           # Startup time (expect <200ms with interactive mode)
git status && git pull        # Test git
ports                         # List listening ports
bat /var/log/syslog          # Test syntax highlighting

# Toggle interactive mode
toggle_interactive off        # Disable Starship + Zinit (fast for automation)
time zsh -i -c exit           # Should be faster now (~50-100ms)
toggle_interactive on         # Re-enable for interactive work
```

### Optional: Git Setup (SSH Signing)

```bash
export GIT_NAME="Admin" GIT_EMAIL="admin@example.com"
~/.config/zsh/scripts/git-setup.sh --name "$GIT_NAME" --email "$GIT_EMAIL"
```

Skip if server only pulls code or uses system git config.

### Troubleshooting

**Tools not found:**
```bash
command -v git tmux fzf bat  # Check PATH
exec zsh -l                  # Restart shell
```

**Functions fail in cron/systemd:**  
Expected for fzf-based functions (`upgrade`, `interactive_kill`). Use direct commands instead:
```bash
# Instead of: upgrade
sudo apt-get update && sudo apt-get upgrade -y
```

**Slow startup:**
Verify Starship/Zinit are disabled:
```bash
echo $DISABLE_STARSHIP  # Should be 1
echo $ZINIT_SKIP       # Should be 1
```

---

## Installation (Step-by-Step)

### Step 1: Clone the config

```bash
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh
```

Or if `~/.config/zsh` exists:
```bash
mv ~/.config/zsh ~/.config/zsh.bak  # backup first
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh
```

**Optional alternative:** Use `npx tiged` if you prefer (requires Node.js):
```bash
npx tiged nandordudas/zsh-config ~/.config/zsh --disable-cache
```

### Step 2: Create `~/.zshenv` (required)

This file must be in your home directory (not in the repo). It sets up the XDG directory structure:

```bash
cat > ~/.zshenv << 'EOF'
# ~/.zshenv
# Sourced for every zsh invocation (login shells, interactive shells, scripts, git hooks).
# Only put things here that every zsh process needs — usually just env vars for directory locations.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Tell zsh to look for dotfiles in ~/.config/zsh instead of ~
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF
```

### Step 3: Create machine-local config

This file holds per-machine settings (API keys, usernames, custom aliases):

```bash
touch ~/.config/zsh/modules/local.zsh
```

Example content (see "[Configuration](#configuration)" for more):
```bash
# ~/.config/zsh/modules/local.zsh
export GITHUB_USER="yourname"
export BITBUCKET_USER="yourname"

# Add machine-specific aliases or functions here
```

### Step 4: Link tmux config

```bash
mkdir -p ~/.config/tmux
ln -sf ~/.config/zsh/tmux/tmux.conf ~/.config/tmux/tmux.conf
```

### Step 5: Open new terminal

**On first launch:**
- Zinit downloads and installs all plugins (takes 1-2 minutes)
- Eval caches are created in `~/.cache/zsh/`
- Subsequent starts are fast (~50-100ms)

**Verify it worked:**
```bash
zsh-health  # Shows all critical tools and their status
time zsh -i -c exit  # Measure startup time
```

---

## Configuration

### Edit machine-local settings

File: `~/.config/zsh/modules/local.zsh` (gitignored)

```bash
# GitHub and BitBucket usernames (for per-repo git identities)
export GITHUB_USER="your-github-username"
export BITBUCKET_USER="your-bitbucket-username"

# Custom aliases
alias myproject="cd ~/projects/myproject"

# Custom functions
my-build() {
  echo "Building..." && make build
}

# Override default behavior
# (Most of the config is here; this file extends it)
```

This file is automatically sourced by `.zshrc` and is **not tracked by git** (safe for secrets).

### Customize plugins

File: `~/.config/zsh/modules/zinit.zsh`

To add/remove plugins, edit the file and restart the shell. Most common customizations:
- Change color theme (search `oh-my-posh` or `powerlevel10k`)
- Add new plugins (see [awesome-zsh-plugins](https://github.com/unixorn/awesome-zsh-plugins))
- Disable plugins you don't use (improves startup time)

### Customize keybindings

File: `~/.config/zsh/modules/keybindings.zsh`

Keybindings are manually defined (not from plugins) for consistency. Edit to customize `Ctrl+R` history, `Ctrl+T` file finder, etc.

### Customize aliases

File: `~/.config/zsh/modules/aliases.zsh`

Common aliases:
- `ll` → `eza -la` (detailed file listing)
- `cat` → `bat` (syntax-highlighted cat)
- `find` → `fd` (faster, intuitive find)
- `du` → `dust` (visual disk usage)

---

## Common Tasks

### Update tools

Periodically check for updates:
```bash
upgrade              # Checks all tools, shows what will be updated
upgrade --dry-run    # See what would update without making changes
upgrade --only node  # Update only Node.js
```

Supported tools: `apt`, `rust`, `cargo`, `node`, `go`, `gh`, `zsh`, `fzf`

### Check system health

```bash
zsh-health
```

Verifies:
- All critical tools installed
- PATH configured correctly
- Shell setup correct
- Issues and how to fix them

### Clear caches

If a tool acts weird after an update:
```bash
zsh-cache-clear      # Removes eval caches
exec zsh -l          # Restart shell (regenerates caches)
```

> **Don't delete** `~/.local/share/zinit` — it contains compiled plugins. Deleting it forces a re-download on next start.

### Free up disk space

Smart cleanup of project directories and system caches:

```bash
freespace --dry-run              # See what would be deleted (no changes)
freespace                        # Clean project dirs (node_modules, vendor in ~/code)
freespace --aggressive           # Also clean system caches (npm, pip, go, cargo, apt)
freespace --aggressive --dry-run # Preview aggressive cleanup
```

**What it cleans:**
- **Always:** `node_modules` and `vendor` dirs in `~/code` (reclaimable at any time)
- **With `--aggressive`:** npm cache (1.5G), pip cache, Go build cache, Cargo cache, apt cache

Uses `confirm()` to prompt before deleting — safe against accidents.

### Interact with git

**forgit aliases** (interactive git operations with fzf):
```bash
glo                  # Git log picker (interactive)
gd                   # Git diff with files (interactive)
gcb                  # Git checkout branch (interactive)
ga                   # Git add with file picker (interactive)
grh                  # Git reset HEAD (interactive)
gss                  # Git stash show (interactive)
gcp                  # Git cherry-pick from branch (interactive)
```

**Standard git aliases**:
```bash
gs                   # git status
gco                  # git checkout
gcm                  # git commit -m
gaa                  # git add -A
gst                  # git stash
```

For complete list, see `modules/aliases.zsh` or run `git alias`.

### Use fzf

Built-in fuzzy finding:
- `Ctrl+R` → Search command history
- `Ctrl+T` → Find files/directories
- `Alt+C` → Smart directory navigation

### Uninstall / Disable

To remove this config and revert to your system default shell:

```bash
# 1. Revert to bash (or your original shell)
chsh -s /bin/bash

# 2. Remove zsh config directory (keeps backup)
mv ~/.config/zsh ~/.config/zsh.bak

# 3. Remove zsh environment file
rm ~/.zshenv

# 4. Remove tmux symlink
rm ~/.config/tmux/tmux.conf

# 5. Close and reopen terminal
# You're back to default shell. Restore ~/.config/zsh.bak if needed.
```

**To temporarily disable without uninstalling:**

```bash
# Disable zinit plugin loading (keeps config intact)
# Edit ~/.config/zsh/modules/local.zsh:
cat >> ~/.config/zsh/modules/local.zsh << 'EOF'
# Temporarily disable plugins
export ZINIT_SKIP=1
EOF

# Then restart shell
exec zsh

# To re-enable, remove the ZINIT_SKIP=1 line and restart
```

**To reset to factory defaults:**

```bash
# Backup your current setup
cp -r ~/.config/zsh ~/.config/zsh.custom-backup

# Reclone and overwrite
rm -rf ~/.config/zsh
git clone https://github.com/nandordudas/zsh-config ~/.config/zsh

# Or update to latest from git
cd ~/.config/zsh && git pull origin main
zsh-cache-clear && exec zsh
```

---

## Verify Installation

Run checks after a fresh install or after pulling updates:

```bash
# Quick health check (recommended first step)
zsh-health

# Detailed checks
time zsh -i -c exit         # Startup time (expected: ~50-100ms)
echo $HISTFILE              # Expected: ~/.local/share/zsh/history
node --version              # Expected: v20+ (auto-installed)
fzf --version               # Expected: 0.68+
ls ~/.cache/zsh/            # Expected: starship.zsh, zoxide.zsh, fnm.zsh, direnv.zsh
upgrade --dry-run           # See what would update

# Test forgit (interactive git with fzf)
cd ~/.config/zsh
glo                         # Git log picker
gcb                         # Git checkout branch picker
```

All checks should pass. If not, see "[Troubleshooting](#troubleshooting)".

---

## Testing

### Run tests locally (no install needed)

Validate the config without modifying your system:

```bash
bash ~/.config/zsh/scripts/test.sh
```

Checks:
- Bash/zsh syntax
- Required files exist
- No personal data in repo
- `git-setup.sh` argument parsing
- Full dry-run in isolated environment

### Full install test in Docker

Test on a clean Ubuntu 24.04:

```bash
# Recommended (reads versions from .docker/versions.env)
make docker-run

# Or manually
docker build -f .docker/Dockerfile -t zsh-config-test .
docker run -it --rm zsh-config-test
```

Takes 5-10 minutes. Reuses cached layers on subsequent builds.

---

## Troubleshooting

### "zsh-health: command not found"

Run `zsh-health` after opening a new terminal. If still missing, the config didn't load:

```bash
# Check ZDOTDIR is set
echo $ZDOTDIR    # Expected: /home/yourname/.config/zsh

# Check .zshenv exists
ls -la ~/.zshenv

# Check ~/.zshenv sets ZDOTDIR
cat ~/.zshenv | grep ZDOTDIR

# Manually source and try
source ~/.zshenv
exec zsh
zsh-health
```

### "Node: command not found" after fresh install

Node is auto-installed on first shell start. If missing:

```bash
fnm install --lts
fnm default lts-latest
exec zsh
node --version
```

### Slow shell startup

Profile it:

```bash
time zsh -i -c exit              # Total time
zinit report                     # Slow plugins
zsh -x 2>&1 | head -50          # First steps
```

Most plugins load on-demand (turbo mode), so slow startup is rare. If a plugin is slow, comment it out in `modules/zinit.zsh`.

### "Command not found" for tools installed via cargo/fnm

PATH not updated. Fix:

```bash
# Check PATH includes tool locations
echo $PATH | grep -E "cargo|fnm|go"

# If missing, restart your shell
exec zsh -l

# Or manually source
source ~/.zshenv
source ~/.zprofile
```

### Upgrade fails or is slow

Test in dry-run mode:

```bash
upgrade --dry-run --only node  # See what will run
upgrade --only apt,rust        # Skip slow checks
```

Network issues? One tool failing doesn't block others (jobs are resilient).

### Git config conflicts

If git uses wrong identity on some repos:

1. Check which identity is active: `git config user.name`
2. Verify `includeIf` paths in `~/.config/git/config` match your repo layout
3. Or run per-repo override: `git config user.name "Your Name"`

---

## Advanced: Git Setup (Optional)

For automatic per-repo identities and SSH commit signing:

```bash
# Run the factory script
~/.config/zsh/scripts/git-setup.sh
# or with explicit values (skips prompts):
~/.config/zsh/scripts/git-setup.sh \
  --name "Your Name" \
  --email "your@email.com"
```

Creates:
- `~/.config/git/config` — Main git config
- `~/.ssh/id_ed25519` — SSH signing key
- Per-repo identities for GitHub, Bitbucket

After running, register SSH key on GitHub:

```bash
gh auth refresh -s admin:public_key,admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type signing
```

Verify:
```bash
git commit --allow-empty -S -m "test: ssh signing"
git log --show-signature -1
# Output: Good "git" signature for your@email.com with ED25519 key
```

---

## Updating

### Pull latest changes

```bash
cd ~/.config/zsh
git pull origin main
zsh-cache-clear      # Clear old caches
exec zsh             # Reload with new config
```

### See what changed

```bash
git log --oneline -n 10              # Last 10 commits
git diff HEAD~5..HEAD -- modules/   # Last 5 commits
git show HEAD                        # Latest commit details
```

### Rollback to previous version

```bash
git log --oneline             # Find a commit hash
git checkout HASH             # Go back to that version
exec zsh                      # Reload
```

---

## Structure

```
~/.zshenv                    # Home, required (you create this)
~/.config/zsh/
├── .zprofile                # Login shell: PATH, env vars
├── .zshrc                    # Main orchestrator
├── modules/
│   ├── options.zsh           # Shell options (setopt)
│   ├── zinit.zsh             # Plugin manager + all plugins
│   ├── completions.zsh       # Completion rules
│   ├── keybindings.zsh       # Key mappings
│   ├── aliases.zsh           # Command aliases
│   ├── functions.zsh         # Custom functions
│   ├── tools.zsh             # External tool setup + caching
│   └── local.zsh             # Machine-local (gitignored)
├── tmux/
│   └── tmux.conf             # tmux config
└── scripts/
    ├── git-setup.sh          # Git configuration factory
    └── test.sh               # Test suite
```

---

## FAQ

**Q: Will this config work on my machine?**

A: Tested on Ubuntu 22.04+, macOS 12+, and WSL2. Requires Bash 4+, Zsh 5.4+. See [Server-Only Setup](#server-only-setup-production) for production deployments (fewer dependencies, no dev tools).

**Q: Can I fork this and customize it?**

A: Yes! That's the recommendation. It's opinionated; customize `modules/local.zsh` for your workflow.

**Q: Does this include a prompt theme?**

A: Yes, Starship. Customize in `~/.config/starship.toml`.

**Q: Can I use this with other plugin managers (Oh My Zsh, Prezto)?**

A: No, it's specifically built around Zinit. Fork and adapt if you prefer another manager.

**Q: How do I report bugs or suggest features?**

A: Open an issue on [GitHub](https://github.com/nandordudas/zsh-config/issues).

**Q: Is this security-tested?**

A: It's a personal config, not a security-hardened system. Review before using in sensitive environments.

**Q: Why is Claude excluded from the server setup?**

A: Claude is a development tool. Server setups should not include API keys or client tools that require authentication. Use the [Server-Only Setup](#server-only-setup-production) guide to install a minimal zsh config on production without dev dependencies.

---

## Resources

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Zinit Plugin Manager](https://github.com/zdharma-continuum/zinit)
- [Awesome Zsh Plugins](https://github.com/unixorn/awesome-zsh-plugins)
- [Starship Prompt](https://starship.rs/)
- [fzf — Fuzzy Finder](https://github.com/junegunn/fzf)
- [direnv](https://direnv.net/)

---

## License

MIT — Use, modify, and share freely.

---

**Questions?** Open an [issue](https://github.com/nandordudas/zsh-config/issues) on GitHub.
