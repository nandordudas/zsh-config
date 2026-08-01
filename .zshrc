# ~/.config/zsh/.zshrc
# Interactive shell configuration. Sources modules in dependency order.
# To profile startup time: uncomment zprof lines, then run: time zsh -i -c exit

[[ -o interactive ]] || return

# History — here (not .zprofile) so non-login interactive shells share the same file
export HISTFILE="${XDG_DATA_HOME}/zsh/history"
export HISTSIZE=50000
export SAVEHIST=50000
export LESSHISTFILE="${XDG_CACHE_HOME}/lesshst"

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
