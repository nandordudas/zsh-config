# modules/keybindings.zsh
# All key bindings defined manually — no plugin needed.
#
# Strategy:
#   - terminfo lookups for terminal-portable keys (Home, End, arrows)
#   - Literal escape sequences as fallback for xterm / VS Code terminal
#   - history-substring-search widgets set here; the plugin loads async but
#     zsh resolves widget names lazily so there's no error at bind time

# Emacs line editing mode
bindkey -e

# =============================================================================
# APPLICATION MODE
# Enables terminfo key values ($terminfo[khome] etc.) when zle is active.
# Required for portable Home/End/arrow bindings across terminals.
# =============================================================================
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
  zle-line-init()   { echoti smkx }
  zle-line-finish() { echoti rmkx }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

# =============================================================================
# LINE NAVIGATION
# =============================================================================
# Home / End via terminfo (most reliable)
[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]}"  ]] && bindkey "${terminfo[kend]}"  end-of-line

# Fallback literal sequences for xterm / VS Code terminal
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[OH'  beginning-of-line   # VT100 application mode
bindkey '^[OF'  end-of-line

# =============================================================================
# WORD NAVIGATION
# =============================================================================
bindkey '^[[1;5C' forward-word    # Ctrl+Right
bindkey '^[[1;5D' backward-word   # Ctrl+Left

# =============================================================================
# DELETION
# =============================================================================
bindkey '^?' backward-delete-char   # Backspace

# Delete key (forward delete)
if [[ -n "${terminfo[kdch1]}" ]]; then
  bindkey "${terminfo[kdch1]}" delete-char
else
  bindkey '^[[3~'  delete-char
  bindkey '^[3;5~' delete-char
fi

# Ctrl+Backspace = delete word backward (VS Code terminal sends ^H)
bindkey '^H' backward-kill-word

# Ctrl+W = kill previous word (standard Unix)
bindkey '^W' backward-kill-word

# Alt+D = kill next word
bindkey '^[d' kill-word

# =============================================================================
# HISTORY SEARCH
# Up/Down: prefix-aware search via zsh-history-substring-search plugin.
# The plugin loads in turbo mode; by the time the user presses Up (~150ms
# human reaction time), the plugin is loaded and the widgets are registered.
# =============================================================================
[[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
[[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
bindkey '^[[A' history-substring-search-up    # xterm Up
bindkey '^[[B' history-substring-search-down  # xterm Down
bindkey '^P'   history-substring-search-up    # Emacs Ctrl+P
bindkey '^N'   history-substring-search-down  # Emacs Ctrl+N

# Ctrl+R: incremental backward history search (fzf overrides this in tools.zsh)
bindkey '^R' history-incremental-search-backward

# =============================================================================
# COMPLETION NAVIGATION
# =============================================================================
# Shift+Tab: move backward through completion menu
[[ -n "${terminfo[kcbt]}" ]] && bindkey "${terminfo[kcbt]}" reverse-menu-complete
bindkey '^[[Z' reverse-menu-complete   # xterm fallback

# Space: expand history inline (e.g., type !$ then space)
bindkey ' ' magic-space

# =============================================================================
# EDITING CONVENIENCES
# =============================================================================
# Ctrl+X Ctrl+E: open current command in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Alt+M: copy previous shell word (useful for: mv foo.txt [Alt+M].bak)
bindkey '^[m' copy-prev-shell-word

# PageUp/PageDown: navigate history
[[ -n "${terminfo[kpp]}" ]] && bindkey "${terminfo[kpp]}" up-line-or-history
[[ -n "${terminfo[knp]}" ]] && bindkey "${terminfo[knp]}" down-line-or-history
