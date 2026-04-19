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
# Requires the 'git bootstrap' alias from scripts/git-setup.sh to be installed.
bootstrap() {
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
  )

  [[ -z "$pids" ]] && return 0

  print -l $=pids | xargs kill -15
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

# Comprehensive system upgrade function — parallel execution
upgrade() {
  # Suppress [N] PID job-start and job-done notifications — they break the
  # in-place ANSI display by adding unexpected lines between redraws.
  # LOCAL_OPTIONS ensures the change is reverted automatically on return.
  setopt LOCAL_OPTIONS
  unsetopt MONITOR NOTIFY

  local tmpdir
  tmpdir=$(mktemp -d)

  # Verify sudo access before backgrounding — apt job needs it.
  # Use -n (non-interactive) so it works without a TTY when NOPASSWD is set.
  if ! sudo -n true 2>/dev/null; then
    printf "Error: sudo access required for system upgrades\n" >&2
    rm -rf "$tmpdir"
    return 1
  fi

  # Track which jobs were launched (in display order)
  local -a names=()
  local -a pids=()

  # Kill background jobs and clean up on Ctrl+C or SIGTERM.
  # kill -- -$pid sends SIGTERM to the entire process group so children
  # of each subshell (e.g. apt, claude) are also terminated.
  trap '
    for _pid in $pids; do kill -- -$_pid 2>/dev/null; done
    rm -rf "$tmpdir"
    printf "\n[upgrade] cancelled\n"
    trap - INT TERM
  ' INT TERM

  local total_start=$EPOCHSECONDS

  # Bookend helpers — called inside each { ... } & block to record
  # start time, then mark done/failed + end time after the body exits.
  # $tmpdir is in scope for all subshells forked from upgrade().
  _job_start() { printf 'running' >"$tmpdir/$1.status"; printf '%s' $EPOCHSECONDS >"$tmpdir/$1.start" }
  _job_end()   {
    (( $2 == 0 )) \
      && printf 'done'   >"$tmpdir/$1.status" \
      || printf 'failed' >"$tmpdir/$1.status"
    printf '%s' $EPOCHSECONDS >"$tmpdir/$1.end"
  }

  # --- apt ---
  {
    _job_start apt
    ( set -e
      sudo apt-get update -qq
      sudo apt-get upgrade -y --autoremove --purge
      sudo apt-get autoclean
    ); _job_end apt $?
  } >"$tmpdir/apt.log" 2>&1 &
  pids+=($!)
  names+=(apt)

  # --- zinit ---
  if (( ${+functions[zinit]} )); then
    {
      _job_start zinit
      ( set -e
        local zinit_dir="${ZINIT[HOME_DIR]:-${HOME}/.local/share/zinit/zinit.git}"
        git -C "$zinit_dir" fetch origin --quiet 2>/dev/null || true
        local behind
        behind=$(git -C "$zinit_dir" rev-list HEAD..FETCH_HEAD --count 2>/dev/null || echo 0)
        behind=${behind:-0}
        (( behind > 0 )) && zinit self-update --quiet || true
        local stamp="${HOME}/.cache/zinit-plugins-updated"
        if [[ ! -f "$stamp" ]] || (( EPOCHSECONDS - $(<"$stamp") > 86400 )); then
          zinit update --all --quiet || true
          printf '%s' $EPOCHSECONDS >"$stamp"
        fi
      ); _job_end zinit $?
    } >"$tmpdir/zinit.log" 2>&1 &
    pids+=($!)
    names+=(zinit)
  fi

  # --- rust (rustup must precede cargo) ---
  if command -v rustup &>/dev/null || command -v cargo &>/dev/null; then
    {
      _job_start rust
      ( set -e
        command -v rustup &>/dev/null && rustup update
        command -v cargo  &>/dev/null && _cargo_smart_update
      ); _job_end rust $?
    } >"$tmpdir/rust.log" 2>&1 &
    pids+=($!)
    names+=(rust)
  fi

  # --- go ---
  if command -v "$HOME/go/bin/g" &>/dev/null; then
    {
      _job_start go
      ( set -e
        local LOCAL_GO REMOTE_GO
        LOCAL_GO=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
        REMOTE_GO=$(curl -sf 'https://go.dev/VERSION?m=text' 2>/dev/null | head -1 | sed 's/go//')
        if [[ -n "$REMOTE_GO" && "$LOCAL_GO" != "$REMOTE_GO" ]]; then
          "$HOME/go/bin/g" install latest && "$HOME/go/bin/g" use latest
        fi
      ); _job_end go $?
    } >"$tmpdir/go.log" 2>&1 &
    pids+=($!)
    names+=(go)
  fi

  # --- node (fnm must precede npm) ---
  if command -v fnm &>/dev/null; then
    {
      _job_start node
      ( set -e
        local lts current
        lts=$(fnm list-remote --lts 2>/dev/null | tail -1 | awk '{print $1}')
        current=$(fnm current 2>/dev/null)
        if [[ "v${lts#v}" != "v${current#v}" ]]; then
          fnm install --lts && fnm default lts-latest && fnm use lts-latest
        fi
        if npm outdated --global 2>/dev/null | grep -q .; then
          npm install --global npm@latest pnpm@latest @antfu/ni eslint taze npkill
        fi
      ); _job_end node $?
    } >"$tmpdir/node.log" 2>&1 &
    pids+=($!)
    names+=(node)
  fi

  # --- claude ---
  if command -v claude &>/dev/null; then
    {
      _job_start claude
      ( set -e
        local current latest
        current=$(claude --version 2>/dev/null | awk '{print $1}')
        latest=$(npm view @anthropic-ai/claude-code version 2>/dev/null)
        if [[ -n "$latest" && "$current" != "$latest" ]]; then
          claude update
        fi
      ); _job_end claude $?
    } >"$tmpdir/claude.log" 2>&1 &
    pids+=($!)
    names+=(claude)
  fi

  # --- Display loop ---
  # Spinner frames (braille dots); 1-indexed for zsh arrays.
  local -a spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local spin_i=1
  local n=${#names[@]}

  # Print initial block
  for name in $names; do
    printf "  ${_COLOR_YELLOW}${spinner[1]}${_COLOR_RESET} [%-8s] starting...\n" "$name"
  done

  # Cache rendered lines for completed jobs — skips re-reading their files each tick.
  typeset -A done_line

  local all_done=0 s start_t end_t elapsed now
  while (( ! all_done )); do
    sleep 0.15
    printf '\033[%dA' "$n"
    all_done=1
    now=$EPOCHSECONDS
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
        printf "\033[2K\r  ${_COLOR_YELLOW}%s${_COLOR_RESET} [%-8s] running  ${_COLOR_DIM}%3ds${_COLOR_RESET}\n" \
          "${spinner[$spin_i]}" "$name" "$elapsed"
        all_done=0
      fi
    done
    (( spin_i = spin_i % ${#spinner} + 1 ))
  done

  # Reap background jobs
  for pid in $pids; do
    wait "$pid" 2>/dev/null
  done

  local total_elapsed
  total_elapsed=$(( EPOCHSECONDS - total_start ))
  printf "\n${c_dim}Finished in %ds${c_reset}\n\n" "$total_elapsed"

  # --- Print logs: failed jobs first (prominent), then successful ---
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

  # --- Version summary ---
  printf '  %-12s %s\n' 'OS:'     "$(lsb_release -ds 2>/dev/null)"
  printf '  %-12s %s\n' 'Kernel:' "$(uname -r)"
  printf '  %-12s %s\n' 'Go:'     "$(go version 2>/dev/null | awk '{print $3}' || echo 'not found')"
  printf '  %-12s %s\n' 'Rust:'   "$(rustc --version 2>/dev/null | awk '{print $2}' || echo 'not found')"
  printf '  %-12s %s\n' 'Cargo:'  "$(cargo --version 2>/dev/null | awk '{print $2}' || echo 'not found')"
  printf '  %-12s %s\n' 'Node:'   "$(node --version 2>/dev/null || echo 'not found')"
  printf '  %-12s %s\n' 'npm:'    "$(npm --version 2>/dev/null || echo 'not found')"
  printf '  %-12s %s\n' 'pnpm:'   "$(pnpm --version 2>/dev/null || echo 'not found')"
  printf '  %-12s %s\n' 'Claude:' "$(claude --version 2>/dev/null || echo 'not found')"
  printf '  %-12s %s\n' 'Docker:' "$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo 'not found')"
  printf '  %-12s %s\n' 'Git:'    "$(git --version 2>/dev/null | awk '{print $3}' || echo 'not found')"
  printf '\n'

  trap - INT TERM
  unfunction _job_start _job_end
  rm -rf "$tmpdir"

  if (( has_failure )); then
    printf "${_COLOR_RED}✗ Some jobs failed — check logs above.${_COLOR_RESET}\n"
    return 1
  fi
  printf "${_COLOR_GREEN}✓ All done!${_COLOR_RESET}\n"
}

# =============================================================================
# GIT HELPERS
# =============================================================================

# FZF git checkout helper (quick alternative to forgit)
# Strips remotes/<remote>/ prefix so remote branches create local tracking branches
# instead of checking out in detached HEAD mode.
gcb() {
  local branch
  branch=$(git branch --all | fzf | sed 's|^[* ]*||; s|remotes/[^/]*/||')
  [[ -n "$branch" ]] && git checkout "$branch"
}

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
