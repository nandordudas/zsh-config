# acme/.zshenv
# zsh reads $ZDOTDIR/.zshenv, NOT ~/.zshenv. Without this file, launching the
# sandbox as `ZDOTDIR=~/.config/zsh/acme zsh -i` from a clean environment left
# every XDG_* var unset, so the tool caches resolved to "/zsh/<tool>.zsh" and
# _ztool_init failed on every tool. It only appeared to work because it was
# always launched from an already-configured shell that exported them.

: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

# Deliberately NOT exporting ZDOTDIR here: it is already set to this directory
# by whoever launched the sandbox, and overwriting it with the repo root (the
# way ~/.zshenv does) would send zsh back to the main config.
