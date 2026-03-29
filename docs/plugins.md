# Plugins

All plugins loaded via Zinit in `modules/zinit.zsh`. Every plugin uses turbo
mode (`wait lucid`) so the prompt appears before any plugin code runs.

---

## zsh-users/zsh-completions

Adds ~700 extra completion definitions for tools not covered by zsh's built-in
completions (Docker, kubectl, cargo, npm, and many more).

Loaded first with `blockf` so Zinit manages fpath instead of the old
`compinit` approach. Triggers `zicompinit; zicdreplay` once on load — the
only place compinit runs.

```
$ cargo <Tab>
  build    check    clean    clippy    doc    fmt    new    run    test    ...

$ docker <Tab>
  attach   build   commit   cp   create   diff   events   exec   ...
```

---

## zsh-users/zsh-autosuggestions

Shows a greyed-out suggestion as you type, based on history and completion.
Press `→` or `End` to accept the full suggestion; `Ctrl+Right` to accept one
word at a time.

```
$ got                       (you type "got")
$ got ./...                 (suggestion shown in grey, from history)
  →  accepts the full suggestion
  Ctrl+Right  accepts up to the next word boundary
```

Config:
- `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=242'` — subtle grey
- `ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20` — no suggestions for very long commands
- `ZSH_AUTOSUGGEST_STRATEGY=(history completion)` — tries history first, then completion

---

## zsh-users/zsh-history-substring-search

Makes `Up`/`Down` search history by the text already on the line, not just
cycle through the last command.

```
$ go        (type "go" then press Up)
Up →  go test ./...
Up →  go mod tidy
Up →  go build ./...
# only commands that start with "go" are cycled
```

Also bound to `Ctrl+P` / `Ctrl+N` for Emacs-style navigation.

---

## zdharma-continuum/fast-syntax-highlighting

Real-time syntax highlighting as you type. Highlights commands, flags,
strings, paths, and errors in different colours.

```
$ git checkout main          # valid command — highlighted normally
$ gti checkout main          # unknown command — shown in red
$ echo "hello $USER"         # variable highlighted inside string
$ cat /etc/nonexistent       # path that does not exist — highlighted differently
```

Faster than the original `zsh-syntax-highlighting` due to a different
internal engine.

---

## MichaelAquilina/zsh-you-should-use

Reminds you to use an alias when you type the full command it expands from.
Appears after the command output (`YSU_MESSAGE_POSITION="after"`).

```
$ git status
On branch main
nothing to commit, working tree clean
You should use alias 'gs' for 'git status'

$ git stash
Saved working directory and index state WIP on main
You should use alias 'gst' for 'git stash'
```

`YSU_HARDCORE=0` — reminder mode only, does not block the command.

---

## Aloxaf/fzf-tab

Replaces the default zsh completion menu with an fzf fuzzy-search popup.
Supports live previews configured in `modules/completions.zsh`.

```
# cd with directory preview
$ cd src/<Tab>
# fzf popup opens
# left: matching directories
# right: eza -1 listing of the highlighted directory

# kill with process preview
$ kill <Tab>
# fzf popup opens
# left: process list
# right: full command of the highlighted PID

# ls with file preview
$ ls <Tab>
# fzf popup: directories show eza listing, files show batcat preview

# switch between completion groups
< / >   move between groups (e.g. files vs directories)
```

---

## hlissner/zsh-autopair

Auto-inserts the closing character when you open a pair, and deletes both
when you backspace over an empty pair.

| Type | Result |
|------|--------|
| `"` | `"│"` |
| `'` | `'│'` |
| `` ` `` | `` `│` `` |
| `(` | `(│)` |
| `[` | `[│]` |
| `{` | `{│}` |

```
$ echo "hello |"       (cursor at |, type " to close)
$ echo "hello "        (pair closed automatically)

$ curl -H '|'          (type the value, closing ' inserted)
$ curl -H 'Authorization: Bearer token'

$ echo $(|)            (Backspace on empty pair removes both characters)
$ echo               (both ( and ) removed)
```

---

## wfxr/forgit

Interactive git workflows built on fzf. Loaded with a 1-second delay since
it's only needed when working with git.

| Command | Action |
|---------|--------|
| `glo` | interactive git log |
| `gd` | interactive diff viewer |
| `gadd` | interactive `git add` (stage individual hunks) |
| `grst` | interactive `git reset HEAD` |
| `gcf` | interactive `git checkout` file |
| `gss` | interactive `git stash show` |
| `gclean` | interactive `git clean` |

```
$ gadd
# opens fzf with all changed files
# Tab to stage/unstage individual files
# ? to toggle preview of the diff

$ glo
# full-screen fzf log browser
# Enter to copy commit hash
# Ctrl+Y to copy commit hash to clipboard
```

---

## OMZ Completions (golang / rust / docker-compose / npm)

Individual completion plugins from oh-my-zsh, loaded without the full OMZ
framework. Each adds `<Tab>` completions for its tool.

```
# golang
$ go test -<Tab>
  -bench       -benchmem    -count       -cover       -run    -v    ...

# rust
$ rustup <Tab>
  component    default    override    show    target    toolchain    update    ...

$ rustup target add <Tab>
  aarch64-unknown-linux-gnu    wasm32-unknown-unknown    x86_64-pc-windows-gnu    ...

# docker-compose
$ docker compose up --<Tab>
  --build    --detach    --force-recreate    --no-deps    --remove-orphans    ...

# npm
$ npm <Tab>
  ci    exec    init    install    ls    outdated    publish    run    test    ...

$ npm run <Tab>
  build    dev    lint    test    typecheck    ...  (reads scripts from package.json)
```
