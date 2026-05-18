# Custom functions for common tasks and workflows

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
extract() {
  [[ $# -eq 1 ]] || { printf "Usage: extract <archive>\n" >&2; return 1; }
  [[ -f "$1" ]] || { printf "Error: File not found: %s\n" "$1" >&2; return 1; }

  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.7z)      7z x "$1" ;;
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
  ) || return 1

  [[ -z "$pids" ]] && { printf "No processes selected\n" >&2; return 0; }

  print -l $=pids | xargs kill -15 || return 1
  printf "✓ Killed PIDs: %s\n" "${pids//$'\n'/ }"
}

# =============================================================================
# SYSTEM UPGRADES & MAINTENANCE
# =============================================================================

# Attempt to download prebuilt binary from GitHub releases
# Returns 0 (success) if binary was downloaded and installed, 1 (failure) if not available
# Usage: _cargo_download_binary "package_name" "github_repo" "asset_pattern" "extract_cmd"
_cargo_download_binary() {
  local package="$1" github_repo="$2" asset_pattern="$3" extract_cmd="$4"
  local install_dir="${HOME}/.cargo/bin"
  local temp_dir

  [[ -n "$package" && -n "$github_repo" && -n "$asset_pattern" ]] || return 1

  # Create temp directory for download
  temp_dir=$(mktemp -d) || return 1
  trap "rm -rf '$temp_dir'" RETURN

  # Try to download from GitHub releases
  # Use /latest/download/ redirect to avoid API rate limits
  local release_url="https://github.com/${github_repo}/releases/latest/download/${asset_pattern}"

  if ! curl -fsSL "$release_url" -o "$temp_dir/binary.tar.gz" 2>/dev/null; then
    return 1
  fi

  # Extract and install binary
  if eval "$extract_cmd" "$temp_dir/binary.tar.gz" "$install_dir" 2>/dev/null; then
    printf "✓ Downloaded prebuilt: %s\n" "$package"
    return 0
  else
    return 1
  fi
}

# Extract tar.gz into directory, preserving binary permissions
_extract_binary_tar() {
  local archive="$1" dest_dir="$2"
  tar -xzf "$archive" -C "$dest_dir" --wildcards '*/'"$3" 2>/dev/null || tar -xzf "$archive" -C "$dest_dir" 2>/dev/null
}

# Extract zip file and locate binary
_extract_binary_zip() {
  local archive="$1" dest_dir="$2" binary_name="$3"
  local extracted
  extracted=$(unzip -q -l "$archive" | grep -o "[^/]*${binary_name}[^ ]*" | head -1) || return 1
  unzip -q -o "$archive" -d "$dest_dir" "$extracted" 2>/dev/null || return 1
  # Move extracted binary to proper location
  find "$dest_dir" -name "$binary_name" -exec mv {} "$dest_dir/$binary_name" \; 2>/dev/null
}

# Smart cargo package updater — hybrid approach: prebuilt first, source fallback
# Tries to download prebuilt binaries from GitHub releases first (fast: ~10-15s)
# Falls back to cargo install if prebuilt unavailable (slow: 5-10 min)
# Only rebuilds if updates available
_cargo_smart_update() {
  local cache_dir="$(_zcache_dir)"
  local manifest_file="$cache_dir/cargo-manifest.json"
  local needs_update=0

  # Package metadata: name, github_repo, release_asset_pattern, extract_binary_name
  declare -A packages=(
    [eza]="eza-community/eza|eza_x86_64-unknown-linux-musl.tar.gz|eza"
    [procs]="dalance/procs|procs-*-x86_64-linux.zip|procs"
    [git-delta]="dandavison/delta|delta-*-x86_64-unknown-linux-musl.tar.gz|delta"
    [du-dust]="bootandy/dust|dust-*-x86_64-unknown-linux-musl.tar.gz|dust"
    [fnm]="Schniz/fnm|fnm-linux.zip|fnm"
  )

  # Initialize manifest if missing
  if [[ ! -f "$manifest_file" ]]; then
    mkdir -p "$cache_dir"
    echo "{" >"$manifest_file"
    local first=1
    for pkg in "${(k)packages[@]}"; do
      local version=$($HOME/.cargo/bin/$pkg --version 2>/dev/null | awk '{print $NF}' || echo "unknown")
      (( ! first )) && echo "," >>"$manifest_file"
      printf '  "%s": "%s"' "$pkg" "$version" >>"$manifest_file"
      first=0
    done
    echo "}" >>"$manifest_file"
    needs_update=1
  fi

  # Check if any installed package is outdated
  if (( ! needs_update )); then
    local output
    output=$(cargo install-update -a --dry-run 2>&1 || echo "check_error")

    if echo "$output" | grep -q "Updating"; then
      needs_update=1
    elif echo "$output" | grep -q "check_error"; then
      echo "⚠ cargo-update check failed; rebuilding conservatively"
      cargo install-update -a
      return $?
    else
      echo "✓ Cargo packages up-to-date (checked $(date +%H:%M:%S))"
      return 0
    fi
  fi

  if (( needs_update )); then
    echo "↻ Updating cargo packages (trying prebuilt binaries first)..."

    # Try downloading prebuilt binaries in parallel
    local -a download_pids=()
    local download_count=0
    local failed_packages=()

    for pkg in "${(k)packages[@]}"; do
      local meta="${packages[$pkg]}"
      local repo="${meta%%|*}" asset="${meta#*|}" asset="${asset%%|*}" binary="${meta##*|}"

      # Attempt download in background
      (
        if [[ "$asset" == *.tar.gz ]]; then
          curl -fsSL "https://github.com/${repo}/releases/latest/download/${asset}" | tar -xzf - -C "$HOME/.cargo/bin" 2>/dev/null && exit 0
        elif [[ "$asset" == *.zip ]]; then
          local temp_dir=$(mktemp -d)
          trap "rm -rf '$temp_dir'" RETURN
          if curl -fsSL "https://github.com/${repo}/releases/latest/download/${asset}" -o "$temp_dir/archive.zip" 2>/dev/null; then
            unzip -q "$temp_dir/archive.zip" -d "$temp_dir" && \
            find "$temp_dir" -name "$binary" -exec cp {} "$HOME/.cargo/bin/$binary" \; 2>/dev/null && \
            chmod +x "$HOME/.cargo/bin/$binary" && exit 0
          fi
        fi
        exit 1
      ) &
      download_pids+=($!)
      (( download_count++ ))
    done

    # Wait for all downloads and check results
    local succeeded=0
    for pid in "${download_pids[@]}"; do
      if wait "$pid" 2>/dev/null; then
        (( succeeded++ ))
      fi
    done

    # If some downloads failed, fall back to cargo install for failed packages
    if (( succeeded < download_count )); then
      echo "↻ Prebuilt binaries unavailable for some packages; rebuilding from source..."
      cargo install-update -a
    else
      printf "✓ Updated %d packages from prebuilt binaries\n" "$download_count"
    fi

    # Update manifest timestamp
    rm -f "$manifest_file"
  fi
}

# Comprehensive system upgrade — parallel execution with selective tool support
# Usage: upgrade [--only tool1,tool2,...] [--dry-run]
upgrade() {
  setopt LOCAL_OPTIONS
  unsetopt MONITOR NOTIFY

  local only_tools dry_run
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

  if ! sudo -n true 2>/dev/null; then
    printf "Error: sudo access required\n" >&2
    rm -rf "$tmpdir"
    return 1
  fi

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
  _upgrade_apt() {
    sudo apt-get update -qq
    sudo apt-get upgrade -y --autoremove --purge
    sudo apt-get autoclean
  }
  _upgrade_zinit() {
    (( ${+functions[zinit]} )) || return 0
    local zinit_dir="${ZINIT[HOME_DIR]:-${HOME}/.local/share/zinit/zinit.git}"
    git -C "$zinit_dir" fetch origin --quiet 2>/dev/null || true
    local behind=$(git -C "$zinit_dir" rev-list HEAD..FETCH_HEAD --count 2>/dev/null || echo 0)
    (( behind > 0 )) && zinit self-update --quiet || true
    local stamp="${HOME}/.cache/zinit-plugins-updated"
    if [[ ! -f "$stamp" ]] || (( EPOCHSECONDS - $(<"$stamp") > 86400 )); then
      zinit update --all --quiet || true
      printf '%s' $EPOCHSECONDS >"$stamp"
    fi
  }
  _upgrade_rust() {
    command -v rustup &>/dev/null && rustup update
    command -v cargo  &>/dev/null && _cargo_smart_update
  }
  _upgrade_go() {
    [[ ! -x "$HOME/go/bin/g" ]] && return 0
    local local_go=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//') || return 0
    local remote_go=$(curl -sf 'https://go.dev/VERSION?m=text' 2>/dev/null | head -1 | sed 's/go//') || return 0
    [[ -n "$remote_go" && "$local_go" != "$remote_go" ]] && "$HOME/go/bin/g" install latest && "$HOME/go/bin/g" use latest || true
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

  _launch_job apt _upgrade_apt
  _launch_job zinit _upgrade_zinit
  _launch_job rust _upgrade_rust
  _launch_job go _upgrade_go
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

  # Spinner display loop
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
  local _ver() {
    local label=$1; shift
    printf '  %-12s %s\n' "$label" "$("$@" 2>/dev/null || echo 'not found')"
  }
  _ver 'OS:'     lsb_release -ds
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
  unfunction _job_start _job_end _launch_job _upgrade_{apt,zinit,rust,go,node,claude} _ver
  rm -rf "$tmpdir"

  if (( has_failure )); then
    printf "${_COLOR_RED}✗ Some jobs failed — check logs above.${_COLOR_RESET}\n"
    return 1
  fi
  printf "${_COLOR_GREEN}✓ All done!${_COLOR_RESET}\n"
}

# =============================================================================
# SYSTEM HEALTH CHECK
# =============================================================================

# Check zsh config and tool availability
zsh-health() {
  local issues=0

  printf "${_COLOR_GREEN}=== ZSH Configuration Health ===${_COLOR_RESET}\n\n"

  # Check core tools
  printf "Core Tools:\n"
  if command -v git &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-8s %s\n" "git" "$(git --version 2>&1 | head -1)"
  else
    printf "  ${_COLOR_RED}✗${_COLOR_RESET} %-8s NOT FOUND\n" "git"; (( issues++ ))
  fi
  if command -v zsh &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-8s %s\n" "zsh" "$(zsh --version 2>&1 | head -1)"
  else
    printf "  ${_COLOR_RED}✗${_COLOR_RESET} %-8s NOT FOUND\n" "zsh"; (( issues++ ))
  fi
  if command -v fzf &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-8s %s\n" "fzf" "$(fzf --version 2>&1)"
  else
    printf "  ${_COLOR_RED}✗${_COLOR_RESET} %-8s NOT FOUND\n" "fzf"; (( issues++ ))
  fi
  if command -v eza &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-8s %s\n" "eza" "$(eza --version 2>&1 | head -1)"
  else
    printf "  ${_COLOR_RED}✗${_COLOR_RESET} %-8s NOT FOUND\n" "eza"; (( issues++ ))
  fi
  if command -v batcat &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-8s %s\n" "bat" "$(batcat --version 2>&1 | head -1)"
  else
    printf "  ${_COLOR_RED}✗${_COLOR_RESET} %-8s NOT FOUND\n" "bat"; (( issues++ ))
  fi
  if command -v fdfind &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-8s %s\n" "fd" "$(fdfind --version 2>&1 | head -1)"
  else
    printf "  ${_COLOR_RED}✗${_COLOR_RESET} %-8s NOT FOUND\n" "fd"; (( issues++ ))
  fi
  printf "\n"

  # Check language tools
  printf "Language Tools:\n"
  if command -v go &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-10s %s\n" "Go" "$(go version 2>&1)"
  else
    printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} %-10s not installed\n" "Go"
  fi
  if command -v rustc &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-10s %s\n" "Rust" "$(rustc --version 2>&1)"
  else
    printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} %-10s not installed\n" "Rust"
  fi
  if command -v node &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-10s %s\n" "Node" "$(node --version 2>&1)"
  else
    printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} %-10s not installed\n" "Node"
  fi
  if command -v python3 &>/dev/null; then
    printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %-10s %s\n" "Python" "$(python3 --version 2>&1)"
  else
    printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} %-10s not installed\n" "Python"
  fi
  printf "\n"

  # Check PATH
  printf "PATH Configuration:\n"
  local path_count=$(echo $PATH | tr ':' '\n' | wc -l)
  printf "  • %d directories in PATH\n" "$path_count"

  local key_dirs=(
    "$HOME/.cargo/bin:Rust/Cargo"
    "$HOME/.local/bin:Local tools"
    "$HOME/go/bin:Go tools"
    "/usr/local/bin:System tools"
  )
  for spec in "${key_dirs[@]}"; do
    local dir="${spec%%:*}" label="${spec##*:}"
    if [[ ":$PATH:" =~ ":$dir:" ]]; then
      printf "  ${_COLOR_GREEN}✓${_COLOR_RESET} %s (%s)\n" "$dir" "$label"
    else
      printf "  ${_COLOR_YELLOW}⊙${_COLOR_RESET} %s (%s) missing from PATH\n" "$dir" "$label"
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
# GIT HELPERS
# =============================================================================
# Note: git checkout helper provided by forgit plugin (gcb alias)

# =============================================================================
# UTILITIES
# =============================================================================

# Show listening ports
ports() {
  ss -tlnp | awk 'NR==1 || /LISTEN/'
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
  for f in starship.zsh zoxide.zsh fnm.zsh direnv.zsh; do
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
# GIT CONFIG (already applied to ~/.config/git/config):
#   [user]
#     signingKey = ~/.ssh/id_ed25519.pub
#   [gpg]
#     format = ssh
#   [gpg "ssh"]
#     allowedSignersFile = ~/.config/git/allowed_signers
#   [commit]
#     gpgSign = true
#   [tag]
#     gpgSign = true
#
# VERIFY a signed commit:
#   git log --show-signature -1
#   # Expected: Good "git" signature for your@email.com with ED25519 key SHA256:...
#
# NOTE: GitHub shows a "Verified" badge only after the key is registered as a
#       Signing Key on GitHub (step 3 above). Local verification works immediately.

# =============================================================================
# DISK SPACE CLEANUP
# =============================================================================

# Smart disk cleanup: targets project dirs (node_modules, vendor) and system caches
# Usage: freespace [--dry-run] [--aggressive]
#   --dry-run     Show what would be deleted without deleting
#   --aggressive  Also clean system caches (apt, npm, pip, go, cargo)
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
  local -a actions=()

  printf "${_COLOR_YELLOW}Analyzing disk usage...${_COLOR_RESET}\n\n"

  # === Project cleanup (always safe) ===
  printf "Project directories (~/code):\n"

  # Node modules
  local nm_count=$(find "$HOME/code" -maxdepth 4 -type d -name node_modules 2>/dev/null | wc -l)
  if (( nm_count > 0 )); then
    local nm_size=$(find "$HOME/code" -maxdepth 4 -type d -name node_modules 2>/dev/null -exec du -sk {} + | awk '{s+=$1} END {print s}')
    printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} node_modules (%d dirs, %s MB)\n" "$nm_count" "$(( nm_size / 1024 ))"
    actions+=("find '$HOME/code' -maxdepth 4 -type d -name node_modules -exec rm -rf {} + 2>/dev/null || true")
    (( removed_kb += nm_size ))
  fi

  # Vendor directories
  local vendor_count=$(find "$HOME/code" -maxdepth 4 -type d -name vendor 2>/dev/null | wc -l)
  if (( vendor_count > 0 )); then
    local vendor_size=$(find "$HOME/code" -maxdepth 4 -type d -name vendor 2>/dev/null -exec du -sk {} + | awk '{s+=$1} END {print s}')
    printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} vendor (%d dirs, %s MB)\n" "$vendor_count" "$(( vendor_size / 1024 ))"
    actions+=("find '$HOME/code' -maxdepth 4 -type d -name vendor -exec rm -rf {} + 2>/dev/null || true")
    (( removed_kb += vendor_size ))
  fi

  printf "\n"

  # === System cache cleanup (if --aggressive) ===
  if (( aggressive )); then
    printf "System caches (--aggressive):\n"

    # npm cache
    if [[ -d "$HOME/.npm" ]]; then
      local npm_size=$(/bin/du -sk "$HOME/.npm" 2>/dev/null | awk '{print $1}' | head -1)
      npm_size=${npm_size:-0}
      if (( npm_size > 0 )); then
        printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} npm cache (%s MB)\n" "$(( npm_size / 1024 ))"
        actions+=("npm cache clean --force 2>/dev/null || true")
        (( removed_kb += npm_size ))
      fi
    fi

    # pip cache
    if [[ -d "$HOME/.cache/pip" ]]; then
      local pip_size=$(/bin/du -sk "$HOME/.cache/pip" 2>/dev/null | awk '{print $1}' | head -1)
      pip_size=${pip_size:-0}
      if (( pip_size > 0 )); then
        printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} pip cache (%s MB)\n" "$(( pip_size / 1024 ))"
        actions+=("rm -rf '$HOME/.cache/pip' 2>/dev/null || true")
        (( removed_kb += pip_size ))
      fi
    fi

    # Go build cache
    if [[ -d "$HOME/.cache/go-build" ]]; then
      local go_size=$(/bin/du -sk "$HOME/.cache/go-build" 2>/dev/null | awk '{print $1}' | head -1)
      go_size=${go_size:-0}
      if (( go_size > 0 )); then
        printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} go build cache (%s MB)\n" "$(( go_size / 1024 ))"
        actions+=("go clean -cache 2>/dev/null || true; rm -rf '$HOME/.cache/go-build' 2>/dev/null || true")
        (( removed_kb += go_size ))
      fi
    fi

    # Cargo cache
    if [[ -d "$HOME/.cargo/registry/cache" ]]; then
      local cargo_size=$(/bin/du -sk "$HOME/.cargo/registry/cache" 2>/dev/null | awk '{print $1}' | head -1)
      cargo_size=${cargo_size:-0}
      if (( cargo_size > 0 )); then
        printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} cargo registry cache (%s MB)\n" "$(( cargo_size / 1024 ))"
        actions+=("rm -rf '$HOME/.cargo/registry/cache' 2>/dev/null || true")
        (( removed_kb += cargo_size ))
      fi
    fi

    # APT cache
    if command -v apt &>/dev/null; then
      local apt_size=$(du -sk /var/cache/apt 2>/dev/null | awk '{print $1}')
      (( apt_size > 0 )) && printf "  ${_COLOR_YELLOW}→${_COLOR_RESET} apt cache (%s MB, requires sudo)\n" "$(( apt_size / 1024 ))"
      actions+=("sudo apt-get autoclean 2>/dev/null || true")
      (( removed_kb += apt_size ))
    fi

    printf "\n"
  fi

  # Summary
  printf "Total space to recover: ${_COLOR_GREEN}%s MB${_COLOR_RESET}\n\n" "$(( removed_kb / 1024 ))"

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

  printf "\n${_COLOR_YELLOW}Cleaning...${_COLOR_RESET}\n"
  for action in "${actions[@]}"; do
    eval "$action"
  done

  local end_kb=$(/bin/df -k "$HOME" | awk 'NR==2 {print $4}')
  local freed=$(( (end_kb - start_kb) / 1024 ))
  printf "\n${_COLOR_GREEN}✓ Done!${_COLOR_RESET} Freed ~${_COLOR_GREEN}%s MB${_COLOR_RESET}\n" "$freed"
}
