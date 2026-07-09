_zconfig_root="$ZDOTDIR:h"

source "$_zconfig_root/modules/options.zsh"      # Core zsh settings
source "$_zconfig_root/modules/zinit.zsh"        # Plugin manager
source "$_zconfig_root/modules/completions.zsh"  # Completions
source "$_zconfig_root/modules/keybindings.zsh"  # Keybindings
source "$_zconfig_root/modules/aliases.zsh"      # Aliases
source "$_zconfig_root/modules/functions.zsh"    # Functions
source "$_zconfig_root/modules/tools.zsh"        # Tool inits (starship, mise, fzf, etc.)
[[ -f "$_zconfig_root/modules/local.zsh" ]] && source "$_zconfig_root/modules/local.zsh"

alias reload='exec -l zsh'

# >>> headroom:managed_rtk >>>
export PATH="/Users/nandordudas/Library/Application Support/Headroom/headroom/bin:$PATH"
# <<< headroom:managed_rtk <<<
# >>> headroom:claude_code >>>
export ANTHROPIC_BASE_URL=http://127.0.0.1:6767
# <<< headroom:claude_code <<<
