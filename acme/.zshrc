# acme/.zshrc
# Interactive shell config for the acme profile. Sources the shared modules
# from the repo root, so every fix there applies here too.

[[ -o interactive ]] || return

# XDG defaults — a non-login interactive shell never runs acme/.zprofile, and
# zsh reads $ZDOTDIR/.zshenv rather than ~/.zshenv, so neither is guaranteed.
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

# History — set HERE and not in acme/.zprofile. Something later in the startup
# chain resets HISTFILE, so a value exported from .zprofile ended up back at
# zsh's default ($ZDOTDIR/.zsh_history, i.e. inside the repo). .zshrc runs last
# and also covers non-login interactive shells, so both problems go away.
[[ -d "$XDG_DATA_HOME/zsh/acme" ]] || mkdir -p "$XDG_DATA_HOME/zsh/acme"
export HISTFILE="$XDG_DATA_HOME/zsh/acme/history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE="$XDG_CACHE_HOME/lesshst"

# Repo root. zsh applies the :h modifier inside double quotes (unlike bash),
# so this correctly strips the trailing /acme.
_zconfig_root="$ZDOTDIR:h"

source "$_zconfig_root/modules/options.zsh"      # Core zsh settings
source "$_zconfig_root/modules/zinit.zsh"        # Plugin manager
source "$_zconfig_root/modules/completions.zsh"  # Completions
source "$_zconfig_root/modules/keybindings.zsh"  # Keybindings
source "$_zconfig_root/modules/aliases.zsh"      # Aliases
source "$_zconfig_root/modules/functions.zsh"    # Functions
source "$_zconfig_root/modules/tools.zsh"        # Tool inits (starship, mise, fzf, etc.)

# Machine-local overrides (gitignored). Machine-specific PATH entries and tool
# env vars belong there, not in this committed file.
[[ -f "$_zconfig_root/modules/local.zsh" ]] && source "$_zconfig_root/modules/local.zsh"

alias reload='exec -l zsh'

unset _zconfig_root
