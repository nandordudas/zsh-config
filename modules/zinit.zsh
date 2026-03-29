# modules/zinit.zsh
# Plugin manager bootstrap and all plugin declarations.
#
# Loading strategy:
#   - No Zinit annexes (none are used by this config)
#   - All plugins in turbo mode (wait/lucid) so the prompt appears immediately
#
# Completion init order (critical):
#   zsh-completions loads first via blockf (registers completion functions in fpath)
#   zicompinit runs ONCE via atload on zsh-completions
#   zicdreplay replays all blockf fpath registrations accumulated during turbo load
#   fzf-tab loads AFTER compinit (it wraps the completion system)

# =============================================================================
# PLUGIN CONFIGURATION
# Set before plugin loading so plugins see these values at load time.
# =============================================================================

# zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# zsh-you-should-use
export YSU_MESSAGE_POSITION="after"
export YSU_HARDCORE=0

# =============================================================================
# ZINIT BOOTSTRAP
# =============================================================================
ZINIT_HOME="${XDG_DATA_HOME}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
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

# =============================================================================
# PLUGIN LOADING (all turbo mode)
# =============================================================================

# Group 1: Completions infrastructure
# blockf: lets zinit manage fpath instead of the old compinit way
# atload'zicompinit; zicdreplay': initialize completion system ONCE after this plugin
# This is the ONLY place zicompinit; zicdreplay should appear.
zinit wait lucid blockf \
  atload'zicompinit; zicdreplay' \
  for zsh-users/zsh-completions

# Group 2: UI enhancement plugins
# fzf-tab MUST load after compinit (zicompinit above triggers it)
zinit wait lucid for \
  atload'_zsh_autosuggest_start' \
    zsh-users/zsh-autosuggestions \
  zsh-users/zsh-history-substring-search \
  zdharma-continuum/fast-syntax-highlighting \
  MichaelAquilina/zsh-you-should-use \
  Aloxaf/fzf-tab \
  hlissner/zsh-autopair

# Group 3: Git tooling (1 second delay — only needed when user types git commands)
zinit wait"1" lucid for \
  wfxr/forgit

# Group 4: Completions for language toolchains and Docker
# Loaded with a 1-second delay — not needed at prompt time.
zinit wait"1" lucid for \
  OMZP::golang \
  OMZP::rust \
  OMZP::docker \
  OMZP::docker-compose \
  OMZP::npm
