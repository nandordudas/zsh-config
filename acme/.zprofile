# acme/.zprofile
# Sourced once for LOGIN shells. PATH, persistent env vars, directory setup.
#
# History lives in acme/.zshrc, not here: something later in the startup chain
# resets HISTFILE, and .zshrc runs last (and also for non-login interactive
# shells, which never read this file). The main config does the same for the
# same reason — see the comment in ../.zshrc.

# Non-interactive login shells (`ssh host cmd`, some editor integrations) return
# early: nothing below is needed to run a single command, and skipping the brew
# shellenv fork keeps them fast.
[[ -o interactive ]] || return

# XDG defaults. ~/.zshenv sets these today, but zsh reads $ZDOTDIR/.zshenv
# rather than ~/.zshenv, so a shell launched with ZDOTDIR already pointed here
# would arrive with them unset and every path below would become "/zsh/...".
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

[[ -d "$XDG_DATA_HOME/zsh/acme" ]] || mkdir -p "$XDG_DATA_HOME/zsh/acme"
[[ -d "$XDG_CACHE_HOME/zsh/acme/compcache" ]] || mkdir -p "$XDG_CACHE_HOME/zsh/acme/compcache"
[[ -d "$XDG_STATE_HOME/zsh" ]] || mkdir -p "$XDG_STATE_HOME/zsh"

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
# the arch default so this still resolves if brew was never found.
: "${HOMEBREW_PREFIX:=/opt/homebrew}"

typeset -U PATH path
path=(
  "$HOME/.local/bin"
  "$HOME/Library/Application Support/Headroom/headroom/bin"
  "$XDG_CONFIG_HOME/zsh/acme/bin"
  "$HOME/.local/share/pnpm/bin"
  $path
  "$HOMEBREW_PREFIX/share/android-commandlinetools/platform-tools"
)
export PATH

export LANG="${LANG:-en_US.UTF-8}"
export GIT_CONFIG_GLOBAL="$HOME/.config/git/config"

# Fall back through nvim/vim/nano like the main .zprofile — bare `code --wait`
# left EDITOR unset entirely on a machine without VS Code, which breaks
# `git commit` and `git rebase -i`.
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

export PNPM_HOME="$HOME/.local/share/pnpm"
export ANDROID_HOME="$HOMEBREW_PREFIX/share/android-commandlinetools"
export ADB_MDNS_OPENSCREEN=1

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# libpq is keg-only, so its bin/lib/include are not linked into the prefix.
# Path is derived from $HOMEBREW_PREFIX rather than forking `brew --prefix libpq`.
_libpq_prefix="$HOMEBREW_PREFIX/opt/libpq"
if [[ -d "$_libpq_prefix" ]]; then
  path=("$_libpq_prefix/bin" $path)
  export LDFLAGS="-L$_libpq_prefix/lib"
  export CPPFLAGS="-I$_libpq_prefix/include"
  export PKG_CONFIG_PATH="$_libpq_prefix/lib/pkgconfig"
fi
unset _libpq_prefix
