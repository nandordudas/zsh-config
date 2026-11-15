# ~/.config/zsh/.zshenv
# Sourced for EVERY zsh invocation (login, interactive, scripts). Keep it
# minimal: only directory env vars and ZDOTDIR.
#
# ~/.zshenv is a symlink to this file. zsh reads ~/.zshenv only while ZDOTDIR
# is still unset (the first shell); ZDOTDIR is exported, so every child shell
# reads $ZDOTDIR/.zshenv instead — this same file — and both paths agree.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Tell zsh to look for dotfiles in ~/.config/zsh instead of ~
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
