# ~/.config/zsh/.zshrc
# Interactive shell configuration. Sources modules in dependency order.
# To profile startup time: uncomment zprof lines, then run: time zsh -i -c exit

[[ -o interactive ]] || return

# XDG defaults — a non-login interactive shell never runs .zprofile, and zsh
# reads $ZDOTDIR/.zshenv rather than ~/.zshenv, so neither is guaranteed to
# have set these. Without the fallbacks HISTFILE becomes "/zsh/history".
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

# History — here (not .zprofile) so non-login interactive shells share the same file
[[ -d "$XDG_DATA_HOME/zsh" ]] || mkdir -p "$XDG_DATA_HOME/zsh"
export HISTFILE="$XDG_DATA_HOME/zsh/history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE="$XDG_CACHE_HOME/lesshst"

# zmodload zsh/zprof  # uncomment to profile

# Repo root — same as $ZDOTDIR here, but modules/*.zsh use $_zconfig_root
# (not $ZDOTDIR) for repo-relative paths so they also work under acme/,
# where $ZDOTDIR points at the acme/ subdir instead of the repo root.
_zconfig_root="$ZDOTDIR"

# 1. Shell options (setopt only, no external deps)
source "$_zconfig_root/modules/options.zsh"

# 2. Zinit bootstrap + all plugins
source "$_zconfig_root/modules/zinit.zsh"

# 3. Completion zstyle config (compinit is triggered by zinit above)
source "$_zconfig_root/modules/completions.zsh"

# 4. Key bindings (after plugins so we can override)
source "$_zconfig_root/modules/keybindings.zsh"

# 5. Aliases
source "$_zconfig_root/modules/aliases.zsh"

# 6. Functions
source "$_zconfig_root/modules/functions.zsh"

# 7. External tool init (cached evals: starship, zoxide, mise, fzf)
source "$_zconfig_root/modules/tools.zsh"

# 8. Machine-local overrides (gitignored)
# Machine-specific PATH entries and tool env vars (Headroom, per-host API
# endpoints, …) belong in local.zsh, not here — this file is committed.
[[ -f "$_zconfig_root/modules/local.zsh" ]] && source "$_zconfig_root/modules/local.zsh"

# zprof  # uncomment when profiling

unset _zconfig_root
