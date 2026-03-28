# Custom functions for common tasks and workflows

# =============================================================================
# DIRECTORY & FILE OPERATIONS
# =============================================================================

# Create directory and cd into it
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract archives (universal)
extract() {
  if [[ ! -f "$1" ]]; then
    echo "File not found: $1"
    return 1
  fi

  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.7z)      7z x "$1" ;;
    *)         echo "Unknown archive format: $1"; return 1 ;;
  esac
}

# =============================================================================
# PRODUCTIVITY
# =============================================================================

# Quick confirm for destructive operations
confirm() {
  local response
  printf "%s [y/N] " "$1"
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
}

# Bootstrap new Git project
bootstrap() {
  local folder_name="${1:-$(tr -dc 'a-z0-9' </dev/urandom | head -c 13)}"
  mkcd "${folder_name}" && git bootstrap || return 1
  cr
}

# =============================================================================
# PROCESS MANAGEMENT
# =============================================================================

# Interactive process killer with fzf
interactive_kill() {
  local pids

  pids=$(
    command ps aux | tail -n +2 \
      | fzf --multi \
            --header="$(command ps aux | head -1)" \
            --header-lines=0 \
            --preview="echo {}" \
            --preview-window=down:2:wrap \
      | awk '{print $2}'
  )

  [[ -z "$pids" ]] && return 0

  print -l $=pids | xargs kill -15
  printf "✓ Killed PIDs: %s\n" "${pids//$'\n'/ }"
}

# =============================================================================
# SYSTEM UPGRADES & MAINTENANCE
# =============================================================================

# Comprehensive system upgrade function
upgrade() {
  # --- System Packages ---
  printf "🔄 Updating package lists...\n"
  sudo apt update || return 1

  printf "📦 Upgrading packages...\n"
  sudo apt-get upgrade -y --autoremove --purge || return 1

  printf "🧹 Cleaning up...\n"
  sudo apt-get autoclean

  printf "✅ System upgraded successfully\n"

  # --- Zsh Plugins (via zinit) ---
  if (( ${+functions[zinit]} )); then
    printf "🔌 Updating zsh plugins...\n"
    zinit self-update --quiet
    zinit update --all --quiet
  fi

  # --- Rust ---
  if command -v rustup &> /dev/null; then
    printf "🦀 Updating Rust...\n"
    rustup update
  fi

  if command -v cargo &> /dev/null; then
    printf "📦 Updating global Cargo packages...\n"
    cargo install-update -a 2>&1 | tee /tmp/cargo-update.log || true
  fi

  # --- Claude CLI ---
  if command -v claude &> /dev/null; then
    printf "🤖 Updating Claude CLI...\n"
    claude update
  fi

  # --- Go (via g) ---
  if command -v "$HOME/go/bin/g" &> /dev/null; then
    printf "🐹 Checking Go versions...\n"

    local LOCAL_GO REMOTE_GO
    # Get local version (strips 'go' prefix) -> "1.26.0"
    LOCAL_GO=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')

    # Single API call — much faster than `g list-all` which fetches every version
    REMOTE_GO=$(curl -sf 'https://go.dev/VERSION?m=text' 2>/dev/null | head -1 | sed 's/go//')

    if [[ -n "$REMOTE_GO" ]] && [[ "$LOCAL_GO" != "$REMOTE_GO" ]]; then
      printf "⬇️  Updating Go to %s (current: %s)...\n" "$REMOTE_GO" "$LOCAL_GO"
      "$HOME/go/bin/g" install latest && "$HOME/go/bin/g" use latest  # FIXED: use instead of set
    else
      printf "✅ Go is already up to date (%s)\n" "$LOCAL_GO"
    fi
  fi

  # --- Node.js (via fnm) ---
  # fnm install --lts is idempotent: skips install if already on latest LTS.
  # npm install --global is also idempotent: skips packages already at latest.
  # Both approaches avoid slow remote version-list fetches (fnm ls-remote, npm outdated).
  if command -v fnm &> /dev/null; then
    printf "🟩 Updating Node.js LTS...\n"
    fnm install --lts && fnm default lts-latest

    printf "📦 Updating global npm packages...\n"
    npm install --global npm@latest pnpm@latest @antfu/ni eslint taze npkill
  fi

  # --- Summary ---
  printf "\n📋 Installed versions:\n"
  printf "  %-12s %s\n" "OS:"     "$(lsb_release -ds 2>/dev/null)"
  printf "  %-12s %s\n" "Kernel:" "$(uname -r)"
  printf "  %-12s %s\n" "Go:"     "$(go version 2>/dev/null | awk '{print $3}' || echo 'not found')"
  printf "  %-12s %s\n" "Rust:"   "$(rustc --version 2>/dev/null | awk '{print $2}' || echo 'not found')"
  printf "  %-12s %s\n" "Cargo:"  "$(cargo --version 2>/dev/null | awk '{print $2}' || echo 'not found')"
  printf "  %-12s %s\n" "Node:"   "$(node --version 2>/dev/null || echo 'not found')"
  printf "  %-12s %s\n" "npm:"    "$(npm --version 2>/dev/null || echo 'not found')"
  printf "  %-12s %s\n" "Claude:" "$(claude --version 2>/dev/null || echo 'not found')"
  printf "  %-12s %s\n" "Docker:" "$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo 'not found')"
  printf "  %-12s %s\n" "Git:"    "$(git --version 2>/dev/null | awk '{print $3}' || echo 'not found')"

  printf "🎉 All done!\n"
}

# =============================================================================
# GIT HELPERS
# =============================================================================

# FZF git checkout helper (quick alternative to forgit)
gc() {
  local branch
  branch=$(git branch --all | fzf | sed 's/^[* ] *//')
  [[ -n "$branch" ]] && git checkout "$branch"
}

# =============================================================================
# CACHE MANAGEMENT
# =============================================================================

# Force regeneration of all eval caches on next shell start.
# Useful when auto-invalidation via mtime doesn't trigger (e.g., manual edits).
zsh-cache-clear() {
  local cache_dir="$XDG_CACHE_HOME/zsh"
  local removed=0
  for f in starship.zsh zoxide.zsh fnm.zsh direnv.zsh; do
    if [[ -f "$cache_dir/$f" ]]; then
      rm "$cache_dir/$f"
      (( removed++ ))
      print "Removed: $cache_dir/$f"
    fi
  done
  print "Cleared $removed cache file(s). Restart shell to regenerate."
}
