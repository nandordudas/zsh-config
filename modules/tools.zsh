# modules/tools.zsh
# External tool initialization with eval output caching.
#
# Pattern: cache each tool's init script to $XDG_CACHE_HOME/zsh/<tool>.zsh
# Regenerate the cache when the binary is newer than the cache file (-nt test).
# This turns ~65-85ms of subprocess forks into ~1-2ms of file sourcing.
#
# Anonymous functions (() { ... }) scope local variables without polluting globals.

_ztool_cache="$XDG_CACHE_HOME/zsh"
mkdir -p "$_ztool_cache"

# =============================================================================
# STARSHIP PROMPT
# Must initialize last among prompt-modifying tools.
# =============================================================================
() {
  local cache="$_ztool_cache/starship.zsh"
  local bin="${commands[starship]}"
  if [[ -x "$bin" ]]; then
    [[ ! -f "$cache" || "$bin" -nt "$cache" ]] && "$bin" init zsh >"$cache"
    source "$cache"
  fi
}

# =============================================================================
# ZOXIDE (smart cd replacement — type z instead of cd)
# =============================================================================
() {
  local cache="$_ztool_cache/zoxide.zsh"
  local bin="${commands[zoxide]}"
  if [[ -x "$bin" ]]; then
    [[ ! -f "$cache" || "$bin" -nt "$cache" ]] && "$bin" init zsh >"$cache"
    source "$cache"
  fi
}

# =============================================================================
# FNM (Node Version Manager)
# =============================================================================
() {
  local cache="$_ztool_cache/fnm.zsh"
  local bin="$HOME/.cargo/bin/fnm"
  if [[ -x "$bin" ]]; then
    [[ ! -f "$cache" || "$bin" -nt "$cache" ]] && "$bin" env --use-on-cd --shell zsh >"$cache"
    source "$cache"
  fi
}

# =============================================================================
# DIRENV (project-specific environments)
# =============================================================================
() {
  local cache="$_ztool_cache/direnv.zsh"
  local bin="$HOME/.local/bin/direnv"
  if [[ -x "$bin" ]]; then
    [[ ! -f "$cache" || "$bin" -nt "$cache" ]] && "$bin" hook zsh >"$cache"
    source "$cache"
  fi
}

# =============================================================================
# FZF (Fuzzy Finder)
# Prefers ~/.fzf/bin/fzf (git install, newer) over system fzf (apt, older).
# Adds ~/.fzf/bin to PATH here as a fallback for non-login shells where
# .zprofile was not sourced.
# =============================================================================
() {
  local fzf_dir="$HOME/.fzf"
  local fzf_bin="$fzf_dir/bin/fzf"

  # Ensure ~/.fzf/bin is in PATH even in non-login interactive shells
  if [[ -x "$fzf_bin" && ":$PATH:" != *":$fzf_dir/bin:"* ]]; then
    path=("$fzf_dir/bin" $path)
  fi

  # Fall back to system fzf if git-clone install is absent
  if [[ ! -x "$fzf_bin" ]]; then
    fzf_bin="$(command -v fzf 2>/dev/null)"
    fzf_dir=""
  fi

  [[ -x "$fzf_bin" ]] || return

  # FZF behavior
  export FZF_DEFAULT_OPTS='
    --height 40%
    --layout=reverse
    --border rounded
    --bind ctrl-/:toggle-preview
    --bind alt-j:preview-down
    --bind alt-k:preview-up
  '

  # Using fdfind (Debian package name for fd)
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git 2>/dev/null'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git 2>/dev/null'

  # Ctrl+T preview: file content via batcat (Debian name for bat)
  export FZF_CTRL_T_OPTS='
    --preview "batcat --color=always --style=numbers --line-range=:100 {} 2>/dev/null || cat {}"
    --preview-window right:55%:wrap
  '

  # Alt+C preview: directory listing via eza
  export FZF_ALT_C_OPTS='
    --preview "eza -1 --icons --color=always {} 2>/dev/null || ls {}"
    --preview-window right:55%:wrap
  '

  # Source fzf shell integration (key bindings + tab completion)
  if [[ -n "$fzf_dir" && -f "$fzf_dir/shell/key-bindings.zsh" ]]; then
    source "$fzf_dir/shell/key-bindings.zsh"
    [[ -f "$fzf_dir/shell/completion.zsh" ]] && source "$fzf_dir/shell/completion.zsh"
  elif "$fzf_bin" --zsh &>/dev/null; then
    # fzf >= 0.48 supports --zsh flag
    source <("$fzf_bin" --zsh)
  fi
}

# =============================================================================
# CLEANUP
# =============================================================================
unset _ztool_cache
