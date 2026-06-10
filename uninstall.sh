#!/usr/bin/env bash
# uninstall.sh — undo what install.sh did, restoring backed-up originals.
#
# One confirmation, then:
#   - ~/.zshenv          → restored from ~/.zshenv.bak if present, else removed
#   - tmux.conf symlink  → removed; tmux.conf.bak restored if present
#   - ~/.config/zsh      → moved to ~/.config/zsh.uninstalled (kept, not deleted)
#   - zsh caches/state   → removed (~/.cache/zsh, zinit plugins)
#
# NOT touched: Homebrew packages, mise runtimes, npm globals
# (~/.default-npm-packages), git config, SSH keys, history.
# To also remove packages afterwards: brew bundle cleanup --file=Brewfile
#
# Usage:
#   ~/.config/zsh/uninstall.sh        # asks once
#   ~/.config/zsh/uninstall.sh -y     # no questions

set -euo pipefail

GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
info() { printf "%s▸%s %s\n" "$GREEN" "$RESET" "$1"; }
warn() { printf "%s⊙%s %s\n" "$YELLOW" "$RESET" "$1"; }

ASSUME_YES=0
[[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]] && ASSUME_YES=1

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
ZSH_DIR="$XDG_CONFIG_HOME/zsh"
TMUX_CONF="$XDG_CONFIG_HOME/tmux/tmux.conf"

printf "%s━━ zsh-config uninstaller ━━%s\n\n" "$BOLD" "$RESET"
printf "This will:\n"
printf "  • restore ~/.zshenv from backup (or remove it)\n"
printf "  • remove the tmux config symlink (restore backup if present)\n"
printf "  • move %s to %s.uninstalled (kept as backup)\n" "$ZSH_DIR" "$ZSH_DIR"
printf "  • clear zsh caches and zinit plugins\n"
printf "\nKept untouched: brew packages, mise runtimes, npm globals, git config, SSH keys, shell history.\n\n"

if (( ! ASSUME_YES )); then
  printf "Proceed? [y/N] "
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
fi

# 1. ~/.zshenv — restore the pre-install original if we backed one up
if [[ -f "$HOME/.zshenv.bak" ]]; then
  mv "$HOME/.zshenv.bak" "$HOME/.zshenv"
  info "Restored original ~/.zshenv from backup"
elif [[ -f "$HOME/.zshenv" ]]; then
  rm "$HOME/.zshenv"
  info "Removed ~/.zshenv"
fi

# 2. tmux config — only remove the symlink if it points into this repo
if [[ -L "$TMUX_CONF" && "$(readlink "$TMUX_CONF")" == "$ZSH_DIR"* ]]; then
  rm "$TMUX_CONF"
  info "Removed tmux config symlink"
  if [[ -f "$TMUX_CONF.bak" ]]; then
    mv "$TMUX_CONF.bak" "$TMUX_CONF"
    info "Restored original tmux.conf from backup"
  fi
elif [[ -e "$TMUX_CONF" ]]; then
  warn "$TMUX_CONF is not this repo's symlink — left untouched"
fi

# 3. Config repo — keep as a backup instead of deleting (local.zsh may hold secrets)
if [[ -d "$ZSH_DIR" ]]; then
  rm -rf "$ZSH_DIR.uninstalled"
  mv "$ZSH_DIR" "$ZSH_DIR.uninstalled"
  info "Moved $ZSH_DIR → $ZSH_DIR.uninstalled (delete it when you're sure)"
fi

# 4. Caches and plugin state (regenerable, safe to delete)
rm -rf "$XDG_CACHE_HOME/zsh" "$XDG_DATA_HOME/zinit" "$XDG_STATE_HOME/zsh"
info "Cleared zsh caches and zinit plugins"

printf "\n%s✓ Uninstalled.%s Open a new terminal — you're back on stock macOS zsh.\n" "$GREEN" "$RESET"
printf "Shell history was kept at %s/zsh/history.\n" "$XDG_DATA_HOME"
printf "To remove brew packages too: brew bundle cleanup --file=%s.uninstalled/Brewfile\n" "$ZSH_DIR"
