echo "1. Sourcing .zprofile"

[[ -o interactive ]] || return

[[ -d "$XDG_DATA_HOME/zsh" ]] || mkdir -p "$XDG_DATA_HOME/zsh"
[[ -d "$XDG_CACHE_HOME/zsh/compcache" ]] || mkdir -p "$XDG_CACHE_HOME/zsh/compcache"

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
  "$XDG_CONFIG_HOME/zsh/acme/bin"
  $path
)
export PATH

if (( $+commands[code] )); then
  export EDITOR='code --wait'
fi
export VISUAL="$EDITOR"
