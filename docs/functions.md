# Functions

All custom functions defined in `modules/functions.zsh`.

---

## mkcd

Create a directory (including intermediate paths) and immediately cd into it.

```
$ mkcd projects/rust/my-crate
~/projects/rust/my-crate

$ mkcd deeply/nested/new/path
~/deeply/nested/new/path
```

---

## extract

Universal archive extractor. Detects format from the file extension and calls
the right tool automatically.

Supports: `.tar.gz` `.tar.bz2` `.tar.xz` `.tar` `.zip` `.rar` `.7z`

```
$ extract archive.tar.gz
# extracts to current directory

$ extract release-v1.2.3.zip
# same — no need to remember tar flags

$ extract nonexistent.tar.gz
File not found: nonexistent.tar.gz

$ extract unknown.lz4
Unknown archive format: unknown.lz4
```

---

## confirm

Interactive yes/no prompt for use in scripts or pipelines. Returns exit code
`0` for yes, `1` for no — composable with `&&`.

```
$ confirm "Delete all logs?" && rm -rf ./logs
Delete all logs? [y/N] y
# logs directory removed

$ confirm "Delete all logs?" && rm -rf ./logs
Delete all logs? [y/N] n
# nothing happens, exit code 1

# Practical use inside a script:
confirm "Deploy to production?" && ./deploy.sh
```

---

## bootstrap

Creates a new Git project directory, runs `git bootstrap` (the custom git
alias from `scripts/git-setup.sh`), and opens it in VS Code.

Requires `scripts/git-setup.sh` to have been run at least once.

```
$ bootstrap my-new-service
# creates ~/...current-dir.../my-new-service/
# runs git init + applies git bootstrap alias (initial commit, branch setup)
# opens the folder in VS Code

$ bootstrap
# no argument — generates a random 13-character alphanumeric folder name
# e.g. creates "k7m2x9p4r1nqz/"

$ bootstrap
Error: 'git bootstrap' alias not found. Run scripts/git-setup.sh first.
# shown when git-setup.sh has not been run
```

---

## interactive_kill (`ik`)

fzf-based process picker. Select one or more processes interactively, then
send `SIGTERM` to all selected PIDs at once.

```
$ ik
# opens fzf with a full process list
# shows the ps header as a sticky fzf header
# Ctrl+Space (or Tab) to multi-select
# Enter to confirm

# after selection:
✓ Killed PIDs: 12345 67890

# ESC or empty selection exits without killing anything
```

Aliased as `ik` in `aliases.zsh`.

---

## upgrade

Comprehensive system upgrade. Runs in sequence:

1. `apt update && apt-get upgrade`
2. `zinit self-update && zinit update --all`
3. `rustup update`
4. `cargo install-update -a`
5. `claude update`
6. Go version check via `go.dev/VERSION` API — updates only if behind
7. `fnm install --lts` + `npm install --global ...`

Prints a version summary at the end.

```
$ upgrade
🔄 Updating package lists...
📦 Upgrading packages...
🧹 Cleaning up...
✅ System upgraded successfully
🔌 Updating zsh plugins...
🦀 Updating Rust...
📦 Updating global Cargo packages...
🤖 Updating Claude CLI...
🐹 Checking Go versions...
✅ Go is already up to date (1.23.4)
🟩 Updating Node.js LTS...
📦 Updating global npm packages...

📋 Installed versions:
  OS:          Ubuntu 24.04.1 LTS
  Kernel:      5.15.167.4-microsoft-standard-WSL2
  Go:          go1.23.4
  Rust:        1.82.0
  Cargo:       1.82.0
  Node:        v22.11.0
  npm:         10.9.0
  Claude:      1.0.7
  Docker:      27.3.1
  Git:         2.47.0
🎉 All done!
```

---

## gcb

fzf git branch checkout helper. Lists local and remote branches, lets you
pick one interactively, and checks it out.

Remote branches (`remotes/origin/...`) automatically create a local tracking
branch instead of leaving you in detached HEAD.

```
$ gcb
# opens fzf with all branches:
#   main
#   feat/parser
#   fix/off-by-one
#   remotes/origin/feat/new-api   ← selecting this creates a local tracking branch

# after selecting "remotes/origin/feat/new-api":
branch 'feat/new-api' set up to track 'origin/feat/new-api'.
Switched to a new branch 'feat/new-api'
```

---

## ports

Show all TCP sockets currently in LISTEN state.

```
$ ports
Netid  State   Local Address:Port   Process
tcp    LISTEN  0.0.0.0:5432         postgres
tcp    LISTEN  0.0.0.0:3000         node
tcp    LISTEN  127.0.0.1:6379       redis-server
```

---

## path

Display PATH entries one per line, numbered. Useful for debugging PATH
ordering after adding new entries.

```
$ path
     1	/home/user/.local/bin
     2	/home/user/.fzf/bin
     3	/home/user/.cargo/bin
     4	/home/user/go/bin
     5	/home/user/.go/bin
     6	/home/user/.config/zsh/bin
     7	/usr/local/bin
     8	/usr/bin
     9	/bin
    10	/usr/sbin
    11	/sbin
```

---

## tmpcd

Create a `mktemp -d` temporary directory and cd into it. For throwaway
experiments that shouldn't clutter your working directories.

```
$ tmpcd
→ /tmp/tmp.k7Xm2pQr4n
/tmp/tmp.k7Xm2pQr4n

$ pwd
/tmp/tmp.k7Xm2pQr4n

# directory is automatically cleaned up by the OS on next reboot
```

---

## zsh-cache-clear

Remove cached eval outputs for the five external tools (starship, zoxide,
fnm, direnv). Forces them to regenerate on the next shell start.

Useful when auto-invalidation via `mtime` doesn't trigger — for example after
a manual config edit that doesn't touch the binary.

```
$ zsh-cache-clear
Removed: /home/user/.cache/zsh/starship.zsh
Removed: /home/user/.cache/zsh/zoxide.zsh
Removed: /home/user/.cache/zsh/fnm.zsh
Removed: /home/user/.cache/zsh/direnv.zsh
Cleared 4 cache file(s). Restart shell to regenerate.

# if caches were already absent:
Cleared 0 cache file(s). Restart shell to regenerate.
```
