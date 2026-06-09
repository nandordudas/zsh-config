# Custom functions for common tasks and workflows

[[ -n "$__functions_zsh_loaded" ]] && return
__functions_zsh_loaded=1

# $EPOCHSECONDS (used by upgrade) requires the datetime module
zmodload zsh/datetime 2>/dev/null

# =============================================================================
# ENVIRONMENT HELPERS
# =============================================================================

# Centralized XDG cache directory with fallback
_zcache_dir() {
  echo "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
}

# Centralized XDG data directory with fallback
_zdata_dir() {
  echo "${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
}

# Get interactive mode state file
_zinteractive_state_file() {
  echo "${XDG_STATE_HOME:-$HOME/.local/state}/zsh/interactive-mode"
}

# =============================================================================
# INTERACTIVE MODE TOGGLE
# =============================================================================

# Toggle Starship + Zinit on/off for interactive vs. headless use
# Usage: toggle_interactive [on|off]
toggle_interactive() {
  local state="${1:-}"
  local state_file
  state_file=$(_zinteractive_state_file)

  if [[ -z "$state" ]]; then
    local current=$(<"$state_file" 2>/dev/null || echo "on")
    printf "Interactive mode is currently: %s\n" "$current"
    printf "Usage: toggle_interactive [on|off]\n" >&2
    return 0
  fi

  case "$state" in
    on|off)
      mkdir -p "$(dirname "$state_file")"
      printf "%s" "$state" >"$state_file"
      printf "Interactive mode: %s\nReloading shell...\n" "$state"
      sleep 0.5
      exec zsh
      ;;
    *)
      printf "Usage: toggle_interactive [on|off]\n" >&2
      return 1
      ;;
  esac
}

# =============================================================================
# COLOR CODES (for consistent output styling)
# =============================================================================

readonly _COLOR_RESET=$'\033[0m'
readonly _COLOR_GREEN=$'\033[32m'
readonly _COLOR_RED=$'\033[31m'
readonly _COLOR_YELLOW=$'\033[33m'
readonly _COLOR_DIM=$'\033[2m'

# =============================================================================
# DIRECTORY & FILE OPERATIONS
# =============================================================================

# Create directory and cd into it
mkcd() {
  [[ -n "$1" ]] || { printf "Usage: mkcd <dir>\n" >&2; return 1; }
  mkdir -p "$1" || { printf "Error: Failed to create directory: %s\n" "$1" >&2; return 1; }
  cd "$1" || return 1
}

# Extract archives (universal)
# .7z/.rar use 7zz (brew sevenzip); falls back to 7z/unrar if installed instead.
extract() {
  [[ $# -eq 1 ]] || { printf "Usage: extract <archive>\n" >&2; return 1; }
  [[ -f "$1" ]] || { printf "Error: File not found: %s\n" "$1" >&2; return 1; }

  local sevenzip
  sevenzip="${commands[7zz]:-${commands[7z]}}"

  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.rar)
      if (( $+commands[unrar] )); then
        unrar x "$1"
      elif [[ -n "$sevenzip" ]]; then
        "$sevenzip" x "$1"
      else
        printf "Error: need 7zz (brew install sevenzip) or unrar for .rar\n" >&2; return 1
      fi
      ;;
    *.7z)
      if [[ -n "$sevenzip" ]]; then
        "$sevenzip" x "$1"
      else
        printf "Error: need 7zz (brew install sevenzip) for .7z\n" >&2; return 1
      fi
      ;;
    *)         printf "Error: Unsupported archive format: %s\n" "$1" >&2; printf "Supported: tar.{gz,bz2,xz}, zip, rar, 7z\n" >&2; return 1 ;;
  esac
}

# =============================================================================
# PRODUCTIVITY
# =============================================================================

# Quick confirm for destructive operations
confirm() {
  [[ -n "$1" ]] || { printf "Usage: confirm <prompt>\n" >&2; return 1; }
  local response
  printf "%s [y/N] " "$1" >&2
  read -r response || { printf "Cancelled\n" >&2; return 1; }
  [[ "$response" =~ ^[Yy]$ ]]
}

# Bootstrap new Git project
# Requires the 'git bootstrap' alias to be installed.
bootstrap() {
  [[ -x "$(command -v git)" ]] || { printf "Error: git not found\n" >&2; return 1; }

  if ! git config --get alias.bootstrap &>/dev/null; then
    printf "Error: 'git bootstrap' alias not found.\n" >&2
    printf "Solution: Run ~/.config/zsh/scripts/git-setup.sh to set up git configuration.\n" >&2
    return 1
  fi
  local folder_name="${1:-$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 13)}"
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
  ) || return 1

  [[ -z "$pids" ]] && { printf "No processes selected\n" >&2; return 0; }

  print -l $=pids | xargs kill -15 || return 1
  printf "✓ Killed PIDs: %s\n" "${pids//$'\n'/ }"
}

# =============================================================================
# SYSTEM UPGRADES & MAINTENANCE
# =============================================================================

# Comprehensive system upgrade — parallel execution with selective tool support
# Usage: upgrade [--only tool1,tool2,...] [--dry-run]
upgrade() {
  setopt LOCAL_OPTIONS
  unsetopt MONITOR NOTIFY

  local only_tools dry_run quiet_mode=0
  [[ ! -t 1 ]] && quiet_mode=1

  while [[ -n "$1" ]]; do
    case "$1" in
      --only)   only_tools="$2"; shift 2 ;;
      --dry-run) dry_run=1; shift ;;
      *)        printf "Usage: upgrade [--only tool1,tool2,...] [--dry-run]\n" >&2; return 1 ;;
    esac
  done

  local tmpdir
  tmpdir=$(mktemp -d)
  trap '
    for _pid in $pids; do kill -- -$_pid 2>/dev/null; done
    wait 2>/dev/null  # Reap all jobs silently
    rm -rf "$tmpdir"
    printf "\n[upgrade] cancelled\n"
    trap - INT TERM
  ' INT TERM

  local -a names=() pids=()
  local total_start=$EPOCHSECONDS

  # Job control helpers
  _job_start() { printf 'running' >"$tmpdir/$1.status"; printf '%s' $EPOCHSECONDS >"$tmpdir/$1.start" }
  _job_end()   {
    (( $2 == 0 )) && printf 'done' >"$tmpdir/$1.status" || printf 'failed' >"$tmpdir/$1.status"
    printf '%s' $EPOCHSECONDS >"$tmpdir/$1.end"
  }
  _launch_job() {
    local tool=$1 fn=$2
    [[ -n "$only_tools" ]] && [[ ! "$only_tools" =~ (^|,)$tool(,|$) ]] && return
    { _job_start $tool; ( set -e; $fn ); _job_end $tool $? } >"$tmpdir/$tool.log" 2>&1 &
    pids+=($!) names+=($tool)
  }

  # Per-tool upgrade functions
  _upgrade_brew() {
    brew update --quiet
    brew upgrade
    brew cleanup --prune=7
  }
  _upgrade_zinit() {
    (( ${+functions[zinit]} )) || return 0
    local zinit_dir="${ZINIT[HOME_DIR]:-${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git}"
    git -C "$zinit_dir" fetch origin --quiet 2>/dev/null || true
    local behind=$(git -C "$zinit_dir" rev-list HEAD..FETCH_HEAD --count 2>/dev/null || echo 0)
    (( behind > 0 )) && zinit self-update --quiet || true
    local stamp="$(_zcache_dir)/zinit-plugins-updated"
    if [[ ! -f "$stamp" ]] || (( EPOCHSECONDS - $(<"$stamp") > 86400 )); then
      zinit update --all --quiet || true
      printf '%s' $EPOCHSECONDS >"$stamp"
    fi
  }
  _upgrade_rust() {
    if command -v rustup &>/dev/null; then
      echo "updating rustup..."
      rustup update || echo "rustup update failed"
    else
      echo "rustup not installed"
      return 0
    fi
    # cargo-update plugin updates cargo-installed binaries from source.
    # On macOS most CLI tools come from brew instead, so this is usually a no-op.
    if command -v cargo-install-update &>/dev/null; then
      cargo install-update -a || echo "cargo package update failed"
    fi
  }
  _upgrade_node() {
    command -v fnm &>/dev/null || return 0
    local lts=$(fnm list-remote --lts 2>/dev/null | tail -1 | awk '{print $1}') || return 0
    local current=$(fnm current 2>/dev/null) || return 0
    [[ "v${lts#v}" != "v${current#v}" ]] && fnm install --lts && fnm default lts-latest && fnm use lts-latest || true
    npm outdated --global 2>/dev/null | grep -q . && npm install --global npm@latest pnpm@latest @antfu/ni eslint taze npkill || true
  }
  _upgrade_claude() {
    command -v claude &>/dev/null || return 0
    local current=$(claude --version 2>/dev/null | awk '{print $1}') || return 0
    local latest=$(npm view @anthropic-ai/claude-code version 2>/dev/null) || return 0
    [[ -n "$latest" && "$current" != "$latest" ]] && claude update || true
  }

  # Launch jobs (or show dry-run)
  if (( dry_run )); then
    printf "Dry-run mode — no changes will be made.\n\n"
    [[ -n "$only_tools" ]] && printf "Selected tools: %s\n\n" "$only_tools"
  fi

  # Go is upgraded by brew (installed via `brew install go`)
  (( $+commands[brew] )) && _launch_job brew _upgrade_brew
  _launch_job zinit _upgrade_zinit
  _launch_job rust _upgrade_rust
  _launch_job node _upgrade_node
  _launch_job claude _upgrade_claude

  [[ ${#names[@]} -eq 0 ]] && { printf "No tools to upgrade\n" >&2; rm -rf "$tmpdir"; return 0; }

  if (( dry_run )); then
    printf "Jobs that would run:\n"
    for name in $names; do
      printf "  • %s\n" "$name"
    done
    printf "\nDry-run complete — no changes made.\n"
    rm -rf "$tmpdir"
    return 0
  fi

  # Spinner display loop (skip in non-interactive mode)
  if (( quiet_mode )); then
    for pid in $pids; do wait "$pid" 2>/dev/null; done
  else
    local -a spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local spin_i=1 n=${#names[@]}
    for name in $names; do
      printf "  ${_COLOR_YELLOW}${spinner[1]}${_COLOR_RESET} [%-8s] starting...\n" "$name"
    done
    typeset -A done_line
    local all_done=0 s start_t end_t elapsed now
    while (( ! all_done )); do
      sleep 0.15
      printf '\033[%dA' "$n"
      all_done=1 now=$EPOCHSECONDS
      for name in $names; do
        if [[ -n ${done_line[$name]} ]]; then
          printf '%s\n' "${done_line[$name]}"
          continue
        fi
        s=$(<"$tmpdir/${name}.status" 2>/dev/null)
        start_t=$(<"$tmpdir/${name}.start" 2>/dev/null)
        start_t=${start_t:-$now}
        if [[ "$s" == 'done' ]]; then
          end_t=$(<"$tmpdir/${name}.end" 2>/dev/null)
          elapsed=$(( ${end_t:-$now} - start_t ))
          done_line[$name]=$(printf "\033[2K\r  ${_COLOR_GREEN}✓${_COLOR_RESET} [%-8s] done     ${_COLOR_DIM}%3ds${_COLOR_RESET}" "$name" "$elapsed")
          printf '%s\n' "${done_line[$name]}"
        elif [[ "$s" == 'failed' ]]; then
          end_t=$(<"$tmpdir/${name}.end" 2>/dev/null)
          elapsed=$(( ${end_t:-$now} - start_t ))
          done_line[$name]=$(printf "\033[2K\r  ${_COLOR_RED}✗${_COLOR_RESET} [%-8s] FAILED   ${_COLOR_DIM}%3ds${_COLOR_RESET}" "$name" "$elapsed")
          printf '%s\n' "${done_line[$name]}"
        else
          elapsed=$(( now - start_t ))
          printf "\033[2K\r  ${_COLOR_YELLOW}%s${_COLOR_RESET} [%-8s] running  ${_COLOR_DIM}%3ds${_COLOR_RESET}\n" "${spinner[$spin_i]}" "$name" "$elapsed"
          all_done=0
        fi
      done
      (( spin_i = spin_i % ${#spinner} + 1 ))
    done
  fi

  # Reap all background jobs (suppress job control output)
  for pid in $pids; do wait "$pid" 2>/dev/null; done
  wait 2>/dev/null  # Final catch-all for any remaining jobs
  local total_elapsed=$(( EPOCHSECONDS - total_start ))
  printf "\n${_COLOR_DIM}Finished in %ds${_COLOR_RESET}\n\n" "$total_elapsed"

  # Print logs: failed first, then successful
  local log has_failure=0
  for name in $names; do
    [[ $(<"$tmpdir/${name}.status") == 'failed' ]] || continue
    has_failure=1
    log=$(<"$tmpdir/${name}.log")
    printf "${_COLOR_RED}=== %s FAILED ===${_COLOR_RESET}\n%s\n\n" "$name" "$log"
  done
  for name in $names; do
    [[ $(<"$tmpdir/${name}.status") == 'failed' ]] && continue
    log=$(<"$tmpdir/${name}.log")
    [[ -n "$log" ]] && printf '=== %s ===\n%s\n\n' "$name" "$log"
  done

  # Version summary — data-driven
  _ver() {
    local label=$1; shift
    printf '  %-12s %s\n' "$label" "$("$@" 2>/dev/null || echo 'not found')"
  }
  _ver 'OS:'     sh -c 'echo "$(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null) ($(uname -m))"'
  _ver 'Kernel:' uname -r
  _ver 'Go:'     sh -c 'go version 2>/dev/null | awk "{print \$3}"'
  _ver 'Rust:'   sh -c 'rustc --version 2>/dev/null | awk "{print \$2}"'
  _ver 'Cargo:'  sh -c 'cargo --version 2>/dev/null | awk "{print \$2}"'
  _ver 'Node:'   node --version
  _ver 'npm:'    npm --version
  _ver 'pnpm:'   pnpm --version
  _ver 'Claude:' sh -c 'claude --version 2>/dev/null | awk "{print \$1}"'
  _ver 'Docker:' sh -c 'docker --version 2>/dev/null | awk "{print \$3}" | tr -d ","'
  _ver 'Git:'    sh -c 'git --version 2>/dev/null | awk "{print \$3}"'
  printf '\n'

  trap - INT TERM
  unfunction _job_start _job_end _launch_job _upgrade_{brew,zinit,rust,node,claude} _ver 2>/dev/null
  rm -rf "$tmpdir"

  if (( has_failure )); then
    if (( quiet_mode )); then
      printf "[FAILED] Some jobs failed — check logs above.\n"
    else
      printf "${_COLOR_RED}✗ Some jobs failed — check logs above.${_COLOR_RESET}\n"
    fi
    return 1
  fi
  if (( quiet_mode )); then
    printf "[OK] All done!\n"
  else
    printf "${_COLOR_GREEN}✓ All done!${_COLOR_RESET}\n"
  fi
}

# =============================================================================
# SYSTEM HEALTH CHECK
# =============================================================================

# Check zsh config and tool availability
zsh-health() {
  local issues=0

  printf "${_COLOR_GREEN}=== ZSH Configuration Health ===${_COLOR_RESET}\n\n"

  # Platform
  printf "Platform:\n"
  printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} macOS %s (%s)\n" "$(sw_vers -productVersion 2>/dev/null)" "$(uname -m)"
  if [[ "$(uname -m)" == "arm64" && ! -x /opt/homebrew/bin/brew ]]; then
    printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} Homebrew not found at /opt/homebrew (run install.sh)\n"
    (( issues++ ))
  fi
  printf "\n"

  # Check core tools
  printf "Core Tools:\n"
  local tool
  for tool in git zsh fzf eza bat fd; do
    if command -v "$tool" &>/dev/null; then
      printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-8s %s\n" "$tool" "$("$tool" --version 2>&1 | head -1)"
    else
      printf "  ${_COLOR_RED}✗${_COLOR_RESET} %-8s NOT FOUND\n" "$tool"; (( issues++ ))
    fi
  done
  printf "\n"

  # Check language tools (label:binary:version-command)
  printf "Language Tools:\n"
  local spec_lang label_lang bin_lang
  for spec_lang in "Go:go:go version" "Rust:rustc:rustc --version" \
                   "Node:node:node --version" "Python:python3:python3 --version"; do
    label_lang="${spec_lang%%:*}"
    bin_lang="${${spec_lang#*:}%%:*}"
    if command -v "$bin_lang" &>/dev/null; then
      printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-10s %s\n" "$label_lang" "$(${(z)spec_lang##*:} 2>&1 | head -1)"
    else
      printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} %-10s not installed\n" "$label_lang"
    fi
  done
  printf "\n"

  # Check PATH
  printf "PATH Configuration:\n"
  local path_count=$(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ')
  printf "  • %d directories in PATH\n" "$path_count"

  local -a key_dirs=(
    "$HOME/.local/bin:Local tools"
    "${HOMEBREW_PREFIX:-/opt/homebrew}/bin:Homebrew"
  )
  [[ -d "$HOME/.cargo/bin" ]] && key_dirs+=("$HOME/.cargo/bin:Rust/Cargo")
  [[ -d "$HOME/go/bin" ]]     && key_dirs+=("$HOME/go/bin:Go tools")

  local spec dir lbl
  for spec in "${key_dirs[@]}"; do
    dir="${spec%%:*}" lbl="${spec##*:}"
    if [[ ":$PATH:" == *":$dir:"* ]]; then
      printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %s (%s)\n" "$dir" "$lbl"
    else
      printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} %s (%s) missing from PATH\n" "$dir" "$lbl"
    fi
  done
  printf "\n"

  # Check zsh config
  printf "ZSH Configuration:\n"
  [[ -d "$ZDOTDIR" ]] && printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} ZDOTDIR = %s\n" "$ZDOTDIR" || printf "  ${_COLOR_RED}✗${_COLOR_RESET} ZDOTDIR not set\n"

  if (( ${+functions[zinit]} )); then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} Zinit plugins loaded\n"
  else
    printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} Zinit not initialized\n"
    (( issues++ ))
  fi

  if command -v z &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} Zoxide (smart cd) available\n"
  else
    printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} Zoxide not loaded\n"
  fi

  printf "\n"

  if (( issues == 0 )); then
    printf "${_COLOR_GREEN}✓ All critical tools present${_COLOR_RESET}\n"
    return 0
  else
    printf "${_COLOR_YELLOW}⊙ %d issue(s) detected — see above${_COLOR_RESET}\n" "$issues"
    return 1
  fi
}

# =============================================================================
# UTILITIES
# =============================================================================

# Show listening TCP ports
ports() {
  lsof -iTCP -sTCP:LISTEN -n -P
}

# Display PATH entries one per line, numbered
# Named show_path to avoid shadowing zsh's $path special array.
show_path() {
  echo $PATH | tr ':' '\n' | cat -n
}

# Create a throwaway temp directory and cd into it
tmpcd() {
  local d
  d=$(mktemp -d)
  printf "→ %s\n" "$d"
  cd "$d"
}

# =============================================================================
# CACHE MANAGEMENT
# =============================================================================

# Force regeneration of all eval caches on next shell start.
# Useful when auto-invalidation via mtime doesn't trigger (e.g., manual edits).
zsh-cache-clear() {
  local cache_dir="$(_zcache_dir)"
  local removed=0
  for f in starship.zsh zoxide.zsh fnm.zsh direnv.zsh fzf.zsh; do
    if [[ -f "$cache_dir/$f" ]]; then
      rm "$cache_dir/$f"
      (( removed++ ))
      print "Removed: $cache_dir/$f"
    fi
  done
  print "Cleared $removed cache file(s). Restart shell to regenerate."
}

# =============================================================================
# GIT SSH SIGNING SETUP
# =============================================================================
#
# Since Git 2.34, SSH keys can sign commits and tags instead of GPG keys.
# This is simpler: no GPG keyring, no key expiry management, no passphrase
# prompts — the same SSH key used for GitHub authentication also signs commits.
#
# ONE-TIME SETUP (new machine):
#
#   1. Generate key (skip if ~/.ssh/id_ed25519 already exists):
#      ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519
#
#   2. Create allowed_signers (used by `git verify-commit` locally):
#      echo "your@email.com $(cat ~/.ssh/id_ed25519.pub)" \
#        >~/.config/git/allowed_signers
#
#   3. Register key on GitHub (requires admin:public_key + admin:ssh_signing_key scopes):
#      gh auth refresh -s admin:public_key,admin:ssh_signing_key
#      gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type authentication
#      gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)" --type signing
#
#      OR add manually at: https://github.com/settings/ssh/new
#      (add once as Authentication Key, once as Signing Key)
#
# Run scripts/git-setup.sh to apply all of this automatically.
#
# VERIFY a signed commit:
#   git log --show-signature -1
#   # Expected: Good "git" signature for your@email.com with ED25519 key SHA256:...

# =============================================================================
# DISK SPACE CLEANUP
# =============================================================================

# Smart disk cleanup: targets project dirs (node_modules, vendor) and system caches
# Usage: freespace [--dry-run] [--aggressive]
#   --dry-run     Show what would be deleted without deleting
#   --aggressive  Also clean system caches (brew, npm, pip, go, cargo)
freespace() {
  local dry_run=0 aggressive=0
  while [[ -n "$1" ]]; do
    case "$1" in
      --dry-run)    dry_run=1; shift ;;
      --aggressive) aggressive=1; shift ;;
      *)            printf "Usage: freespace [--dry-run] [--aggressive]\n" >&2; return 1 ;;
    esac
  done

  local start_kb=$(/bin/df -k "$HOME" | awk 'NR==2 {print $4}')
  local removed_kb=0
  local -a actions=()   # action keywords, executed by _freespace_run below (no eval)

  printf "${_COLOR_YELLOW}Analyzing disk usage...${_COLOR_RESET}\n\n"

  # === Project cleanup (always safe) ===
  printf "Project directories (~/code):\n"

  # Node modules
  local nm_count=$(command find "$HOME/code" -maxdepth 4 -type d -name node_modules 2>/dev/null | wc -l | tr -d ' ')
  if (( nm_count > 0 )); then
    local nm_size=$(command find "$HOME/code" -maxdepth 4 -type d -name node_modules -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
    printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} node_modules (%d dirs, %s MB)\n" "$nm_count" "$(( nm_size / 1024 ))"
    actions+=(node_modules)
    (( removed_kb += nm_size ))
  fi

  # Vendor directories
  local vendor_count=$(command find "$HOME/code" -maxdepth 4 -type d -name vendor 2>/dev/null | wc -l | tr -d ' ')
  if (( vendor_count > 0 )); then
    local vendor_size=$(command find "$HOME/code" -maxdepth 4 -type d -name vendor -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {print s+0}')
    printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} vendor (%d dirs, %s MB)\n" "$vendor_count" "$(( vendor_size / 1024 ))"
    actions+=(vendor)
    (( removed_kb += vendor_size ))
  fi

  printf "\n"

  # === System cache cleanup (if --aggressive) ===
  # Table: action-keyword:label:directory — sizes computed in one loop
  if (( aggressive )); then
    printf "System caches (--aggressive):\n"

    local -a cache_specs=(
      "npm_cache:npm cache:$HOME/.npm"
      "pip_cache:pip cache:$HOME/.cache/pip"
      "go_cache:go build cache:$HOME/.cache/go-build"
      "cargo_cache:cargo registry cache:$HOME/.cargo/registry/cache"
    )
    local spec action_kw cache_label cache_dir cache_size
    for spec in "${cache_specs[@]}"; do
      action_kw="${spec%%:*}"
      cache_label="${${spec#*:}%%:*}"
      cache_dir="${spec##*:}"
      [[ -d "$cache_dir" ]] || continue
      cache_size=$(/usr/bin/du -sk "$cache_dir" 2>/dev/null | awk '{print $1}'); cache_size=${cache_size:-0}
      if (( cache_size > 0 )); then
        printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} %s (%s MB)\n" "$cache_label" "$(( cache_size / 1024 ))"
        actions+=("$action_kw"); (( removed_kb += cache_size ))
      fi
    done

    if (( $+commands[brew] )); then
      printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} homebrew cache (brew cleanup)\n"
      actions+=(brew_cache)
    fi

    printf "\n"
  fi

  # Summary
  printf "Total space to recover: ${_COLOR_GREEN}%s MB${_COLOR_RESET}\n\n" "$(( removed_kb / 1024 ))"

  [[ ${#actions[@]} -eq 0 ]] && { printf "Nothing to clean.\n"; return 0; }

  # Dry-run or execute
  if (( dry_run )); then
    printf "${_COLOR_YELLOW}Dry-run mode — no changes made.${_COLOR_RESET}\n"
    printf "Run ${_COLOR_GREEN}freespace${_COLOR_RESET}"
    (( aggressive )) && printf " ${_COLOR_GREEN}--aggressive${_COLOR_RESET}"
    printf " to clean.\n"
    return 0
  fi

  if ! confirm "Delete these directories?"; then
    printf "Cancelled.\n"
    return 1
  fi

  _freespace_run() {
    case "$1" in
      node_modules) command find "$HOME/code" -maxdepth 4 -type d -name node_modules -exec rm -rf {} + 2>/dev/null ;;
      vendor)       command find "$HOME/code" -maxdepth 4 -type d -name vendor -exec rm -rf {} + 2>/dev/null ;;
      npm_cache)    npm cache clean --force 2>/dev/null ;;
      pip_cache)    rm -rf "$HOME/.cache/pip" 2>/dev/null ;;
      go_cache)     go clean -cache 2>/dev/null; rm -rf "$HOME/.cache/go-build" 2>/dev/null ;;
      cargo_cache)  rm -rf "$HOME/.cargo/registry/cache" 2>/dev/null ;;
      brew_cache)   brew cleanup --prune=all 2>/dev/null ;;
    esac
    return 0
  }

  printf "\n${_COLOR_YELLOW}Cleaning...${_COLOR_RESET}\n"
  local action
  for action in "${actions[@]}"; do
    _freespace_run "$action"
  done
  unfunction _freespace_run

  local end_kb=$(/bin/df -k "$HOME" | awk 'NR==2 {print $4}')
  local freed=$(( (end_kb - start_kb) / 1024 ))
  printf "\n${_COLOR_GREEN}✓ Done!${_COLOR_RESET} Freed ~${_COLOR_GREEN}%s MB${_COLOR_RESET}\n" "$freed"
}
