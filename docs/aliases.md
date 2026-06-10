# Aliases

All aliases defined in `modules/aliases.zsh`, with example calls and output.

---

## Navigation

| Alias | Expands to |
|-------|-----------|
| `gg` | `cd $CODE_DIR/github/$GITHUB_USER` (requires `GITHUB_USER` in `modules/local.zsh`) |
| `gb` | `cd $CODE_DIR/bitbucket/$BITBUCKET_USER` (requires `BITBUCKET_USER` in `modules/local.zsh`) |
| `cr` | `code --reuse-window .` |

```
$ gg
~/Development/code/github/nandordudas

$ gb
~/Development/code/bitbucket/nandordudas

$ cr
# opens current directory in the existing VS Code window
```

---

## File Listing (eza)

| Alias | Expands to |
|-------|-----------|
| `ls` | `eza -F --icons --git` |
| `l`  | `eza -F --icons` |
| `la` | `eza -laF --icons --git` |
| `ll` | `eza -laF --icons --git --group-directories-first` |
| `lt` | `eza -T --icons --git-ignore` |

```
$ ls
 src/   tests/   Cargo.toml   README.md

$ la
drwxr-xr-x  - user  3 Mar 10:00  src/
drwxr-xr-x  - user  3 Mar 09:55  tests/
.rw-r--r-- 1.2k user  3 Mar 10:00  Cargo.toml
.rw-r--r--  842 user  2 Mar 14:30  README.md

$ ll
# same as la but directories always appear at the top

$ lt
.
├──  src
│   ├──  main.rs
│   └──  lib.rs
├──  tests
│   └──  integration.rs
└──  Cargo.toml
```

---

## File Operations

| Alias | Expands to | Behaviour change |
|-------|-----------|-----------------|
| `mkdir` | `mkdir -p` | creates intermediate directories automatically |
| `rm` | `rm -i` | prompts before every deletion |
| `cp` | `cp -i` | prompts before overwriting |
| `mv` | `mv -i` | prompts before overwriting |

```
$ mkdir a/b/c/d
# creates all four levels at once, no "cannot create directory" error

$ rm important.txt
remove important.txt? y

$ cp config.toml config.toml.bak
# no prompt — destination does not exist yet

$ cp config.toml config.toml.bak
overwrite config.toml.bak? n
```

---

## Directory Shortcuts

| Alias | Expands to |
|-------|-----------|
| `..` | `cd ..` |
| `~` | `cd ~` |
| `cdd` | `cd -` |

```
$ pwd
/Users/user/Development/code/github/nandordudas/my-project/src

$ ..
/Users/user/Development/code/github/nandordudas/my-project

$ ~
~

$ cdd
/Users/user/Development/code/github/nandordudas/my-project   # jumps back to previous dir
```

---

## Docker Compose

Most `docker compose` aliases come from the `OMZP::docker-compose` plugin (enabled in Zinit):
`dco`, `dcdn`, `dce`, `dclf`, etc.

Custom aliases:

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `dc-up` | `UID=$(id -u) GID=$(id -g) docker compose up` | Start services with host UID/GID for proper file permissions |

```
$ dc-up
# starts all services with current user's UID/GID so file permissions
# inside containers match the host (avoids root-owned output files)

$ dco ps   # via plugin — docker compose ps
NAME       IMAGE     COMMAND   SERVICE   CREATED   STATUS    PORTS
api        node:20   ...       api       2m ago    Up 2m     3000/tcp
db         postgres  ...       db        2m ago    Up 2m     5432/tcp

$ dce api sh   # via plugin — docker compose exec
# opens a shell inside the running api container

$ dclf   # via plugin — docker compose logs -f
api  | Listening on port 3000
db   | database system is ready to accept connections
```

---

## Docker CLI

Most aliases come from the `OMZP::docker` plugin (enabled in Zinit):
`dps`, `dpsa`, `dils`, `dpo`, `dxc`, etc.

Custom aliases for special operations:

| Alias | Expands to | Purpose |
|-------|-----------|---------|
| `drm` | `docker rm $(docker ps -aq)` | Remove **all** stopped containers |
| `drmi` | `docker rmi $(docker images -qf dangling=true)` | Remove **dangling** images only |

```
$ dps
CONTAINER ID   IMAGE     STATUS    PORTS      NAMES
a3f1b2c4d5e6   node:20   Up 5m     3000/tcp   api

$ dpsa
# same but includes exited/stopped containers

$ dimg
REPOSITORY   TAG       IMAGE ID       SIZE
node         20        abc123def456   180MB
postgres     16        def456abc123   380MB

$ drm
# removes all stopped containers

$ drmi
# removes untagged (dangling) images — frees disk space after builds
```

---

## Git

| Alias | Expands to |
|-------|-----------|
| `gs` | `git status` |
| `gp` | `git pull` |
| `gd` | `git diff` |
| `gco` | `git checkout` |
| `gcm` | `git commit -m` |
| `gaa` | `git add -A` |
| `gl` | `git log --oneline --graph --decorate --all` |
| `gst` | `git stash` |
| `gstp` | `git stash pop` |
| `gstl` | `git stash list` |
| `gwip` | `git add -A && git commit -m "wip: HH:MM"` |
| `gunwip` | undo last commit if its message starts with `wip` |

```
$ gs
On branch main
Changes not staged for commit:
  modified:   src/main.rs

$ gd
diff --git a/src/main.rs b/src/main.rs
- fn old() {}
+ fn new() {}

$ gco feat/my-feature
Switched to branch 'feat/my-feature'

$ gaa && gcm "fix: correct off-by-one in parser"
[main a1b2c3d] fix: correct off-by-one in parser
 1 file changed, 1 insertion(+), 1 deletion(-)

$ gl
* a1b2c3d (HEAD -> main) fix: correct off-by-one in parser
* f4e5d6c feat: add parser module
* 1a2b3c4 (origin/main) init

$ gst
Saved working directory and index state WIP on main: a1b2c3d fix: ...

$ gstl
stash@{0}: WIP on main: a1b2c3d fix: ...

$ gstp
On branch main
Changes not staged for commit:
  modified:   src/main.rs

$ gwip
[main 9z8y7x6] wip: 14:32
 2 files changed, 47 insertions(+)

$ gunwip
# undoes the wip commit, restoring changes to the working tree
```

---

## Tools & Utilities

Aliases for optional tools only activate when the tool is installed, so a
missing tool never shadows the real command.

| Alias | Expands to |
|-------|-----------|
| `df` | `duf` (if installed) |
| `du` | `dust` (if installed) |
| `pss` | `procs` (if installed) |
| `ik` | `interactive_kill` |
| `qfind` | `find . -name` |
| `rand` | `openssl rand -base64 32` |
| `json` | `jq .` (falls back to `python3 -m json.tool` if jq missing) |
| `zshconfig` | open the config dir in `$EDITOR` (waits), then reload the shell |
| `reload` | `exec zsh` |

The bat theme is set via `BAT_THEME` (default `TwoDark`) — override it in
`modules/local.zsh`.

```
$ df
# duf: colourised disk usage with mount points in a table

$ du src/
# dust: tree-style directory size breakdown

$ pss
# procs: colourised, searchable process list

$ qfind "*.toml"
./Cargo.toml
./config/app.toml

$ rand
dK4mN8pQrT2vXyZ1aB5cE7fH0jL3nO6s

$ echo '{"name":"alice","age":30}' | json
{
    "name": "alice",
    "age": 30
}

$ zshconfig
# opens the ~/.config/zsh directory in $EDITOR (VS Code, waiting)
# closing the editor triggers exec zsh to reload the shell

$ reload
# replaces the current shell process with a fresh zsh
```

---

## System

`open`, `pbcopy`, and `pbpaste` are native on macOS — no aliases needed.

| Alias | Expands to |
|-------|-----------|
| `psa` | `ps aux` |
| `uuid` | `uuidgen` (lowercased) copied to clipboard |

```
$ psa | head -3
USER   PID  %CPU %MEM  COMMAND
user  1234   0.1  0.5  zsh
user  5678   2.3  1.2  node

$ uuid
# generates a lowercase UUID and copies it to the clipboard
# nothing is printed — the value is ready to Cmd+V anywhere
```

---

## Development Tools

Node, Go, and other runtimes are managed by [mise](https://mise.jdx.dev/) —
use `mise use node@22`, `mise ls`, `mise upgrade` directly (no aliases needed).

### Cargo (Rust)

| Alias | Expands to |
|-------|-----------|
| `cb` | `cargo build` |
| `ct` | `cargo test` |
| `crun` | `cargo run` |
| `cch` | `cargo check` (not `cc` — that would shadow the system C compiler) |
| `cf` | `cargo fmt` |
| `clippy` | `cargo clippy -- -D warnings` |

```
$ cch
    Checking my-crate v0.1.0
    Finished `dev` profile in 0.38s

$ cb
   Compiling my-crate v0.1.0
    Finished `dev` profile in 1.24s

$ ct
running 4 tests
test parser::test_empty ... ok
test parser::test_basic ... ok
test parser::test_nested ... ok
test parser::test_error ... ok
test result: ok. 4 passed; 0 failed

$ cf
# formats all .rs files in place, no output if already formatted

$ clippy
    Checking my-crate v0.1.0
warning: unused variable `x`
error: treating warnings as errors
```

### Go

| Alias | Expands to |
|-------|-----------|
| `got` | `go test ./...` |
| `gomod` | `go mod tidy` |
| `gocover` | run tests with coverage, open HTML report |

```
$ got
ok      github.com/user/myapp/internal/parser   0.012s
ok      github.com/user/myapp/cmd               0.003s

$ gomod
# removes unused dependencies, adds missing ones, updates go.sum

$ gocover
# runs go test -coverprofile=/tmp/cover.out ./...
# then opens the HTML coverage report in your default browser
```

### Node / pnpm

| Alias | Expands to |
|-------|-----------|
| `taze` | `taze -r` |

```
$ taze
my-app › package.json
  vue                 ^3.3.0  →  ^3.4.0
  vite                ^4.5.0  →  ^5.1.0

packages/ui › package.json
  @headlessui/vue     ^1.7.0  →  ^1.7.16
# -r checks all workspaces in the monorepo
```
