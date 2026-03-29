#!/usr/bin/env bash
# scripts/git-setup.sh
# Git configuration factory — applies this full git setup to a new machine.
#
# Usage:
#   ./scripts/git-setup.sh
#   ./scripts/git-setup.sh --name "Your Name" --email "your@email.com"
#
# What it does:
#   1. Creates ~/.config/git/{github,bitbucket}/ directory structure
#   2. Writes main config, per-host configs, global gitignore
#   3. Generates ~/.ssh/id_ed25519 (ed25519) if it doesn't exist
#   4. Configures SSH commit/tag signing (Git 2.34+, no GPG required)
#   5. Creates allowed_signers for local signature verification
#   6. Prints next steps for registering the key on GitHub/Bitbucket
#
# Idempotent: safe to run multiple times. Overwrites config files each run.

set -euo pipefail

# =============================================================================
# ARGUMENTS
# =============================================================================
GIT_NAME=""
GIT_EMAIL=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --name)   GIT_NAME="$2";  shift 2 ;;
    --email)  GIT_EMAIL="$2"; shift 2 ;;
    *) printf "Unknown option: %s\n" "$1" >&2; exit 1 ;;
  esac
done

prompt() {
  local var="$1" label="$2" default="$3"
  if [[ -z "${!var}" ]]; then
    printf "%s [%s]: " "$label" "$default"
    read -r "$var"
    [[ -z "${!var}" ]] && printf -v "$var" '%s' "$default"
  fi
}

prompt GIT_NAME   "Git name"  ""
prompt GIT_EMAIL  "Git email" ""

# =============================================================================
# PATHS
# =============================================================================
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
GIT_DIR="$XDG_CONFIG_HOME/git"
SSH_KEY="$HOME/.ssh/id_ed25519"

mkdir -p "$GIT_DIR/github" "$GIT_DIR/bitbucket" "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# =============================================================================
# SSH SIGNING KEY
# =============================================================================
if [[ ! -f "$SSH_KEY" ]]; then
  printf "Generating SSH key for git signing...\n"
  ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY" -N ""
else
  printf "SSH key already exists: %s\n" "$SSH_KEY"
fi

SSH_PUB=$(cat "${SSH_KEY}.pub")

# allowed_signers — used by `git verify-commit` for local verification
printf "%s %s\n" "$GIT_EMAIL" "$SSH_PUB" > "$GIT_DIR/allowed_signers"

# =============================================================================
# GLOBAL GITIGNORE
# =============================================================================
cat > "$GIT_DIR/ignore" << 'EOF'
.DS_Store
Thumbs.db

.vscode
dist
node_modules
vendor

.env
*.log

**/.claude/settings.local.json
EOF

# =============================================================================
# GITHUB PER-HOST CONFIG
# =============================================================================
cat > "$GIT_DIR/github/.gitconfig" << EOF
[user]
  # SSH key used for both authentication and commit/tag signing.
  # Register on GitHub: Settings → SSH and GPG keys
  #   - Add once as Authentication Key  (enables passwordless push)
  #   - Add once as Signing Key         (shows "Verified" badge on commits)
  #
  # Via CLI (requires admin:public_key + admin:ssh_signing_key scopes):
  #   gh auth refresh -s admin:public_key,admin:ssh_signing_key
  #   gh ssh-key add ~/.ssh/id_ed25519.pub --title "\$(hostname)" --type authentication
  #   gh ssh-key add ~/.ssh/id_ed25519.pub --title "\$(hostname)" --type signing
	signingKey = ~/.ssh/id_ed25519.pub
	name = $GIT_NAME
	email = $GIT_EMAIL
EOF

# =============================================================================
# BITBUCKET PER-HOST CONFIG
# =============================================================================
cat > "$GIT_DIR/bitbucket/.gitconfig" << EOF
[user]
  # SSH key used for commit/tag signing (same key as GitHub).
  # Register on Bitbucket: Personal settings → SSH keys
	signingKey = ~/.ssh/id_ed25519.pub
	name = $GIT_NAME
	email = $GIT_EMAIL
EOF

# =============================================================================
# MAIN GIT CONFIG
# Write template first (literal, no shell expansion), then inject personal values.
# =============================================================================
cat > "$GIT_DIR/config" << 'CONFIG_EOF'
[advice]
	detachedHead = false
[core]
	autocrlf = input
	abbrev = 12
	excludesFile = ~/.config/git/ignore
	filemode = true
	fsmonitor = false
	quotePath = false
	untrackedCache = true
	whitespace = fix,-indent-with-non-tab,trailing-space,cr-at-eol
	pager = delta
	editor = code --wait
[branch]
	autoSetupRebase = always
	sort = -committerdate
[help]
	autoCorrect = 10 # 1 second delay
[init]
	defaultBranch = main
[log]
	date = iso
	showSignature = false
	abbrevCommit = true
	follow = true
[maintenance]
	auto = true
	strategy = incremental
[pull]
	rebase = merges
[blame]
	coloring = highlightRecent
	date = relative
[rebase]
	updateRefs = true
	abbreviateCommands = true
	autoSquash = true
	autoStash = true
[color]
	ui = true
[color "branch"]
	current = yellow reverse
	local = yellow
	remote = green
[color "status"]
	added = yellow
	changed = green
	untracked = cyan
[column]
	ui = auto
[diff]
	algorithm = histogram
	colorMoved = default
	indentHeuristic = true
	mnemonicPrefix = true
	renames = copies
	tool = default-difftool
	wordRegex = [^[:space:]]
[difftool]
	prompt = false
[fetch]
	parallel = 0
	prune = true
	pruneTags = true
	writeCommitGraph = true
[gc]
	cruftPacks = true
[grep]
	column = true
	fullName = true
	lineNumber = true
[interactive]
	singleKey = true
	diffFilter = delta --color-only
[pack]
	writeReverseIndex = true
[revert]
	reference = true
[index]
	threads = 0
[status]
	aheadBehind = true
	showUntrackedFiles = all
[tag]
	sort = version:refname
	gpgSign = true
[transfer]
	fsckObjects = true
[merge]
	autoStash = true
	conflictStyle = zdiff3
	ff = only
	tool = code
[mergetool]
	prompt = false
[push]
	autoSetupRemote = true
	default = simple
	followTags = true
	gpgSign = if-asked
	useForceIfIncludes = true
[sequence]
	editor = code --wait
[rerere]
	autoUpdate = true
	enabled = true
[url "git@github.com:"]
	insteadOf = ggh:
[url "https://github.com/"]
	insteadOf = gh:
[url "https://bitbucket.org/"]
	insteadOf = bb:
[delta]
	features = side-by-side-if-terminal-wide
	navigate = true
	paging = always
	side-by-side = false
	line-numbers = true
	true-color = always
	syntax-theme = TwoDark
	#
	commit-decoration-style = bold yellow box ul
	commit-style = raw
	#
	file-style = bold yellow ul
	file-decoration-style = bold yellow ul box
	#
	hunk-header-style = file line-number syntax
	hunk-header-decoration-style = yellow box
	hunk-header-file-style = bold yellow
	hunk-header-line-number-style = bold magenta
	#
	minus-style = syntax "#340001"
	plus-style = syntax "#012800"
	minus-emph-style = syntax bold "#6f0000"
	plus-emph-style = syntax bold "#005500"
	#
	line-numbers-minus-style = brightred
	line-numbers-plus-style = brightgreen
	line-numbers-zero-style = brightblack
	line-numbers-left-format = " {nm:>4} │ "
	line-numbers-right-format = " {np:>4} │ "
	#
	whitespace-error-style = 22 reverse
[diff "exif"]
	textconv = exiftool
[checkout]
	defaultRemote = origin
[commit]
	cleanup = scissors
	gpgSign = true
	verbose = true
[difftool "default-difftool"]
	cmd = code --wait --diff $LOCAL $REMOTE
[mergetool "code"]
	cmd = code --wait --merge $REMOTE $LOCAL $BASE $MERGED
[includeIf "gitdir:~/Code/GitHub/**/.git"]
	path = ~/.config/git/github/.gitconfig
[includeIf "gitdir:~/Code/BitBucket/**/.git"]
	path = ~/.config/git/bitbucket/.gitconfig
[alias]
	# Basic Operations
	alias = "!f() { git config --get-regexp '^alias\\.' | sed 's/alias\\.//' | sort; }; f"
	review = "!git diff --cached --color=always | less -R"
	whoami = "!f() { \
		printf '\\n%b\\n' '\\033[1;36m━━ Git Configuration ━━\\033[0m'; \
		printf '%b %s\\n' '\\033[1;32m✓\\033[0m Name:' \"$(git config user.name)\"; \
		printf '%b %s\\n' '\\033[1;32m✓\\033[0m Email:' \"$(git config user.email)\"; \
		printf '%b %s\\n' '\\033[1;32m✓\\033[0m Signing key:' \"$(git config user.signingkey)\"; \
		printf '%b %s\\n' '\\033[1;32m✓\\033[0m GPG format:' \"$(git config gpg.format)\"; \
		printf '%b\\n\\n' '\\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━\\033[0m'; \
	}; f"
	edit-last = commit --amend --no-verify
	fresh = "!f() { git checkout -b \"$1\" && git push -u origin \"$1\"; }; f"
	wip = "!git add -A && git commit -m 'WIP: work in progress'"
	fixup = "!f() { git commit --fixup \"$1\"; }; f"
	autofixup = "!git rebase -i --autosquash HEAD~$(git rev-list --count HEAD ^origin/main)"
	conf = "!f() { git config --global --edit && echo '✓ Config saved'; }; f"
	addp = add --patch
	add-all = add --all
	unstage = restore --staged
	discard = restore --worktree
	# Commit Operations
	mnd = commit --all --amend --no-edit
	amend = commit --amend --reuse-message=HEAD
	undo = reset HEAD~1 --mixed
	recommit = commit --amend -m
	# Branch Operations
	br = branch
	bra = branch --all
	brd = branch --delete
	brv = branch --verbose --verbose
	current = branch --show-current
	# Merge Operations
	mff = merge --no-ff
	mmsg = merge --no-edit
	pick = cherry-pick --no-commit
	cont = rebase --continue
	# Stash Operations
	stashk = stash push --keep-index
	stash-all = stash push --include-untracked
	stash-pop = stash pop
	# Rebase Operations
	rebase-onto = "!f() { git rebase --onto ${1-main} ${2-main}; }; f"
	reb = "!r() { git rebase --interactive HEAD~$1; }; r"
	rebase-branch = "!f() { git rebase --interactive $(git merge-base HEAD ${1-main}); }; f"
	resign = "!r() { git rebase --interactive HEAD~$1 --exec \"git commit --amend -S --no-edit --no-verify\"; }; r"
	# Remote Operations
	fp = fetch --all --prune
	pushf = push --force-with-lease --force-if-includes
	promi = "!r() { git pull --rebase=interactive origin ${1-main}; }; r"
	sync = "!f() { git fetch origin ${1-main} && git rebase origin/${1-main}; }; f"
	# Log and History
	lg = log --graph \
		--abbrev-commit \
		--decorate \
		--all \
		--date=relative \
		--format=format:'%C(bold blue)%h%C(reset) %C(bold yellow)%d%C(reset) %C(white)%s%C(reset) %C(bold cyan)(%an)%C(reset) %C(bold green)(%ar)%C(reset)'
	lga = log --graph \
		--abbrev-commit \
		--decorate \
		--date=relative \
		--format=format:'%C(bold blue)%h%C(reset)%C(bold yellow)%d%C(reset) %C(white)%s%C(reset) %C(bold green)(%ar)%C(reset)' \
		--all
	log-summary = log --oneline --graph --decorate --all
	new = log --graph main..HEAD --oneline
	missing = log --graph HEAD..main --oneline
	ahead = log main..HEAD --oneline
	behind = log HEAD..main --oneline
	commits-today = log --since=today --oneline
	# Status and Diff
	st = "!git status --short --branch --color=always"
	diff-tool = difftool --dir-diff
	staged-files = diff --cached --name-only
	unstaged-files = diff --name-only
	all-changes = diff HEAD --name-only
	# Maintenance and Cleanup
	cleanup = "!f() { \
		echo '🧹 Cleaning merged branches...'; \
		git branch --merged main | grep -v '* main' | xargs -r git branch -d; \
		echo '✅ Done'; \
	}; f"
	gc-aggressive = gc --aggressive --prune=now
	bootstrap = "!f() { \
		echo \"🚀 Bootstrapping new Git repository...\"; \
		git init || return 1; \
		echo \"⚙️ Registering maintenance...\"; \
		git maintenance register || return 1; \
		git maintenance start || return 1; \
		echo \"🎯 Creating initial commit...\"; \
		git commit --allow-empty --message 'chore: initial commit' \
			$(git config --get commit.gpgsign | grep -q true && echo '-S') || return 1; \
		echo \"✅ Repository bootstrap complete!\"; \
	}; f"
	# Search
	find-commit = log --oneline --grep
	find-author = log --oneline --author
	find-file = log --oneline --name-only
	find-deleted = log --oneline --diff-filter=D --summary
	# Statistics
	stats = log --stat --oneline
	authors = log --format='%aN' | sort | uniq -c | sort -rn
	lines-changed = log --format=medium --numstat
	# Quick commit shortcuts
	ac = "!git add --all && git commit --verbose"
	acm = "!f() { git add --all && git commit -m \"$1\"; }; f"
	changed = show --name-status
	recent = branch --sort=-committerdate --format='%(refname:short) %(committerdate:relative)'
	contributors = shortlog -sn
	diff-main = "!git diff origin/main...HEAD --stat"
	commits-week = "!git log --since='1 week ago' --oneline"
	top-authors = "!git shortlog -sn --all | head -10"
	what = "!git log --oneline -n 10"
	mine = "!git log --author=\"$(git config user.name)\" --oneline"
	ignore = "!f() { echo \"$1\" >> .gitignore; }; f"
	restore-file = "!f() { git checkout HEAD -- \"$1\"; }; f"
	untrack = "rm --cached"
	hotspots = "!git log -p --all -S \"\" --numstat | grep '^[0-9]' | awk '{print $3}' | sort | uniq -c | sort -rn | head"
	impact = "!git diff --cached --numstat | awk '{added+=$1; removed+=$2} END {print \"Lines added: \" added \", Lines removed: \" removed}'"
	blame-line = "!f() { git blame -L $2,$2 $1; }; f"
	stash-list = stash list --format="%C(yellow)%gd%C(reset) %s"
	root = rev-list --max-parents=0 HEAD
	stale = branch --sort=committerdate --format='%(committerdate:relative)%09%(refname:short)'
	resign-branch = "!git rebase --exec 'git commit --amend --no-edit -S' $(git merge-base HEAD main)"
[user]
	signingKey = ~/.ssh/id_ed25519.pub
	name = __GIT_NAME__
	email = __GIT_EMAIL__
[gpg]
	format = ssh
[gpg "ssh"]
	allowedSignersFile = ~/.config/git/allowed_signers
CONFIG_EOF

# Inject personal values (sed delimiter | avoids conflicts with path slashes)
sed -i \
  -e "s|__GIT_NAME__|$GIT_NAME|g" \
  -e "s|__GIT_EMAIL__|$GIT_EMAIL|g" \
  "$GIT_DIR/config"

# =============================================================================
# GITHUB CREDENTIAL HELPER (gh CLI)
# Write directly to $GIT_DIR/config instead of --global, because GIT_CONFIG_GLOBAL
# may not be set yet when this script runs (it is set by .zprofile at login time).
# Using --global here would write to ~/.gitconfig and conflict with the XDG config.
# =============================================================================
GH_BIN=$(command -v gh 2>/dev/null || true)
if [[ -n "$GH_BIN" ]]; then
  git config --file "$GIT_DIR/config" credential."https://github.com".helper ""
  git config --file "$GIT_DIR/config" --add credential."https://github.com".helper "!$GH_BIN auth git-credential"
  git config --file "$GIT_DIR/config" credential."https://gist.github.com".helper ""
  git config --file "$GIT_DIR/config" --add credential."https://gist.github.com".helper "!$GH_BIN auth git-credential"
fi

# =============================================================================
# NEXT STEPS
# =============================================================================
printf "\n✅ Git configuration applied to %s\n\n" "$GIT_DIR"
printf "📋 Next steps:\n"
printf "   1. Register SSH key on GitHub (shows 'Verified' badge on commits):\n"
printf "      gh auth refresh -s admin:public_key,admin:ssh_signing_key\n"
printf "      gh ssh-key add ~/.ssh/id_ed25519.pub --title \"%s\" --type authentication\n" "$(hostname)"
printf "      gh ssh-key add ~/.ssh/id_ed25519.pub --title \"%s\" --type signing\n\n" "$(hostname)"
printf "   2. Verify signing works:\n"
printf "      git commit --allow-empty -S -m 'test: ssh signing'\n"
printf "      git log --show-signature -1\n\n"
printf "   3. Set GIT_CONFIG_GLOBAL in your shell profile (~/.config/zsh/.zprofile):\n"
printf "      export GIT_CONFIG_GLOBAL=\"\$HOME/.config/git/config\"\n\n"
printf "   Public key:\n"
printf "      %s\n" "$SSH_PUB"
