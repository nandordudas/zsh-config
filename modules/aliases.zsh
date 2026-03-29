# All aliases organized by category

# =============================================================================
# NAVIGATION
# =============================================================================
alias gg="cd ~/Code/GitHub/${GITHUB_USER}"
alias gb="cd ~/Code/BitBucket/${BITBUCKET_USER}"
alias cr='code --reuse-window .'

# =============================================================================
# FILE LISTING (eza)
# =============================================================================
alias ls='eza -F --icons --git'
alias l='eza -F --icons'
alias la='eza -laF --icons --git'
alias ll='eza -laF --icons --git --group-directories-first'
alias lt='eza -T --icons --git-ignore'

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
alias ~='cd ~'
alias cdd='cd -'  # Back to previous directory

# =============================================================================
# DOCKER
# =============================================================================
alias dc='docker compose'
alias dc-up='UID=$(id -u) GID=$(id -g) docker compose up'
alias dc-down='docker compose down'
alias dc-exec='docker compose exec'
alias dc-logs='docker compose logs -f'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -qf dangling=true)'

# =============================================================================
# GIT (quick aliases - forgit plugin provides more)
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
# TOOLS & UTILITIES
# =============================================================================
alias bat='batcat --theme TwoDark'
alias fd='fdfind'
alias df='duf'
alias du='dust'
alias pss='procs'
alias g="$HOME/go/bin/g"
alias ik='interactive_kill'
alias qfind='find . -name'
alias rand='openssl rand -base64 32'
alias zshconfig='code --wait "$ZDOTDIR/.zshrc" && exec zsh'
alias reload='exec zsh'
alias json='python3 -m json.tool'

# =============================================================================
# SYSTEM
# =============================================================================
alias psa='ps aux'
alias free='free -h'

# =============================================================================
# WSL-SPECIFIC ALIASES
# =============================================================================
if (( IS_WSL )); then
  alias open='explorer.exe'
  alias pbcopy='clip.exe'
  alias pbpaste='powershell.exe Get-Clipboard | tr -d "\r"'
  alias uuid="cat /proc/sys/kernel/random/uuid | tr -d '\n' | clip.exe"
fi

# =============================================================================
# DEVELOPMENT TOOLS
# =============================================================================
alias nvm='fnm'  # Use fnm instead of nvm

# =============================================================================
# CARGO (Rust)
# =============================================================================
alias cb='cargo build'
alias ct='cargo test'
alias crun='cargo run'
alias cc='cargo check'
alias cf='cargo fmt'
alias clippy='cargo clippy -- -D warnings'

# =============================================================================
# GO
# =============================================================================
alias got='go test ./...'
alias gomod='go mod tidy'
alias gocover='go test -coverprofile=/tmp/cover.out ./... && go tool cover -html=/tmp/cover.out'

# =============================================================================
# NODE / PNPM
# =============================================================================
alias taze='taze -r'  # Check all workspaces for outdated deps
