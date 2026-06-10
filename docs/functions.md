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

Comprehensive parallel system upgrade. Smart recovery from network failures.

**Usage:**
```bash
upgrade                          # Full upgrade (all tools)
upgrade --only mise,rust         # Selective (just mise runtimes + rust)
upgrade --dry-run                # Preview without executing
upgrade --dry-run --only claude  # Preview specific tools
```

**What it upgrades (parallel jobs):**
- **Homebrew**: `brew update && brew upgrade && brew cleanup` (covers Go too)
- `zinit self-update && zinit update --all` (if zinit loaded)
- **Rust**: `rustup update` + `cargo install-update -a` (if cargo-update installed)
- **mise**: `mise upgrade` for managed runtimes (node, go, …) + global npm packages
- **Claude**: checks npm registry for updates (if claude present)

All jobs run simultaneously with live spinner feedback. Failed job logs appear
after all jobs complete, followed by version summary.

**Example:**
```
$ upgrade
  ✓ [brew    ] done      12s
  ✓ [zinit   ] done       0s
  ✓ [rust    ] done       2s
  ✓ [node    ] done       2s
  ✓ [claude  ] done       1s

Finished in 12s

  OS:          macOS 26.1 (arm64)
  Kernel:      25.1.0
  Go:          go1.26.3
  Rust:        rustc 1.95.0
  Cargo:       1.95.0
  Node:        v24.15.0
  npm:         11.14.1
  pnpm:        11.1.2
  Claude:      2.1.143
  Docker:      29.5.0
  Git:         2.43.0

✓ All done!
```

**Resilience:**
- Network failures on any tool don't block others (e.g., curl timeout on go.dev doesn't fail job)
- Graceful fallback to skip upgrade if check unavailable
- `--dry-run` lets you preview without risk

---

## zsh-health

System diagnostic. Scans for installed tools, verifies PATH configuration,
and checks shell setup status.

Use this after a fresh install or when tools stop working.

```
$ zsh-health

=== ZSH Configuration Health ===

Platform:
  ✓ macOS 26.1 (arm64)

Core Tools:
  ✓ git      git version 2.43.0
  ✓ zsh      zsh 5.9 (arm64-apple-darwin25.0)
  ✓ fzf      0.68.0 (b908f7a0)
  ✓ eza      eza - A modern, maintained replacement for ls
  ✓ bat      bat 0.24.0
  ✓ fd       fd 9.0.0

Language Tools:
  ✓ Go         go version go1.26.3 darwin/arm64
  ✓ Rust       rustc 1.95.0 (59807616e 2026-04-14)
  ✓ Node       v24.15.0
  ✓ Python     Python 3.12.3

PATH Configuration:
  • 18 directories in PATH
  ✓ /Users/user/.local/bin (Local tools)
  ✓ /opt/homebrew/bin (Homebrew)
  ✓ /Users/user/.cargo/bin (Rust/Cargo)
  ✓ /Users/user/go/bin (Go tools)

ZSH Configuration:
  ✓ ZDOTDIR = /Users/user/.config/zsh
  ✓ Zinit plugins loaded
  ✓ Zoxide (smart cd) available

✓ All critical tools present
```

**Checks performed:**
- Platform: macOS version + Homebrew location on Apple Silicon
- Core tools: git, zsh, fzf, eza, bat, fd
- Languages: Go, Rust, Node, Python
- PATH: key directories present (.local, Homebrew, .cargo, go)
- Shell: ZDOTDIR set, Zinit loaded, Zoxide available

Exit code 0 if all critical checks pass, 1 if issues detected.

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

Show all TCP sockets currently in LISTEN state (via `lsof`).

```
$ ports
COMMAND   PID  USER  FD  TYPE  DEVICE  SIZE/OFF  NODE  NAME
postgres  312  user  7u  IPv4  0x...   0t0       TCP   *:5432 (LISTEN)
node      845  user 23u  IPv4  0x...   0t0       TCP   *:3000 (LISTEN)
redis-se  990  user  6u  IPv4  0x...   0t0       TCP   127.0.0.1:6379 (LISTEN)
```

---

## show_path

Display PATH entries one per line, numbered. Useful for debugging PATH
ordering after adding new entries.

```
$ show_path
     1	/Users/user/.local/bin
     2	/Users/user/.cargo/bin
     3	/Users/user/go/bin
     4	/Users/user/.config/zsh/bin
     5	/opt/homebrew/bin
     6	/opt/homebrew/sbin
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
mise, direnv, fzf). Forces them to regenerate on the next shell start.

Useful when auto-invalidation via `mtime` doesn't trigger — for example after
a manual config edit that doesn't touch the binary.

```
$ zsh-cache-clear
Removed: /home/user/.cache/zsh/starship.zsh
Removed: /home/user/.cache/zsh/zoxide.zsh
Removed: /home/user/.cache/zsh/mise.zsh
Removed: /home/user/.cache/zsh/direnv.zsh
Cleared 4 cache file(s). Restart shell to regenerate.

# if caches were already absent:
Cleared 0 cache file(s). Restart shell to regenerate.
```

---

## toggle_interactive

Switch between full interactive mode (Starship + Zinit plugins) and a bare
fast shell for headless/automation use. State persists across shells.

```
$ toggle_interactive off    # fast shell (~50ms), no prompt theme, no plugins
$ toggle_interactive on     # full features
$ toggle_interactive        # show current state
```

---

## freespace

Smart disk cleanup with confirmation prompts. Targets `node_modules` and
`vendor` directories under `$CODE_DIR` (default `~/Development/Code`); with `--aggressive` also cleans system
caches (npm, pip, go, cargo, brew).

```
$ freespace --dry-run              # preview, no changes
$ freespace                        # clean project dirs (asks first)
$ freespace --aggressive           # also clean system caches
```
