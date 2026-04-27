# Aliases

All aliases defined in `modules/aliases.zsh`, with example calls and output.

---

## Navigation

| Alias | Expands to |
|-------|-----------|
| `gg` | `cd ~/code/github/$GITHUB_USER` (requires `GITHUB_USER` in `modules/local.zsh`) |
| `gb` | `cd ~/code/bitbucket/$BITBUCKET_USER` (requires `BITBUCKET_USER` in `modules/local.zsh`) |
| `cr` | `code --reuse-window .` |

```
$ gg
~/code/github/nandordudas

$ gb
~/code/bitbucket/nandordudas

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
/home/user/code/git_hub/nandordudas/my-project/src

$ ..
/home/user/code/git_hub/nandordudas/my-project

$ ~
~

$ cdd
/home/user/code/git_hub/nandordudas/my-project   # jumps back to previous dir
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

| Alias | Expands to |
|-------|-----------|
| `bat` | `batcat --theme TwoDark ...` |
| `fd` | `fdfind` |
| `df` | `duf` |
| `du` | `dust` |
| `pss` | `procs` |
| `g` | `~/.cargo/bin/g` (Go version manager) |
| `ik` | `interactive_kill` |
| `qfind` | `find . -name` |
| `rand` | `openssl rand -base64 32` |
| `json` | `python3 -m json.tool` |
| `zshconfig` | open `.zshrc` in VS Code, reload on close |
| `reload` | `exec zsh` |

```
$ bat src/main.rs
# syntax-highlighted file, theme follows OS light/dark mode

$ fd '\.go$'
./cmd/main.go
./internal/parser/parser.go

$ df
# duf: colourised disk usage with mount points in a table

$ du src/
# dust: tree-style directory size breakdown

$ pss
# procs: colourised, searchable process list

$ g list
  1.21.0
  1.22.0
* 1.23.0   (installed, active)

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
# opens ~/.config/zsh/.zshrc in VS Code
# saving and closing VS Code triggers exec zsh to reload the shell

$ reload
# replaces the current shell process with a fresh zsh
```

---

## System

| Alias | Expands to |
|-------|-----------|
| `psa` | `ps aux` |
| `free` | `free -h` |

```
$ psa | head -3
USER   PID  %CPU %MEM  COMMAND
user  1234   0.1  0.5  zsh
user  5678   2.3  1.2  node

$ free
               total   used   free   shared  buff/cache  available
Mem:            15Gi   4.2Gi  8.1Gi    512Mi        2.8Gi      10Gi
Swap:          4.0Gi     0B   4.0Gi
```

---

## WSL-Specific

Available only when `IS_WSL=1`.

| Alias | Expands to |
|-------|-----------|
| `open` | `explorer.exe` |
| `pbcopy` | `clip.exe` |
| `pbpaste` | `powershell.exe Get-Clipboard \| tr -d "\r"` |
| `uuid` | generate UUID and copy to Windows clipboard |

```
$ open .
# opens the current directory in Windows Explorer

$ echo "hello" | pbcopy
# copies "hello" to the Windows clipboard

$ pbpaste
hello
# raw text output, safe to pipe to other commands

$ pbpaste | wc -c
6

$ uuid
# generates a UUID, strips the newline, sends to clipboard
# nothing is printed — the value is ready to Ctrl+V in any Windows app
```

---

## Development Tools

### General

| Alias | Expands to |
|-------|-----------|
| `nvm` | `fnm` |

```
$ nvm use 20
# delegates to fnm — fnm is a faster drop-in for nvm
```

### Cargo (Rust)

| Alias | Expands to |
|-------|-----------|
| `cb` | `cargo build` |
| `ct` | `cargo test` |
| `crun` | `cargo run` |
| `cc` | `cargo check` |
| `cf` | `cargo fmt` |
| `clippy` | `cargo clippy -- -D warnings` |

```
$ cc
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
