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
# VISUAL mirrors EDITOR so every consumer (git resolves VISUAL before
# EDITOR) gets the same waiting editor — `code` without --wait returns
# immediately and breaks rebase/commit editing.
# =============================================================================
if (( $+commands[code] )); then
  export EDITOR='code --wait'
elif (( $+commands[nvim] )); then
  export EDITOR='nvim'
elif (( $+commands[vim] )); then
  export EDITOR='vim'
else
  export EDITOR='nano'
fi
export VISUAL="$EDITOR"

# =============================================================================
# GO
# Go itself is per-project via mise (GOROOT handled by mise); GOPATH is
# where `go install` puts binaries — kept stable across versions.
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
export CODE_DIR="${CODE_DIR:-$HOME/Development/code}"

# =============================================================================
# RUST / CARGO
# Sources ~/.cargo/env which exports CARGO_HOME etc.
# ~/.cargo/bin is already in PATH above, but this also sets other Cargo vars.
# =============================================================================
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
