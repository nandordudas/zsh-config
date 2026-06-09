# ~/.config/zsh/.zshrc
# Interactive shell configuration. Sources modules in dependency order.
# To profile startup time: uncomment zprof lines, then run: time zsh -i -c exit

[[ -o interactive ]] || return

# zmodload zsh/zprof  # uncomment to profile

# 1. Platform detection (OS flags, portable command names)
source "$ZDOTDIR/modules/platform.zsh"

# 2. Shell options (setopt only, no external deps)
source "$ZDOTDIR/modules/options.zsh"

# 3. Zinit bootstrap + all plugins
source "$ZDOTDIR/modules/zinit.zsh"

# 4. Completion zstyle config (compinit is triggered by zinit above)
source "$ZDOTDIR/modules/completions.zsh"

# 5. Key bindings (after plugins so we can override)
source "$ZDOTDIR/modules/keybindings.zsh"

# 6. Aliases
source "$ZDOTDIR/modules/aliases.zsh"

# 7. Functions
source "$ZDOTDIR/modules/functions.zsh"

# 8. External tool init (cached evals: starship, zoxide, fnm, direnv, fzf)
source "$ZDOTDIR/modules/tools.zsh"

# 9. Machine-local overrides (gitignored)
[[ -f "$ZDOTDIR/modules/local.zsh" ]] && source "$ZDOTDIR/modules/local.zsh"

# zprof  # uncomment when profiling
