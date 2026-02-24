# modules/completions.zsh
# Completion BEHAVIOR configuration via zstyle.
# Completion INITIALIZATION is handled in zinit.zsh via zicompinit; zicdreplay.
# This file must NOT call compinit, zicompinit, autoload -Uz compinit, or zicdreplay.

# =============================================================================
# CACHE
# =============================================================================
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/compcache"

# =============================================================================
# MATCHING & ORDERING
# =============================================================================
# Case-insensitive: lowercase matches uppercase and vice versa
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Never offer . and .. in completion menus
zstyle ':completion:*' special-dirs false

# Group completions by type, show group names
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'

# =============================================================================
# DISPLAY
# =============================================================================
# Color completions using LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Show a menu when there are many matches
zstyle ':completion:*' menu select

# =============================================================================
# PROCESS COMPLETION
# =============================================================================
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,%cpu,cmd"

# =============================================================================
# GIT COMPLETION
# =============================================================================
zstyle ':completion:*:git-checkout:*' sort false

# =============================================================================
# FZF-TAB CONFIGURATION
# ftb-tmux-popup is NOT used — requires an active tmux session.
# Default fzf rendering works in VS Code terminal and any other terminal.
# =============================================================================

# cd preview: show directory contents with eza
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza -1 --icons --color=always $realpath 2>/dev/null || ls $realpath'

# ls/la/ll preview: directory listing or file content
zstyle ':fzf-tab:complete:(ls|la|ll|lt):*' fzf-preview \
  'if [[ -d $realpath ]]; then
     eza -1 --icons --color=always $realpath 2>/dev/null || ls $realpath
   else
     batcat --color=always --style=numbers --line-range=:50 $realpath 2>/dev/null || cat $realpath
   fi'

# kill preview: show process command
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-header -w -w'

# Tab/Shift-Tab to switch between completion groups
zstyle ':fzf-tab:*' switch-group '<' '>'
