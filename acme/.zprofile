[[ -o interactive ]] || return

[[ -d "$XDG_DATA_HOME/zsh/acme" ]] || mkdir -p "$XDG_DATA_HOME/zsh/acme"
[[ -d "$XDG_CACHE_HOME/zsh/acme/compcache" ]] || mkdir -p "$XDG_CACHE_HOME/zsh/acme/compcache"

export HISTFILE="${XDG_DATA_HOME}/zsh/acme/history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE="${XDG_CACHE_HOME}/lesshst"

if [[ -z "$HOMEBREW_PREFIX" ]]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$_brew" ]]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi

typeset -U PATH path
path=(
  "$HOME/.local/bin"
  "$HOME/Library/Application Support/Headroom/headroom/bin"
  "$XDG_CONFIG_HOME/zsh/acme/bin"
  "$HOME/.local/share/pnpm/bin"
  $path
  "$(brew --prefix)/share/android-commandlinetools/platform-tools"
)
export PATH

export LANG="${LANG:-en_US.UTF-8}"
export GIT_CONFIG_GLOBAL="$HOME/.config/git/config"

(( $+commands[code] )) && export EDITOR='code --wait'

export VISUAL="$EDITOR"

export PNPM_HOME="$HOME/.local/share/pnpm"
export ANDROID_HOME="$(brew --prefix)/share/android-commandlinetools"
export ADB_MDNS_OPENSCREEN=1

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

if _libpq_prefix="$(brew --prefix libpq 2>/dev/null)" && [[ -d "$_libpq_prefix" ]]; then
  path=("$_libpq_prefix/bin" $path)
  export LDFLAGS="-L$_libpq_prefix/lib"
  export CPPFLAGS="-I$_libpq_prefix/include"
  export PKG_CONFIG_PATH="$_libpq_prefix/lib/pkgconfig"
fi
unset _libpq_prefix
