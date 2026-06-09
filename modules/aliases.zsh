# All aliases organized by category.
# Aliases for optional tools are guarded with $+commands so a missing tool
# never shadows the real command (important across macOS/Linux/WSL).

# =============================================================================
# NAVIGATION
# =============================================================================
alias gg='[[ -n "$GITHUB_USER" ]] && cd ~/code/github/"$GITHUB_USER" || echo "GITHUB_USER not set in modules/local.zsh"'
alias gb='[[ -n "$BITBUCKET_USER" ]] && cd ~/code/bitbucket/"$BITBUCKET_USER" || echo "BITBUCKET_USER not set in modules/local.zsh"'
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
alias drm='docker rm $(docker ps -aq)'  # removes all STOPPED containers (running ones are skipped)
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
# ZSH_BAT_CMD / ZSH_FD_CMD are resolved in modules/platform.zsh
# (bat/fd everywhere except Debian/Ubuntu where they are batcat/fdfind).
# =============================================================================
export BAT_THEME="${BAT_THEME:-TwoDark}"
[[ "$ZSH_BAT_CMD" == "batcat" ]] && alias bat='batcat'
[[ "$ZSH_FD_CMD" == "fdfind" ]] && alias fd='fdfind'

(( $+commands[duf] ))   && alias df='duf'
(( $+commands[dust] ))  && alias du='dust'
(( $+commands[procs] )) && alias pss='procs'

# `g` Go version manager (only when installed via its default location)
[[ -x "$HOME/go/bin/g" ]] && alias g="$HOME/go/bin/g"

alias ik='interactive_kill'
alias qfind='find . -name'
alias rand='openssl rand -base64 32'
alias zshconfig='${VISUAL:-${EDITOR:-vi}} "$ZDOTDIR" && exec zsh'
alias reload='exec zsh'
alias json='python3 -m json.tool'

# =============================================================================
# SYSTEM
# =============================================================================
alias psa='ps aux'
(( IS_LINUX )) && alias free='free -h'   # `free` does not exist on macOS

# =============================================================================
# PLATFORM-SPECIFIC ALIASES
# macOS ships open/pbcopy/pbpaste natively; WSL maps them to Windows tools.
# =============================================================================
if (( IS_WSL )); then
  alias open='explorer.exe'
  alias pbcopy='clip.exe'
  # Use sed instead of tr for more reliable carriage return removal
  alias pbpaste='powershell.exe Get-Clipboard | sed "s/\r$//"'
  alias uuid="cat /proc/sys/kernel/random/uuid | tr -d '\n' | clip.exe"
elif (( IS_MACOS )); then
  alias uuid="uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '\n' | pbcopy"
elif (( IS_LINUX )); then
  (( $+commands[xdg-open] )) && alias open='xdg-open'
  if (( $+commands[wl-copy] )); then
    alias pbcopy='wl-copy' pbpaste='wl-paste'
  elif (( $+commands[xclip] )); then
    alias pbcopy='xclip -selection clipboard' pbpaste='xclip -selection clipboard -o'
  fi
fi

# =============================================================================
# DEVELOPMENT TOOLS
# =============================================================================
(( $+commands[fnm] )) && alias nvm='fnm'  # Use fnm instead of nvm

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
