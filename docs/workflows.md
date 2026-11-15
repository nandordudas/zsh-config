# The Shell Playbook

A narrative guide to everyday development with this zsh configuration.
Read it top to bottom the first time; return to individual chapters as a reference.

---

## Chapter 1 — Starting a New Project

You have an idea. The fastest path from nothing to a signed, tracked git repository is two commands.

### Navigate to your code directory

```sh
gg
```

`gg` expands to `cd $CODE_DIR/github/$GITHUB_USER`. You land directly in your GitHub projects root. No typing long paths, no getting lost. Set `GITHUB_USER` in `modules/local.zsh` once and it works forever.

### Create the directory and enter it

```sh
mkcd my-new-service
```

`mkcd` is a custom function (`modules/functions.zsh`) that combines `mkdir -p` and `cd` in one step. All intermediate directories are created automatically. You are now inside the new, empty folder.

### Bootstrap the git repository

```sh
git bootstrap
```

This git alias (installed by `scripts/git-setup.sh`) does four things in sequence:

1. `git init` — initialises the repository
2. `git maintenance register` — registers the repo for background optimisation
3. `git maintenance start` — activates scheduled pack and commit-graph jobs
4. Creates an empty initial commit, signed with your SSH key

The result is a properly structured, signed, and maintained repository before you write a single line of code. The `bootstrap` shell function wraps this and also opens VS Code:

```sh
bootstrap my-new-service
# equivalent to: mkcd my-new-service && git bootstrap && code .
```

If no name is given, `bootstrap` generates a random 13-character folder name — useful for throwaway experiments.

### Verify the setup

```sh
git whoami
```

Prints your configured name, email, and signing key in one glance. Run this on any machine after `git-setup.sh` to confirm identity is correct before your first commit.

---

## Chapter 2 — Checking What's Around You

Before writing code, orient yourself. This config replaces several standard tools with richer alternatives.

### List files

```sh
ls          # icons + git status indicators, one line per entry
ll          # long form, git status, directories first
la          # long form including hidden files
lt          # tree view, respects .gitignore
```

All four are powered by `eza`. The git column in `ls` / `ll` / `la` shows whether each file is modified, staged, untracked, or clean — at a glance, without running `git status`.

### Inspect a file

```sh
bat README.md
```

`bat` replaces `cat` with syntax highlighting, line numbers, and git diff markers in the gutter. Theme is set via `BAT_THEME` (default `TwoDark`), configurable in `modules/local.zsh`.

### Find files by name

```sh
qfind "*.toml"
# expands to: find . -name "*.toml"
```

### Search inside files — ripgrep

`rg` is the primary search tool. It respects `.gitignore` by default, is dramatically faster than `grep`, and colourises matches.

```sh
rg 'TODO'                          # search current directory recursively
rg 'fn parse' src/                 # restrict to a subdirectory
rg -t go 'context.Context'         # search only .go files
rg -l 'import React'               # print matching filenames only
rg -c 'error'                      # count matches per file
rg --hidden 'SECRET'               # include hidden files
rg -i 'readme'                     # case-insensitive
rg -n 'func main' --line-number    # show line numbers (default behaviour)
```

Combine with fzf for interactive search:

```sh
rg --line-number '' | fzf --delimiter ':' --preview 'bat --color=always {1} --highlight-line {2}'
```

### Check disk usage

```sh
du src/       # dust: tree-style breakdown of directory sizes
df            # duf: colourised table of mount points and free space
```

### See what is listening on ports

```sh
ports
```

Custom function (`modules/functions.zsh`) that calls `lsof -iTCP -sTCP:LISTEN`. Shows PID, command, and port for every TCP listener. Useful before starting a dev server to check if the port is already taken.

---

## Chapter 3 — The Git Workflow

This config installs a rich set of git aliases. They live in `~/.config/git/config` under `[alias]`.

### Check status quickly

```sh
git st        # git status --short --branch — compact, coloured
gs            # zsh alias for git status (verbose form)
```

### Stage and commit

```sh
gaa           # git add -A (stage everything)
gcm "fix: correct off-by-one in parser"   # git commit -m
```

Or stage and commit in one step:

```sh
git acm "feat: add request validation"
# expands to: git add --all && git commit -m "..."
```

For a patch-mode review of what you are staging:

```sh
git addp      # git add --patch — stage hunks interactively
git review    # git diff --cached piped through delta — see exactly what will be committed
```

### Commit with conventional scope

```sh
git scope "feat" "auth" "add JWT refresh token"
# commits: feat(auth): add JWT refresh token
```

### Save work in progress

```sh
gwip          # git add -A && git commit -m "wip: HH:MM"
gunwip        # undo the wip commit, restoring changes to working tree
```

Use `gwip` before switching context. `gunwip` brings everything back when you return.

### Stash

```sh
gst           # git stash push
gstp          # git stash pop
gstl          # git stash list (colourised)
git stashk    # stash but keep the index (staged changes stay staged)
git stash-all # include untracked files in the stash
```

---

## Chapter 4 — Navigating Branches

### See all branches

```sh
git br        # local branches
git bra       # all branches including remote
git brv       # verbose: shows tracking and ahead/behind counts
git recent    # last 15 branches by commit date — most active work first
git stale     # oldest 15 branches — candidates for deletion
```

### Switch branches — interactively

```sh
gcb
```

`gcb` (from the **forgit** plugin) opens an fzf picker with all local and remote branches. Selecting a remote branch automatically creates a local tracking branch — no detached HEAD.

### Create and push a branch

```sh
git fresh feat/user-auth
# git checkout -b feat/user-auth && git push -u origin feat/user-auth
```

The upstream is set immediately, so your first `git push` and `git pull` work without extra flags.

### See what your branch contains

```sh
git new       # commits on current branch not on main (ahead)
git missing   # commits on main not on current branch (behind)
git what      # last 10 commits, one line each
```

---

## Chapter 5 — Rebasing and Cleaning History

Rebase is enabled by default in this config (`branch.autoSetupRebase = always`, `pull.rebase = merges`). Every pull rebases instead of merging.

### Sync with main

```sh
git rebase-main
# fetch origin main + rebase current branch onto it
```

Or use the zsh alias that does the same and handles the upstream automatically:

```sh
git sync
```

### Interactive rebase — rewrite the last N commits

```sh
git reb 3     # interactive rebase of last 3 commits
```

Opens your `$EDITOR` (VS Code, waiting for you to close the tab) with the rebase todo list. Common operations:

- `pick` — keep as-is
- `reword` (or `r`) — change the commit message
- `squash` (or `s`) — melt into the previous commit
- `fixup` (or `f`) — squash silently (discard the message)
- `drop` (or `d`) — delete the commit entirely

### Fixup workflow — clean up as you go

```sh
# make a mistake in commit abc1234, then:
git fixup abc1234     # creates a fixup! commit targeting abc1234
git autofixup         # rebases interactively with --autosquash, placing
                      # the fixup commit next to its target automatically
```

### Rebase a branch onto main (no merge commits)

```sh
git rebase-branch main
# interactive rebase from the point where your branch diverged from main
```

### Continue after a conflict

```sh
# resolve conflicts in editor, then:
git add the-resolved-file.go
git cont              # git rebase --continue
```

### Force push safely

```sh
git pushf
# git push --force-with-lease --force-if-includes
# refuses to push if the remote has commits you have not fetched —
# prevents accidentally overwriting someone else's work
```

---

## Chapter 6 — Reading History

### Pretty log

```sh
gl            # zsh alias — graph, all branches, relative dates, one line
git lg        # more colourful version with author and relative time
git lga       # minimal — just hash, branch labels, subject, date
```

### Find commits by message

```sh
git find-commit "parser"
# git log --oneline --grep "parser"
```

### Find commits by author

```sh
git find-author "alice"
git mine              # commits by you (uses git config user.name)
```

### Find commits touching a file

```sh
git find-file -- src/parser.go
```

### Find when a line was deleted

```sh
git find-deleted-line "function parseToken"
# searches all history for diffs adding or removing this string
```

### Time-bounded queries

```sh
git commits-today
git commits-week
git commits-since "2024-01-01"
```

### Who changed what

```sh
git hotspots
# top 20 most frequently changed files — useful for finding high-churn areas
git top-authors
git authors
```

### Compare staged / unstaged / all changes

```sh
git staged-files      # files in the index (ready to commit)
git unstaged-files    # modified but not staged
git all-changes       # everything changed since HEAD
git diff-main         # stat of all changes between current branch and main
```

---

## Chapter 7 — Searching Inside Git History

### Search for a string across all commits

```sh
git log -S "secretValue" --all
# shows every commit that added or removed this exact string
```

### Search by regex

```sh
git log -G "func Parse.*" --all --oneline
```

### Find a deleted function

```sh
git find-function "parseToken"
# searches .js .go .php .ts files for the function definition
```

### Blame a specific line range

```sh
git blame-line src/parser.go 42 60
# shows who last touched lines 42-60
```

Blame output uses relative dates and highlights recent changes (`blame.coloring = highlightRecent`).

---

## Chapter 8 — fzf: Fuzzy Finding Everything

`fzf` is wired into the shell via keybindings. No command to remember — just use the shortcuts.

| Shortcut | What it does |
|---|---|
| `Ctrl+T` | Fuzzy-pick a file and paste its path at the cursor |
| `Ctrl+R` | Fuzzy-search shell history and paste the selected command |
| `Option+C` (⌥C) | Fuzzy-pick a directory and cd into it |

All three open a full-screen selector. `Ctrl+T` shows a file preview via `bat`. `Option+C` shows a directory listing via `eza`.

Additional fzf bindings inside the selector:

| Key | Action |
|---|---|
| `Ctrl+/` | Toggle preview panel |
| `Option+J` (⌥J) | Scroll preview down |
| `Option+K` (⌥K) | Scroll preview up |

Tab completion is enhanced by the **fzf-tab** plugin: pressing `Tab` after a partial command opens an fzf popup instead of the standard inline menu. Works for git branches, file paths, process names, and more.

---

## Chapter 9 — zoxide: Smart Directory Jumping

`zoxide` learns from your `cd` history and lets you jump anywhere with a fragment.

```sh
z my-service          # jump to the most frecent path matching "my-service"
z gith nand pars      # multiple tokens — narrows the match
z -                   # jump to previous directory (same as cd -)
zi                    # interactive picker via fzf — see all matches
```

`zoxide` replaces `cd` for navigating to known places. Use real `cd` (or `..`) only for relative navigation. After a few days of normal work, `z` becomes significantly faster than any alias.

---

## Chapter 10 — Recovery and Undo

Mistakes happen. These are your escape hatches.

### Undo the last commit (keep changes)

```sh
git undo
# git reset --soft HEAD~1 — commit is gone, files are staged
```

### Amend the last commit

```sh
git amend               # reuse the current message, update content
git edit-last           # opens $EDITOR for message + content (skips hooks)
git recommit "new message"
```

### Undo a push

```sh
git undo-push
# force-pushes HEAD~1 to the remote branch — removes the last pushed commit
# only safe on feature branches you own
```

### Discard working-tree changes

```sh
git discard
# shows what will be lost, asks for confirmation, then git restore --worktree
```

### Restore a specific file from HEAD

```sh
git restore-file src/parser.go
```

### Stop tracking a file (keep it on disk)

```sh
git untrack .env
# git rm --cached .env — removes from index, file stays in working tree
```

### Emergency: hard reset

```sh
git reset-hard
# prompts: "Type YES to confirm" before doing git reset --hard
# the confirmation guard makes accidental data loss much harder
```

### Find lost commits

```sh
git reflog
# shows every position HEAD has been in — commits are recoverable for 90 days
```

---

## Chapter 11 — Maintenance and Health

### Run a full system upgrade

```sh
upgrade
```

Upgrades Homebrew, Zinit plugins, Rust toolchain, mise runtimes, and Claude CLI in parallel. Shows a spinner per job, then prints a version summary when all are done.

```sh
upgrade --only mise,rust    # selective
upgrade --dry-run           # preview without executing
```

### Check that everything is wired up

```sh
zsh-health
```

Scans for core tools (git, fzf, eza, bat, fd), language runtimes (Rust, Node, Python), PATH entries, and shell configuration. Prints a green checkmark or a warning for each item. Run this after a fresh install or if something stops working.

### Reload config after changes

```sh
reload        # exec zsh — replaces the current shell process
zshconfig     # open the config directory in $EDITOR, then auto-reload on close
```

### Clear tool init caches

```sh
zsh-cache-clear
# removes cached starship/zoxide/mise/fzf init scripts
# forces regeneration on next shell start
```

---

## Chapter 12 — Temporary Workspaces

Sometimes you need a throwaway environment.

### Temporary directory

```sh
tmpcd
# creates a mktemp -d directory and cd into it
# printed path so you can find it again
# cleaned up by the OS on reboot
```

### Throwaway project

```sh
bootstrap
# no name given → random 13-char folder name
# full git bootstrap, opens VS Code
```

### Kill a stuck process

```sh
ik
# opens fzf with the full process list
# Ctrl+Space or Tab to multi-select multiple processes
# Enter sends SIGTERM to all selected PIDs
```

---

## Quick Reference Card

```
NAVIGATION
  gg / gb              jump to GitHub / Bitbucket code root
  z <fragment>         smart jump to any visited directory
  mkcd <path>          create directory and cd into it
  ..  ~  cdd           up one level / home / previous directory
  cd -N                jump to Nth previous directory in stack

FILES
  ls / ll / la / lt    eza variants (icons, git status, tree)
  bat <file>           syntax-highlighted file viewer
  qfind "*.ext"        find by name
  rg <pattern>         ripgrep — fast recursive file search

GIT: DAILY
  git st               short status
  git acm "message"    add all + commit
  git sync             fetch + rebase onto upstream
  git pushf            force-push safely
  git undo             soft reset last commit
  gcb                  interactive branch picker (fzf)
  git fresh <name>     create + push branch

GIT: HISTORY
  gl / git lg          pretty graph log
  git what             last 10 commits
  git new / missing    ahead / behind main
  git find-commit X    search log messages
  git mine             your commits

GIT: REBASE
  git rebase-main      sync with origin/main
  git reb 3            interactive rebase last 3 commits
  git fixup <hash>     create fixup! commit
  git autofixup        squash fixups automatically
  git cont             rebase --continue

FZF
  Ctrl+T               fuzzy file picker
  Ctrl+R               fuzzy history search
  ⌥C                   fuzzy directory jump
  Tab                  enhanced completion (fzf-tab)

SHELL
  upgrade              full system upgrade
  zsh-health           check all tools
  ik                   interactive process kill
  ports                show listening ports
  reload               restart shell
```

---

*All aliases live in `modules/aliases.zsh`. All functions live in `modules/functions.zsh`. Git aliases live in `~/.config/git/config` under `[alias]`. Run `git alias` to list every git alias with descriptions.*
