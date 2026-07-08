echo "2. Sourcing .zshrc"

setopt ALWAYS_TO_END
setopt AUTO_CD
setopt AUTO_PUSHD
setopt BG_NICE
setopt CDABLE_VARS
setopt COMBINING_CHARS
setopt COMPLETE_IN_WORD
setopt EXTENDED_GLOB
setopt EXTENDED_HISTORY
setopt GLOB_DOTS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt NO_NOMATCH
setopt NOTIFY
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt RC_QUOTES
setopt SHARE_HISTORY

ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME/.git" ]]; then
  print -P "%F{33}Installing Zinit...%f"
  command mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || {
    print -P "%F{160}Zinit installation failed.%f"
    return 1
  }
fi
source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit wait lucid blockf \
  atload'zicompinit; zicdreplay' \
  for zsh-users/zsh-completions

zinit wait lucid for \
  atload'_zsh_autosuggest_start' \
  zsh-users/zsh-autosuggestions \
  zsh-users/zsh-history-substring-search \
  zdharma-continuum/fast-syntax-highlighting \
  MichaelAquilina/zsh-you-should-use \
  Aloxaf/fzf-tab \
  hlissner/zsh-autopair

zinit wait'0' lucid for wfxr/forgit

zinit wait"1" lucid for \
  OMZP::golang \
  OMZP::rust \
  OMZP::docker \
  OMZP::docker-compose \
  OMZP::npm \
  OMZP::mise

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/compcache"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs false
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,%cpu,command"
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons --color=always $realpath 2>/dev/null || ls $realpath'

zstyle ':fzf-tab:complete:(ls|la|ll|lt):*' fzf-preview \
  'if [[ -d $realpath ]]; then
     eza -1 --icons --color=always $realpath 2>/dev/null || ls $realpath
   else
     bat --color=always --style=numbers --line-range=:50 $realpath 2>/dev/null || cat $realpath
   fi'

zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps -p $word -o command='
zstyle ':fzf-tab:*' switch-group '<' '>'

if (( $+commands[eza] )); then
  alias ls='eza -F --icons --git'
  alias l='eza -F --icons'
  alias la='eza -laF --icons --git'
  alias ll='eza -laF --icons --git --group-directories-first'
  alias lt='eza -T --icons --git-ignore'
else
  alias l='ls -l'
  alias ll='ls -la'
  alias la='ls -la'
fi

_ztool_cache() {
  local name=$1 cache="$XDG_CACHE_HOME/zsh/${name}.zsh"
  shift
  if [[ ! -f "$cache" || "$(command -v "$name")" -nt "$cache" ]]; then
    "$@" >| "$cache" 2>/dev/null
  fi
  source "$cache"
}

_ztool_cache starship starship init zsh
_ztool_cache zoxide zoxide init zsh

export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border rounded
  --bind ctrl-/:toggle-preview
  --bind alt-j:preview-down
  --bind alt-k:preview-up
'

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null'

export FZF_CTRL_T_OPTS='
  --preview "bat --color=always --style=numbers --line-range=:100 {} 2>/dev/null || cat {}"
  --preview-window right:55%:wrap
'

export FZF_ALT_C_OPTS='
  --preview "eza -1 --icons --color=always {} 2>/dev/null || ls {}"
  --preview-window right:55%:wrap
'

_ztool_cache fzf fzf --zsh

# alias reload='ZDOTDIR= exec -l zsh'
alias reload='exec -l zsh'
