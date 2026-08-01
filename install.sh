#!/usr/bin/env bash
# install.sh — one-command setup for zsh-config on macOS.
#
# Supports Apple Silicon (M-series) and Intel Macs via Homebrew.
#
# Usage:
#   git clone https://github.com/nandordudas/zsh-config ~/.config/zsh
#   ~/.config/zsh/install.sh                  # full install
#
# Options:
#   --minimal           Core tools only (skip dev toolchains: mise, rustup)
#   --config-only       Only set up config files, install no packages
#   --yes, -y           Don't ask for confirmation
#   --git-name  NAME    Also run scripts/git-setup.sh with this name
#   --git-email EMAIL   ... and this email (both required to run git-setup)
#   --help, -h          Show this help
#
# Idempotent: safe to re-run. Existing ~/.zshenv is backed up before overwrite.

set -euo pipefail

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

info()  { printf "%s▸%s %s\n" "$GREEN" "$RESET" "$1"; }
warn()  { printf "%s⊙%s %s\n" "$YELLOW" "$RESET" "$1"; }
error() { printf "%s✗%s %s\n" "$RED" "$RESET" "$1" >&2; }
step()  { printf "\n%s━━ %s ━━%s\n" "$BOLD" "$1" "$RESET"; }

usage() {
  cat << 'EOF'
install.sh — one-command setup for zsh-config on macOS.

Supports Apple Silicon (M-series) and Intel Macs via Homebrew.
Packages are declared in Brewfile (core) and Brewfile.dev (toolchains).

Usage:
  git clone https://github.com/nandordudas/zsh-config ~/.config/zsh
  ~/.config/zsh/install.sh                  # full install

Options:
  --minimal           Core tools only (skip Brewfile.dev: mise, rustup)
  --config-only       Only set up config files, install no packages
  --yes, -y           Don't ask for confirmation
  --git-name  NAME    Also run scripts/git-setup.sh with this name
  --git-email EMAIL   ... and this email (both required to run git-setup)
  --help, -h          Show this help

Idempotent: safe to re-run. Existing ~/.zshenv is backed up before overwrite.
EOF
}

# -----------------------------------------------------------------------------
# Arguments
# -----------------------------------------------------------------------------
MINIMAL=0
CONFIG_ONLY=0
ASSUME_YES=0
GIT_NAME=""
GIT_EMAIL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minimal)     MINIMAL=1; shift ;;
    --config-only) CONFIG_ONLY=1; shift ;;
    --yes|-y)      ASSUME_YES=1; shift ;;
    --git-name)    GIT_NAME="$2"; shift 2 ;;
    --git-email)   GIT_EMAIL="$2"; shift 2 ;;
    --help|-h)     usage; exit 0 ;;
    *) error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

confirm() {
  (( ASSUME_YES )) && return 0
  local reply
  printf "%s [y/N] " "$1"
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# Platform check
# -----------------------------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]] && (( ! CONFIG_ONLY )); then
  error "This config targets macOS. Detected: $(uname -s)"
  error "On other systems you can still set up the config files only:"
  error "  $0 --config-only"
  exit 1
fi

ARCH="$(uname -m)"

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ZSH_DIR="$XDG_CONFIG_HOME/zsh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/nandordudas/zsh-config"

# -----------------------------------------------------------------------------
# Plan summary
# -----------------------------------------------------------------------------
step "zsh-config installer"
if [[ "$(uname -s)" == "Darwin" ]]; then
  info "Platform: macOS $(sw_vers -productVersion 2>/dev/null) $ARCH$( [[ "$ARCH" == "arm64" ]] && echo ' (Apple Silicon)' )"
fi
(( MINIMAL ))     && info "Mode: minimal (core tools only)"
(( CONFIG_ONLY )) && info "Mode: config-only (no packages will be installed)"
info "Config dir: $ZSH_DIR"

if ! confirm "Proceed with installation?"; then
  echo "Cancelled."
  exit 0
fi

# -----------------------------------------------------------------------------
# Package installation (Homebrew + Brewfile)
# -----------------------------------------------------------------------------
# Put brew in PATH for this script, wherever it lives
brew_env() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$b" ]] || continue
    # Confirm brew is really callable afterwards. If `shellenv` fails the
    # command substitution is empty, `eval ""` succeeds, and a bare
    # `&& return 0` would report success with brew still absent from PATH.
    eval "$("$b" shellenv)" 2>/dev/null
    command -v brew &>/dev/null && return 0
  done
  return 1
}

if (( ! CONFIG_ONLY )); then
  step "Homebrew"
  if ! command -v brew &>/dev/null && ! brew_env; then
    info "Installing Homebrew (you may be prompted for your password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_env || { error "Homebrew installation failed"; exit 1; }
  fi
  info "Homebrew: $(brew --version | head -1)"

  step "Core packages (Brewfile)"
  # Declarative package list — see Brewfile for the annotated set.
  # All bottles are native arm64 on Apple Silicon.
  #
  # Non-fatal on purpose. Under `set -e` a single renamed cask or transient
  # download failure here would abort the installer before ANY config file is
  # written, which on a fresh machine is the worst possible outcome: no shell
  # config and no ~/.zshenv. Warn and carry on to the config step instead.
  brew bundle --file="$SCRIPT_DIR/Brewfile" \
    || warn "some core packages failed — re-run: brew bundle --file=$SCRIPT_DIR/Brewfile"

  if (( ! MINIMAL )); then
    step "Dev toolchains (Brewfile.dev)"
    brew bundle --file="$SCRIPT_DIR/Brewfile.dev" \
      || warn "some dev toolchains failed — re-run: brew bundle --file=$SCRIPT_DIR/Brewfile.dev"

    # Set up the rustup MANAGER only — no global toolchain. A project with a
    # rust-toolchain.toml auto-installs its pinned toolchain on first build.
    # For ad-hoc rust outside projects: `rustup default stable` (one-time).
    if command -v rustup-init &>/dev/null && [[ ! -d "$HOME/.rustup" ]]; then
      info "Initializing rustup (no global toolchain — rust is per-project)..."
      rustup-init -y --no-modify-path --default-toolchain none \
        || warn "rustup-init failed — run it manually later"
    fi

    # Node is the only GLOBAL runtime — always-on tools (ccstatusline, taze, …)
    # need it. Go/Python/etc. are per-project: run `mise use go@1.24` inside a
    # project to pin and install on demand (writes .mise.toml).
    #
    # ~/.default-npm-packages: mise auto-installs these into EVERY node version
    # it installs, so global npm tools survive node upgrades and switches.
    if [[ ! -f "$HOME/.default-npm-packages" ]]; then
      cat > "$HOME/.default-npm-packages" << 'EOF'
pnpm
@antfu/ni
taze
npkill
ccstatusline
eslint
EOF
      info "Created ~/.default-npm-packages (auto-installed with every node version)"
    fi

    info "Installing Node.js LTS via mise..."
    if mise use --global node@lts; then
      # Ensure globals exist even when node was already installed before
      # the default-packages file was created (re-runs, upgrades).
      # Read into an array — quoting the whole xargs output would pass all
      # packages to npm as a single argument.
      NPM_GLOBALS=()
      while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && NPM_GLOBALS+=("$pkg")
      done < "$HOME/.default-npm-packages"
      if (( ${#NPM_GLOBALS[@]} )); then
        mise exec -- npm install --global "${NPM_GLOBALS[@]}" \
          || warn "npm globals failed — run: npm i -g \$(xargs < ~/.default-npm-packages)"
      fi
    else
      warn "mise install failed — run 'mise use -g node@lts' later"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# Config files
# -----------------------------------------------------------------------------
step "Config files"

# 1. Make sure the repo lives at ~/.config/zsh
if [[ "$SCRIPT_DIR" != "$ZSH_DIR" ]]; then
  if [[ -d "$ZSH_DIR/.git" ]]; then
    info "Config already cloned at $ZSH_DIR"
  elif [[ -e "$ZSH_DIR" ]]; then
    warn "$ZSH_DIR exists but is not this repo — backing up to ${ZSH_DIR}.bak"
    mv "$ZSH_DIR" "${ZSH_DIR}.bak"
    git clone "$REPO_URL" "$ZSH_DIR"
  else
    info "Cloning config to $ZSH_DIR"
    mkdir -p "$XDG_CONFIG_HOME"
    git clone "$REPO_URL" "$ZSH_DIR"
  fi
fi

# 2. ~/.zshenv — the only file outside the repo; points zsh at ZDOTDIR
ZSHENV="$HOME/.zshenv"
ZSHENV_CONTENT='# ~/.zshenv — generated by zsh-config install.sh
# Sourced for EVERY zsh invocation. Keep minimal: only directory env vars.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Tell zsh to look for dotfiles in ~/.config/zsh instead of ~
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"'

if [[ -f "$ZSHENV" ]] && ! grep -q 'ZDOTDIR="\$XDG_CONFIG_HOME/zsh"' "$ZSHENV"; then
  warn "Existing ~/.zshenv backed up to ~/.zshenv.bak"
  cp "$ZSHENV" "$ZSHENV.bak"
fi
printf '%s\n' "$ZSHENV_CONTENT" > "$ZSHENV"
info "Wrote ~/.zshenv"

# 3. Interactive mode state (persists user preference for starship prompt)
ZSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "$ZSH_STATE_DIR"
if [[ ! -f "$ZSH_STATE_DIR/interactive-mode" ]]; then
  echo "on" > "$ZSH_STATE_DIR/interactive-mode"
  info "Created zsh state directory and interactive-mode toggle"
else
  info "interactive-mode toggle already exists — kept"
fi

# 4. Machine-local overrides (gitignored)
if [[ ! -f "$ZSH_DIR/modules/local.zsh" ]]; then
  cat > "$ZSH_DIR/modules/local.zsh" << 'EOF'
# Machine-local zsh config (gitignored — safe for secrets and machine quirks)
# export GITHUB_USER="yourname"
# export BITBUCKET_USER="yourname"

# Machine-specific PATH entries and tool env vars go here, not in the
# committed .zshrc:
# export PATH="$HOME/some/local/bin:$PATH"
EOF
  info "Created modules/local.zsh"
else
  info "modules/local.zsh already exists — kept"
fi

# 5. herdr config symlink (back up an existing real file first)
mkdir -p "$XDG_CONFIG_HOME/herdr"
HERDR_CONF="$XDG_CONFIG_HOME/herdr/config.toml"
if [[ -f "$HERDR_CONF" && ! -L "$HERDR_CONF" ]]; then
  warn "Existing herdr config.toml backed up to config.toml.bak"
  mv "$HERDR_CONF" "$HERDR_CONF.bak"
fi
ln -sf "$ZSH_DIR/herdr/config.toml" "$HERDR_CONF"
info "Linked herdr config"

# 5a. Claude Code <-> herdr native integration (agent state hook).
# Requires both CLIs present; ~/.claude must exist before `herdr integration install`.
if command -v herdr &>/dev/null && command -v claude &>/dev/null; then
  mkdir -p "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  if herdr integration install claude &>/dev/null; then
    info "Installed herdr's Claude Code integration (agent state hook)"
  else
    warn "herdr integration install claude failed — run it manually later"
  fi
fi

# 5b. alacritty config — create a local wrapper that imports the versioned base.
#     A real file (not a symlink) so local overrides placed after the import win.
mkdir -p "$XDG_CONFIG_HOME/alacritty"
ALACRITTY_CONF="$XDG_CONFIG_HOME/alacritty/alacritty.toml"
ALACRITTY_BASE="$ZSH_DIR/alacritty/alacritty.toml"
if [[ -L "$ALACRITTY_CONF" ]]; then
  rm "$ALACRITTY_CONF"    # remove old symlink; replace with real local wrapper
elif [[ -f "$ALACRITTY_CONF" ]] && ! grep -q "zsh/alacritty/alacritty.toml" "$ALACRITTY_CONF"; then
  warn "Existing alacritty.toml backed up to alacritty.toml.bak"
  mv "$ALACRITTY_CONF" "$ALACRITTY_CONF.bak"
fi
if [[ ! -f "$ALACRITTY_CONF" ]]; then
  cat > "$ALACRITTY_CONF" << EOF
# ~/.config/alacritty/alacritty.toml — local, not committed to the repo
# Imports the shared base config; settings added below override the base.
#
# The import path below is ABSOLUTE and was baked in when install.sh ran.
# Moving or renaming the config repo breaks alacritty (it starts with defaults
# and no error) until you re-run install.sh or edit the path by hand.

[general]
import = [
  "$ALACRITTY_BASE",
]

# Example machine-local overrides — anything here wins over the base:
# [font]
# size = 14.0
#
# [window]
# opacity = 0.95
EOF
  info "Created alacritty local wrapper (imports base config)"
else
  info "alacritty local wrapper already exists — kept"
fi

# 5c. starship config symlink (back up an existing real file first)
mkdir -p "$XDG_CONFIG_HOME"
STARSHIP_CONF="$XDG_CONFIG_HOME/starship.toml"
if [[ -f "$STARSHIP_CONF" && ! -L "$STARSHIP_CONF" ]]; then
  warn "Existing starship.toml backed up to starship.toml.bak"
  mv "$STARSHIP_CONF" "$STARSHIP_CONF.bak"
fi
ln -sf "$ZSH_DIR/starship/starship.toml" "$STARSHIP_CONF"
info "Linked starship config"

# 6. Project root for gg/gb aliases and freespace
mkdir -p "$HOME/Development/code"
touch "$HOME/Development/.metadata_never_index"
info "Project root: ~/Development/code (override CODE_DIR in modules/local.zsh)"
info "Spotlight indexing disabled for ~/Development (.metadata_never_index)"

# 7. Git identity + SSH signing (optional)
if [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
  step "Git setup (SSH signing)"
  bash "$ZSH_DIR/scripts/git-setup.sh" --name "$GIT_NAME" --email "$GIT_EMAIL"
elif [[ -n "$GIT_NAME$GIT_EMAIL" ]]; then
  warn "Both --git-name and --git-email are required to run git-setup — skipped"
fi

# -----------------------------------------------------------------------------
# Default shell (macOS ships zsh as default since Catalina)
# -----------------------------------------------------------------------------
step "Default shell"
if [[ "${SHELL:-}" == *zsh* ]]; then
  info "Default shell is already zsh"
else
  ZSH_BIN="$(command -v zsh)"
  if confirm "Change default shell to $ZSH_BIN?"; then
    chsh -s "$ZSH_BIN" || warn "chsh failed — run manually: chsh -s $ZSH_BIN"
  else
    info "Skipped. Run later: chsh -s $ZSH_BIN"
  fi
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
step "Done"
printf '%s\n' "
${GREEN}✓ zsh-config installed${RESET}

Next steps:
  1. Open a NEW terminal (first start downloads Zinit plugins, ~1-2 min)
  2. Run ${BOLD}zsh-health${RESET} to verify everything works
  3. Edit ${BOLD}$ZSH_DIR/modules/local.zsh${RESET} for machine-specific settings

To undo everything later: ${BOLD}$ZSH_DIR/uninstall.sh${RESET} (one confirmation, restores backups)"

if [[ -z "$GIT_NAME" ]]; then
  printf '%s\n' "  4. Optional — git identity + SSH commit signing:
     ${BOLD}$ZSH_DIR/scripts/git-setup.sh --name \"Your Name\" --email \"you@example.com\"${RESET}"
fi
echo
