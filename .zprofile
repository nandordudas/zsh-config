# ~/.config/zsh/.zprofile
# Sourced once for login shells (every new VS Code terminal in WSL, ssh
# sessions, every Terminal.app/iTerm2 tab on macOS).
# Sets up PATH, persistent env vars, and creates required directories.

# =============================================================================
# OS DETECTION
# Runs once at login; all child shells inherit the flags from the environment.
# =============================================================================
case "$OSTYPE" in
  darwin*) export IS_MACOS=1 IS_LINUX=0 ;;
  linux*)  export IS_MACOS=0 IS_LINUX=1 ;;
  *)       export IS_MACOS=0 IS_LINUX=0 ;;
esac

if [[ -z "$IS_WSL" ]]; then
  if (( IS_LINUX )) && [[ -r /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    export IS_WSL=1
  else
    export IS_WSL=0
  fi
fi

# =============================================================================
# ONE-TIME DIRECTORY SETUP
# Create directories that tools expect to exist. Safe to run at every login.
# =============================================================================
[[ -d "$XDG_DATA_HOME/zsh" ]]             || mkdir -p "$XDG_DATA_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh" ]]            || mkdir -p "$XDG_CACHE_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh/compcache" ]]  || mkdir -p "$XDG_CACHE_HOME/zsh/compcache"
[[ -d "$XDG_STATE_HOME/zsh" ]]            || mkdir -p "$XDG_STATE_HOME/zsh"

# =============================================================================
# HOMEBREW (macOS and Linuxbrew)
# Must come before the PATH block so brew-installed tools are found.
# /opt/homebrew = Apple Silicon, /usr/local = Intel macs, /home/linuxbrew = Linux
# =============================================================================
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$_brew" ]]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi

# =============================================================================
# ZSH CONFIG UPDATE CHECK
# Once a day, fetch the repo's upstream and report if new commits are available.
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

  # Fetch upstream quietly (only on the daily check, so login stays fast)
  git -C "$zsh_dir" fetch --quiet 2>/dev/null || return 0

  # Count commits upstream has that we don't
  local behind
  behind=$(git -C "$zsh_dir" rev-list --count HEAD..@{u} 2>/dev/null)

  if [[ -n "$behind" && "$behind" -gt 0 ]]; then
    printf '\n%s\n' "╭─ 🔄 zsh-config has $behind new commit(s) upstream"
    printf '%s\n' "├─ Run: git -C \$ZDOTDIR pull && exec zsh"
    printf '%s\n' "╰─────────────────────────────────────────"
  fi
}

_check_zsh_config_updates

# =============================================================================
# PATH (deduplicated via typeset -U)
# Ordered: user-local → language runtimes → system
# Homebrew paths (if any) were already prepended by brew shellenv above and
# are preserved through $path at the end.
# =============================================================================
typeset -U PATH path

path=(
  "$HOME/.local/bin"           # direnv, delta, user-installed tools
  "$HOME/.fzf/bin"             # fzf (git-cloned install)
  "$HOME/.cargo/bin"           # fnm, cargo-installed tools
  "$HOME/go/bin"               # go-installed binaries (g, etc.)
  "$HOME/.go/bin"              # go toolchain itself (g version manager)
  "$XDG_CONFIG_HOME/zsh/bin"   # personal scripts
  $path                        # homebrew + system dirs (/usr/local/bin, /usr/bin, …)
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
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
# Only point GOROOT at ~/.go when the `g` version manager layout exists.
# (Homebrew/system Go installs manage GOROOT themselves.)
# =============================================================================
[[ -d "$HOME/.go" ]] && export GOROOT="$HOME/.go"
export GOPATH="${GOPATH:-$HOME/go}"

# =============================================================================
# GIT & PERSONAL IDENTIFIERS
# =============================================================================
export GIT_CONFIG_GLOBAL="$HOME/.config/git/config"

# =============================================================================
# RUST / CARGO
# Sources ~/.cargo/env which exports CARGO_HOME etc.
# ~/.cargo/bin is already in PATH above, but this also sets other Cargo vars.
# =============================================================================
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
