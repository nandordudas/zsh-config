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
#   --minimal           Core tools only (skip Rust/Go/Node toolchains)
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

usage() { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; }

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
# Package installation (Homebrew)
# -----------------------------------------------------------------------------
if (( ! CONFIG_ONLY )); then
  step "Homebrew"
  if ! command -v brew &>/dev/null; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      info "Installing Homebrew (you may be prompted for your password)..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      else
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    fi
  fi
  info "Homebrew: $(brew --version | head -1)"

  step "Core packages (brew)"
  # Everything this config uses comes straight from brew —
  # all bottles are native arm64 on Apple Silicon.
  core=(
    git tmux fzf bat fd ripgrep eza zoxide starship direnv gh
    git-delta dust duf procs sevenzip
  )
  brew install "${core[@]}"

  if (( ! MINIMAL )); then
    step "Dev toolchains (brew)"
    dev=(fnm go fastfetch)
    brew install "${dev[@]}"

    if ! command -v rustup &>/dev/null && [[ ! -f "$HOME/.cargo/env" ]]; then
      info "Installing Rust via rustup..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    fi

    info "Installing Node.js LTS via fnm..."
    fnm install --lts && fnm default lts-latest || warn "fnm install failed — run 'fnm install --lts' later"
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

# 3. Machine-local overrides (gitignored)
if [[ ! -f "$ZSH_DIR/modules/local.zsh" ]]; then
  cat > "$ZSH_DIR/modules/local.zsh" << 'EOF'
# Machine-local zsh config (gitignored — safe for secrets and machine quirks)
# export GITHUB_USER="yourname"
# export BITBUCKET_USER="yourname"
EOF
  info "Created modules/local.zsh"
else
  info "modules/local.zsh already exists — kept"
fi

# 4. tmux config symlink
mkdir -p "$XDG_CONFIG_HOME/tmux"
ln -sf "$ZSH_DIR/tmux/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"
info "Linked tmux config"

# 5. Git identity + SSH signing (optional)
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
  3. Edit ${BOLD}$ZSH_DIR/modules/local.zsh${RESET} for machine-specific settings"

if [[ -z "$GIT_NAME" ]]; then
  printf '%s\n' "  4. Optional — git identity + SSH commit signing:
     ${BOLD}$ZSH_DIR/scripts/git-setup.sh --name \"Your Name\" --email \"you@example.com\"${RESET}"
fi
echo
