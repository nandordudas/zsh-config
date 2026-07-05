#!/usr/bin/env bash
# uninstall.sh — undo what install.sh did, restoring backed-up originals.
#
# One confirmation, then:
#   - dark-notify process   → stopped
#   - ~/.zshenv             → restored from ~/.zshenv.bak if present, else removed
#   - herdr config symlink  → removed; config.toml.bak restored if present
#   - herdr Claude Code integration → uninstalled if herdr is present
#   - alacritty wrapper   → removed (or restored from .bak); theme.toml removed
#   - ~/.config/zsh       → moved to ~/.config/zsh.uninstalled (kept, not deleted)
#   - zsh caches/state    → removed (~/.cache/zsh, zinit plugins)
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
HERDR_CONF="$XDG_CONFIG_HOME/herdr/config.toml"

printf "%s━━ zsh-config uninstaller ━━%s\n\n" "$BOLD" "$RESET"
printf "This will:\n"
printf "  • restore ~/.zshenv from backup (or remove it)\n"
printf "  • remove the herdr config symlink (restore backup if present)\n"
printf "  • uninstall herdr's Claude Code integration, if herdr is present\n"
printf "  • remove the alacritty local wrapper (restore backup if present)\n"
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

# 2. herdr config — only remove the symlink if it points into this repo
if [[ -L "$HERDR_CONF" && "$(readlink "$HERDR_CONF")" == "$ZSH_DIR"* ]]; then
  rm "$HERDR_CONF"
  info "Removed herdr config symlink"
  if [[ -f "$HERDR_CONF.bak" ]]; then
    mv "$HERDR_CONF.bak" "$HERDR_CONF"
    info "Restored original config.toml from backup"
  fi
elif [[ -e "$HERDR_CONF" ]]; then
  warn "$HERDR_CONF is not this repo's symlink — left untouched"
fi

# 2b. herdr's Claude Code integration (agent state hook) — uninstall if herdr is present
if command -v herdr &>/dev/null && herdr integration uninstall claude &>/dev/null; then
  info "Uninstalled herdr's Claude Code integration"
fi

# 3. alacritty wrapper — remove if install.sh created it (imports this repo's base)
ALACRITTY_CONF="$XDG_CONFIG_HOME/alacritty/alacritty.toml"
if [[ -f "$ALACRITTY_CONF" ]] && grep -q "zsh/alacritty/alacritty.toml" "$ALACRITTY_CONF"; then
  if [[ -f "$ALACRITTY_CONF.bak" ]]; then
    mv "$ALACRITTY_CONF.bak" "$ALACRITTY_CONF"
    info "Restored original alacritty.toml from backup"
  else
    rm "$ALACRITTY_CONF"
    info "Removed alacritty local wrapper"
  fi
fi

# 5. Config repo — keep as a backup instead of deleting (local.zsh may hold secrets)
if [[ -d "$ZSH_DIR" ]]; then
  rm -rf "$ZSH_DIR.uninstalled"
  mv "$ZSH_DIR" "$ZSH_DIR.uninstalled"
  info "Moved $ZSH_DIR → $ZSH_DIR.uninstalled (delete it when you're sure)"
fi

# 6. Caches and plugin state (regenerable, safe to delete)
rm -rf "$XDG_CACHE_HOME/zsh" "$XDG_DATA_HOME/zinit" "$XDG_STATE_HOME/zsh"
info "Cleared zsh caches and zinit plugins"

printf "\n%s✓ Uninstalled.%s Open a new terminal — you're back on stock macOS zsh.\n" "$GREEN" "$RESET"
printf "Shell history was kept at %s/zsh/history.\n" "$XDG_DATA_HOME"
printf "To remove brew packages too: brew bundle cleanup --file=%s.uninstalled/Brewfile\n" "$ZSH_DIR"
