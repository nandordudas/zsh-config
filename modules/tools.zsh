# modules/tools.zsh
# External tool initialization with eval output caching.
#
# Pattern: cache each tool's init script to $XDG_CACHE_HOME/zsh/<tool>.zsh
# Regenerate the cache when the binary is newer than the cache file (-nt test).
# This turns ~65-85ms of subprocess forks into ~1-2ms of file sourcing.
#
# Helper function _ztool_init() centralizes cache logic and reduces duplication.
# Special case: FZF requires complex PATH handling and stays in anonymous function.

_ztool_cache="$XDG_CACHE_HOME/zsh"
mkdir -p "$_ztool_cache"
chmod 700 "$_ztool_cache" 2>/dev/null  # Prevent cache injection vulnerability

# =============================================================================
# HELPER: Initialize external tool with init script caching
# Usage: _ztool_init "starship" "$(command -v starship)" "starship init zsh"
# =============================================================================
_ztool_init() {
  local name="$1" bin="$2" init_cmd="$3"
  [[ -x "$bin" ]] || return 0
  local cache="$_ztool_cache/${name}.zsh"
  if [[ ! -s "$cache" || "$bin" -nt "$cache" ]]; then
    # Write to a temp file first so a failed or empty init never leaves a
    # bad cache behind (which would be silently sourced on every future start).
    if ! eval "$init_cmd" >"$cache.tmp" 2>/dev/null || [[ ! -s "$cache.tmp" ]]; then
      rm -f "$cache.tmp"
      return 1
    fi
    mv -f "$cache.tmp" "$cache"
  fi
  source "$cache"
}

# =============================================================================
# STARSHIP PROMPT (conditional on interactive mode)
# Must initialize last among prompt-modifying tools.
# =============================================================================
# Check if interactive mode is enabled (default: on)
_zinteractive_mode_file="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/interactive-mode"
_zinteractive_mode=$(<"$_zinteractive_mode_file" 2>/dev/null || echo "on")

if [[ "$_zinteractive_mode" == "on" ]]; then
  _ztool_init starship "$(command -v starship)" "starship init zsh"
fi
unset _zinteractive_mode _zinteractive_mode_file

# =============================================================================
# ZOXIDE (smart cd replacement — type z instead of cd)
# =============================================================================
_ztool_init zoxide "$(command -v zoxide)" "zoxide init zsh"

# =============================================================================
# MISE (runtime version manager: node, go, python, …)
# Runtimes are installed by install.sh (`mise use -g node@lts go@latest`);
# the shell only wires up the activation hook here.
# =============================================================================
_ztool_init mise "$(command -v mise)" "mise activate zsh"

# =============================================================================
# DIRENV (project-specific environments)
# Must initialize before zoxide so project-specific PATH changes apply to cd
# =============================================================================
_direnv_bin="$(command -v direnv 2>/dev/null || echo "$HOME/.local/bin/direnv")"
_ztool_init direnv "$_direnv_bin" "direnv hook zsh"
unset _direnv_bin

# =============================================================================
# FZF (Fuzzy Finder)
# Installed via brew; fzf >= 0.48 ships zsh integration behind --zsh.
# Init output is cached like the other tools (~10-15ms saved per shell).
# =============================================================================
() {
  (( $+commands[fzf] )) || return 0

  # FZF behavior
  export FZF_DEFAULT_OPTS='
    --height 40%
    --layout=reverse
    --border rounded
    --bind ctrl-/:toggle-preview
    --bind alt-j:preview-down
    --bind alt-k:preview-up
  '

  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null'
  fi

  # Ctrl+T preview: file content via bat
  export FZF_CTRL_T_OPTS='
    --preview "bat --color=always --style=numbers --line-range=:100 {} 2>/dev/null || cat {}"
    --preview-window right:55%:wrap
  '

  # Alt+C preview: directory listing via eza
  export FZF_ALT_C_OPTS='
    --preview "eza -1 --icons --color=always {} 2>/dev/null || ls {}"
    --preview-window right:55%:wrap
  '

  # Key bindings + tab completion (cached)
  _ztool_init fzf "${commands[fzf]}" "fzf --zsh"
}

# =============================================================================
# CLEANUP
# =============================================================================
unset -f _ztool_init
unset _ztool_cache
