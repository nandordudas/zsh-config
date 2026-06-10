# ~/.config/zsh/.zprofile
# Sourced once for login shells (every Terminal.app/iTerm2 tab, VS Code
# terminal, ssh session). Sets up PATH, persistent env vars, and creates
# required directories. This config targets macOS.

# =============================================================================
# ONE-TIME DIRECTORY SETUP
# Create directories that tools expect to exist. Safe to run at every login.
# =============================================================================
[[ -d "$XDG_DATA_HOME/zsh" ]]             || mkdir -p "$XDG_DATA_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh" ]]            || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh/compcache" ]]  || mkdir -p "$XDG_CACHE_HOME/zsh/compcache"
[[ -d "$XDG_STATE_HOME/zsh" ]]            || mkdir -p "$XDG_STATE_HOME/zsh"

# =============================================================================
# HOMEBREW
# Must come before the PATH block so brew-installed tools are found.
# /opt/homebrew = Apple Silicon, /usr/local = Intel macs
# =============================================================================
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$_brew" ]]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi

# =============================================================================
# ZSH CONFIG UPDATE CHECK
# Once a day: compare against the already-fetched upstream (instant, no
# network), then refresh the remote refs in a detached background job.
# Login is never blocked by the network; a new update shows up one check late.
# =============================================================================
_check_zsh_config_updates() {
  zmodload zsh/datetime 2>/dev/null || return 0

  local zsh_dir="$ZDOTDIR"
  local cache_file="$XDG_CACHE_HOME/zsh/update-check"
  local cache_max_age=86400  # 1 day in seconds

  # Skip if not a git repo
  [[ -d "$zsh_dir/.git" ]] || return 0

  # Skip if cache fresh
  if [[ -f "$cache_file" ]]; then
    local last_check=$(<"$cache_file")
    (( EPOCHSECONDS - last_check < cache_max_age )) && return 0
  fi

  # Update cache timestamp
  printf '%s' "$EPOCHSECONDS" >"$cache_file"

  # Compare against refs from the last background fetch (no network)
  local behind
  behind=$(git -C "$zsh_dir" rev-list --count HEAD..@{u} 2>/dev/null)

  if [[ -n "$behind" && "$behind" -gt 0 ]]; then
    printf '\n%s\n' "╭─ 🔄 zsh-config has $behind new commit(s) upstream"
    printf '%s\n' "├─ Run: git -C \$ZDOTDIR pull && exec zsh"
    printf '%s\n' "╰─────────────────────────────────────────"
  fi

  # Refresh remote refs for the next check — detached, silent, never prompts
  ( GIT_TERMINAL_PROMPT=0 git -C "$zsh_dir" fetch --quiet >/dev/null 2>&1 & ) 2>/dev/null
}

_check_zsh_config_updates

# =============================================================================
# PATH (deduplicated via typeset -U)
# Ordered: user-local → language runtimes → homebrew/system
# Homebrew paths were already prepended by brew shellenv above and are
# preserved through $path.
# =============================================================================
typeset -U PATH path

path=(
  "$HOME/.local/bin"           # user-installed tools
  "$HOME/.cargo/bin"           # cargo-installed tools
  "$HOME/go/bin"               # go-installed binaries
  "$XDG_CONFIG_HOME/zsh/bin"   # personal scripts
  $path                        # homebrew + system dirs (/opt/homebrew/bin, /usr/bin, …)
)

export PATH

# =============================================================================
# LANGUAGE & LOCALE
# =============================================================================
export LANG="${LANG:-en_US.UTF-8}"

# =============================================================================
# EDITOR
# Prefer VS Code when installed, fall back to nvim/vim/nano.
# =============================================================================
if (( $+commands[code] )); then
  export EDITOR='code --wait'
  export VISUAL='code'
elif (( $+commands[nvim] )); then
  export EDITOR='nvim' VISUAL='nvim'
elif (( $+commands[vim] )); then
  export EDITOR='vim' VISUAL='vim'
else
  export EDITOR='nano' VISUAL='nano'
fi

# =============================================================================
# HISTORY
# Directory is guaranteed by the mkdir block above.
# =============================================================================
export HISTFILE="$XDG_DATA_HOME/zsh/history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE="$XDG_CACHE_HOME/lesshst"

# =============================================================================
# GO
# Homebrew Go manages GOROOT itself; only GOPATH is needed.
# =============================================================================
export GOPATH="${GOPATH:-$HOME/go}"

# =============================================================================
# GIT & PERSONAL IDENTIFIERS
# =============================================================================
export GIT_CONFIG_GLOBAL="$HOME/.config/git/config"

# =============================================================================
# PROJECT ROOT
# Used by the gg/gb navigation aliases and freespace cleanup.
# Override in modules/local.zsh if your projects live elsewhere.
# =============================================================================
export CODE_DIR="${CODE_DIR:-$HOME/Developer}"

# =============================================================================
# RUST / CARGO
# Sources ~/.cargo/env which exports CARGO_HOME etc.
# ~/.cargo/bin is already in PATH above, but this also sets other Cargo vars.
# =============================================================================
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
