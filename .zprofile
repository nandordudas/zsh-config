# ~/.config/zsh/.zprofile
# Sourced once for login shells (every Terminal.app/iTerm2 tab, VS Code
# terminal, ssh session). Sets up PATH, persistent env vars, and creates
# required directories. This config targets macOS.

# Non-interactive login shells (`ssh host cmd`, some editor integrations) return
# early: nothing below is needed to run one command, and skipping the brew
# shellenv fork keeps them fast.
[[ -o interactive ]] || return

# =============================================================================
# XDG BASE DIRECTORIES
# ~/.zshenv normally sets these, but zsh reads $ZDOTDIR/.zshenv — NOT
# ~/.zshenv — so any shell started with ZDOTDIR pointed at a directory
# without its own .zshenv arrives here with them unset, and every path below
# would resolve to "/zsh/...". Default them rather than assume.
# =============================================================================
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

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

# $HOMEBREW_PREFIX instead of $(brew --prefix): shellenv above already exported
# it, and each `brew --prefix` is a ~40ms ruby fork at every login. Fall back to
# the arch default so paths still resolve if brew was never found.
: "${HOMEBREW_PREFIX:=/opt/homebrew}"

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
# GIT & PERSONAL IDENTIFIERS
# =============================================================================
export GIT_CONFIG_GLOBAL="$HOME/.config/git/config"

# =============================================================================
# PROJECT ROOT
# Used by the gg/gb navigation aliases.
# Override in modules/local.zsh if your projects live elsewhere.
# =============================================================================
export CODE_DIR="${CODE_DIR:-$HOME/Developer/code}"

# =============================================================================
# RUST / CARGO
# Sources ~/.cargo/env which exports CARGO_HOME etc.
# ~/.cargo/bin is already in PATH above, but this also sets other Cargo vars.
# =============================================================================
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# =============================================================================
# LOCAL TOOL ENV
# =============================================================================
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# libpq is keg-only, so its bin/lib/include are not linked into the prefix.
# Derived from $HOMEBREW_PREFIX rather than forking `brew --prefix libpq`.
_libpq_prefix="$HOMEBREW_PREFIX/opt/libpq"
if [[ -d "$_libpq_prefix" ]]; then
  path=("$_libpq_prefix/bin" $path)
  export LDFLAGS="-L$_libpq_prefix/lib"
  export CPPFLAGS="-I$_libpq_prefix/include"
  export PKG_CONFIG_PATH="$_libpq_prefix/lib/pkgconfig"
fi
unset _libpq_prefix
