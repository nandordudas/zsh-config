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
  if [[ ! -f "$cache" || "$bin" -nt "$cache" ]]; then
    eval "$init_cmd" >"$cache" || return 1
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
# FNM (Node Version Manager)
# =============================================================================
_fnm_bin="$(command -v fnm 2>/dev/null || echo "$HOME/.cargo/bin/fnm")"

# Ensure FNM has a default Node version installed before init
if [[ -x "$_fnm_bin" ]]; then
  if [[ -z "$($_fnm_bin list 2>/dev/null | grep default)" ]]; then
    $_fnm_bin install --lts &>/dev/null || true
  fi
fi

_ztool_init fnm "$_fnm_bin" "fnm env --use-on-cd --shell zsh"

# FNM's multishell mode may not work in subshells; fallback: add default version to PATH
if ! command -v node &>/dev/null && [[ -x "$_fnm_bin" ]]; then
  _fnm_default=$($_fnm_bin list 2>/dev/null | grep default | awk '{print $2}')
  _fnm_default_bin="${FNM_DIR:-$HOME/.local/share/fnm}/node-versions/${_fnm_default}/installation/bin"
  if [[ -d "$_fnm_default_bin" ]]; then
    export PATH="$_fnm_default_bin:$PATH"
  fi
  unset _fnm_default _fnm_default_bin
fi

unset _fnm_bin

# =============================================================================
# DIRENV (project-specific environments)
# Must initialize before zoxide so project-specific PATH changes apply to cd
# =============================================================================
_direnv_bin="$(command -v direnv 2>/dev/null || echo "$HOME/.local/bin/direnv")"
_ztool_init direnv "$_direnv_bin" "direnv hook zsh"
unset _direnv_bin

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

  # fd/bat command names resolved in modules/platform.zsh (fdfind/batcat on Debian)
  if [[ "$ZSH_FD_CMD" != "find" ]]; then
    export FZF_DEFAULT_COMMAND="$ZSH_FD_CMD --type f --hidden --follow --exclude .git 2>/dev/null"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="$ZSH_FD_CMD --type d --hidden --follow --exclude .git 2>/dev/null"
  fi

  # Ctrl+T preview: file content via bat
  export FZF_CTRL_T_OPTS="
    --preview \"$ZSH_BAT_CMD --color=always --style=numbers --line-range=:100 {} 2>/dev/null || cat {}\"
    --preview-window right:55%:wrap
  "

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
unset -f _ztool_init
unset _ztool_cache
