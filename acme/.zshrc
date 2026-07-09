# acme/.zshrc — sources the shared modules in $ZDOTDIR:h/modules so this
# profile stays in sync with the canonical config (keybindings, aliases,
# functions, tool init) instead of hand-duplicating a stale copy.

_zconfig_root="$ZDOTDIR:h"

source "$_zconfig_root/modules/options.zsh"
source "$_zconfig_root/modules/zinit.zsh"
source "$_zconfig_root/modules/completions.zsh"
source "$_zconfig_root/modules/keybindings.zsh"
source "$_zconfig_root/modules/aliases.zsh"
source "$_zconfig_root/modules/functions.zsh"
source "$_zconfig_root/modules/tools.zsh"

unset _zconfig_root

# acme-specific overrides (after modules so these win)
alias reload='exec -l zsh'

# >>> headroom:managed_rtk >>>
export PATH="/Users/nandordudas/Library/Application Support/Headroom/headroom/bin:$PATH"
# <<< headroom:managed_rtk <<<
# >>> headroom:claude_code >>>
export ANTHROPIC_BASE_URL=http://127.0.0.1:6767
# <<< headroom:claude_code <<<
