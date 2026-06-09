#!/usr/bin/env bash
# install.sh — one-command setup for zsh-config.
#
# Supported platforms:
#   - macOS (Apple Silicon & Intel) via Homebrew
#   - Ubuntu / Debian (native or WSL2) via apt + cargo
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

usage() { sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; }

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
# Platform detection
# -----------------------------------------------------------------------------
OS=""
ARCH="$(uname -m)"

case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    if [[ -r /etc/os-release ]] && grep -qiE 'debian|ubuntu' /etc/os-release; then
      OS="debian"
    else
      OS="linux-other"
    fi
    ;;
  *) OS="unsupported" ;;
esac

IS_WSL=0
if [[ "$OS" == "debian" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=1
fi

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
case "$OS" in
  macos)  info "Platform: macOS $ARCH $( [[ "$ARCH" == "arm64" ]] && echo '(Apple Silicon)' )" ;;
  debian) info "Platform: Ubuntu/Debian$( (( IS_WSL )) && echo ' (WSL2)' )" ;;
  *)
    error "Unsupported platform: $(uname -s)"
    error "Manual setup: install zsh, git, fzf, bat, fd, ripgrep, eza, zoxide,"
    error "starship, direnv, then run: $0 --config-only"
    exit 1
    ;;
esac
(( MINIMAL ))     && info "Mode: minimal (core tools only)"
(( CONFIG_ONLY )) && info "Mode: config-only (no packages will be installed)"
info "Config dir: $ZSH_DIR"

if ! confirm "Proceed with installation?"; then
  echo "Cancelled."
  exit 0
fi

# -----------------------------------------------------------------------------
# Package installation
# -----------------------------------------------------------------------------
install_macos() {
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
  # Everything that this config uses comes straight from brew on macOS —
  # no cargo builds needed, all bottles are native arm64.
  local -a core=(
    git tmux fzf bat fd ripgrep eza zoxide starship direnv gh
    git-delta dust duf procs sevenzip
  )
  brew install "${core[@]}"

  if (( ! MINIMAL )); then
    step "Dev toolchains (brew)"
    local -a dev=(fnm go fastfetch)
    brew install "${dev[@]}"

    if ! command -v rustup &>/dev/null && [[ ! -f "$HOME/.cargo/env" ]]; then
      info "Installing Rust via rustup..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    fi

    info "Installing Node.js LTS via fnm..."
    fnm install --lts && fnm default lts-latest || warn "fnm install failed — run 'fnm install --lts' later"
  fi
}

install_debian() {
  step "System packages (apt)"
  sudo apt-get update -qq
  sudo apt-get install -y \
    zsh git tmux curl wget unzip ca-certificates \
    bat fd-find ripgrep zoxide p7zip-full
  # Optional packages that may not exist on older releases
  sudo apt-get install -y duf exiftool 2>/dev/null || true

  step "Starship prompt"
  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  step "direnv"
  if ! command -v direnv &>/dev/null; then
    curl -sfL https://direnv.net/install.sh | bash
  fi

  step "fzf (git install for latest version)"
  if [[ ! -d "$HOME/.fzf" ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
  fi

  step "GitHub CLI"
  if ! command -v gh &>/dev/null; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -qq && sudo apt-get install -y gh
  fi

  if (( ! MINIMAL )); then
    step "Rust toolchain + cargo tools"
    if ! command -v cargo &>/dev/null && [[ ! -f "$HOME/.cargo/env" ]]; then
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    fi
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
    info "Building cargo tools (this takes a while on first install)..."
    cargo install eza git-delta du-dust procs fnm cargo-update

    step "Node.js (fnm)"
    fnm install --lts && fnm default lts-latest || warn "fnm install failed — run 'fnm install --lts' later"

    step "Go (g version manager)"
    if [[ ! -x "$HOME/go/bin/g" ]]; then
      curl -sSL https://raw.githubusercontent.com/stefanmaric/g/master/bin/install | \
        GOPATH="$HOME/go" GOROOT="$HOME/.go" bash -s -- -y || warn "Go install failed — see README"
    fi
  else
    step "git-delta (minimal mode)"
    if ! command -v delta &>/dev/null; then
      if ! command -v cargo &>/dev/null && [[ ! -f "$HOME/.cargo/env" ]]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
      fi
      # shellcheck disable=SC1091
      source "$HOME/.cargo/env"
      cargo install git-delta eza
    fi
  fi
}

if (( ! CONFIG_ONLY )); then
  case "$OS" in
    macos)  install_macos ;;
    debian) install_debian ;;
  esac
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
# Default shell
# -----------------------------------------------------------------------------
step "Default shell"
ZSH_BIN="$(command -v zsh || true)"
if [[ -z "$ZSH_BIN" ]]; then
  warn "zsh not found in PATH — install it and re-run"
elif [[ "${SHELL:-}" == *zsh* ]]; then
  info "Default shell is already zsh"
else
  if ! grep -q "$ZSH_BIN" /etc/shells 2>/dev/null; then
    warn "$ZSH_BIN is not in /etc/shells — adding requires sudo"
    echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null || true
  fi
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
