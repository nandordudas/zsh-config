# ~/.config/zsh/.zshrc
# Interactive shell configuration. Sources modules in dependency order.
# To profile startup time: uncomment zprof lines, then run: time zsh -i -c exit

[[ -o interactive ]] || return

# zmodload zsh/zprof  # uncomment to profile

# 1. Shell options (setopt only, no external deps)
source "$ZDOTDIR/modules/options.zsh"

# 2. Zinit bootstrap + all plugins
source "$ZDOTDIR/modules/zinit.zsh"

# 3. Completion zstyle config (compinit is triggered by zinit above)
source "$ZDOTDIR/modules/completions.zsh"

# 4. Key bindings (after plugins so we can override)
source "$ZDOTDIR/modules/keybindings.zsh"

# 5. Aliases
source "$ZDOTDIR/modules/aliases.zsh"

# 6. Functions
source "$ZDOTDIR/modules/functions.zsh"

# 7. External tool init (cached evals: starship, zoxide, fnm, direnv, fzf)
source "$ZDOTDIR/modules/tools.zsh"

# 8. Machine-local overrides (gitignored)
[[ -f "$ZDOTDIR/modules/local.zsh" ]] && source "$ZDOTDIR/modules/local.zsh"

# zprof  # uncomment when profiling
