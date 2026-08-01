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
