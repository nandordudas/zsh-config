# All aliases organized by category.
# Aliases for optional tools are guarded with $+commands so a missing tool
# never shadows the real command.

# =============================================================================
# NAVIGATION
# =============================================================================
# CODE_DIR (default ~/Development/code) is set in .zprofile, override in local.zsh
alias gg='[[ -n "$GITHUB_USER" ]] && cd "${CODE_DIR:-$HOME/Development/code}/github/$GITHUB_USER" || echo "GITHUB_USER not set in modules/local.zsh"'
alias gb='[[ -n "$BITBUCKET_USER" ]] && cd "${CODE_DIR:-$HOME/Development/code}/bitbucket/$BITBUCKET_USER" || echo "BITBUCKET_USER not set in modules/local.zsh"'
alias cr='code --reuse-window .'

# =============================================================================
# FILE LISTING (eza, falls back to plain ls if missing)
# =============================================================================
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

# =============================================================================
# FILE OPERATIONS
# =============================================================================
alias mkdir='mkdir -p'
alias rm='rm -i'     # Confirm before deletion
alias cp='cp -i'     # Confirm before overwrite
alias mv='mv -i'     # Confirm before overwrite

# =============================================================================
# DIRECTORY SHORTCUTS
# =============================================================================
alias ..='cd ..'
alias cdd='cd -'  # Back to previous directory

# =============================================================================
# DOCKER
# Most common aliases are provided by OMZP::docker and OMZP::docker-compose.
# These are custom extensions that don't conflict with the plugin aliases.
# =============================================================================
alias dc-up='UID=$(id -u) GID=$(id -g) docker compose up'  # injects host UID/GID
alias drm='docker rm $(docker ps -aq)'  # removes all stopped containers (errors on running ones — they are kept)
alias drmi='docker rmi $(docker images -qf dangling=true)'  # dangling images only

# =============================================================================
# GIT (quick aliases; forgit plugin provides powerful interactive ones)
# =============================================================================
alias gs='git status'
alias gp='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gcm='git commit -m'
alias gaa='git add -A'
alias gl='git log --oneline --graph --decorate --all'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gwip='git add -A && git commit -m "wip: $(date +%H:%M)"'
alias gunwip='git log -n 1 --format=%s | grep -q "^wip" && git reset HEAD~1'

# =============================================================================
# TOOLS & UTILITIES (command replacements and shortcuts)
# =============================================================================
export BAT_THEME="${BAT_THEME:-TwoDark}"

(( $+commands[duf] ))   && alias df='duf'
(( $+commands[dust] ))  && alias du='dust'
(( $+commands[procs] )) && alias pss='procs'

alias ik='interactive_kill'
alias qfind='find . -name'
alias rand='openssl rand -base64 32'
# ${=EDITOR} word-splits "code --wait" so the shell waits for the editor
# to close before reloading
alias zshconfig='${=EDITOR:-vi} "$ZDOTDIR" && exec zsh'
alias reload='exec zsh'
# jq comes from the Brewfile; python3 fallback needs Xcode CLT
if (( $+commands[jq] )); then
  alias json='jq .'
else
  alias json='python3 -m json.tool'
fi

# =============================================================================
# SYSTEM (macOS)
# open / pbcopy / pbpaste are native on macOS.
# =============================================================================
alias psa='ps aux'
alias uuid="uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '\n' | pbcopy"

# =============================================================================
# CARGO (Rust)
# =============================================================================
alias cb='cargo build'
alias ct='cargo test'
alias crun='cargo run'
alias cch='cargo check'  # not `cc` — that would shadow the system C compiler
alias cf='cargo fmt'
alias clippy='cargo clippy -- -D warnings'

# =============================================================================
# GO (Most aliases provided by OMZP::golang)
# =============================================================================
alias gocover='go test -coverprofile=/tmp/cover.out ./... && go tool cover -html=/tmp/cover.out'

# =============================================================================
# NODE / PNPM
# =============================================================================
(( $+commands[taze] )) && alias taze='taze -r'  # Check all workspaces for outdated deps

# =============================================================================
# TMUX
# =============================================================================
alias tm='tmux new-session -A -s main'   # attach to 'main' or create it
alias ta='tmux attach-session -t'        # attach to named session
alias tl='tmux list-sessions'
alias tn='tmux new-session -s'           # new named session
alias tk='tmux kill-session -t'
