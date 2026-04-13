# Zsh Features

Options and built-in zsh capabilities active in this config (`modules/options.zsh`).

---

## History

| Option | Effect |
|--------|--------|
| `HIST_IGNORE_DUPS` | Consecutive duplicate commands are not recorded |
| `HIST_IGNORE_SPACE` | Commands prefixed with a space are not recorded |
| `HIST_REDUCE_BLANKS` | Leading/trailing whitespace stripped from entries |
| `HIST_EXPIRE_DUPS_FIRST` | Duplicates are evicted first when history is full |
| `HIST_VERIFY` | History expansions (`!cmd`) are shown before executing |
| `HIST_FIND_NO_DUPS` | Duplicate entries skipped when searching with Up |
| `EXTENDED_HISTORY` | Each entry stored as `:start:elapsed;command` |
| `SHARE_HISTORY` | New entries immediately visible in all open sessions |

```
# HIST_IGNORE_SPACE — run a command without recording it:
$  secret-token generate    (leading space)
# not saved to ~/.local/share/zsh/history

# HIST_VERIFY — safe history expansion:
$ git checkout main
$ git checkout feat/new
$ !git          (expands to last git command)
$ git checkout feat/new    (shown for review — press Enter to confirm)

# EXTENDED_HISTORY — what entries look like in the file:
: 1710000000:3;go test ./...
#  ^timestamp  ^elapsed seconds
```

History file: `$XDG_DATA_HOME/zsh/history` (default: `~/.local/share/zsh/history`)
Size: 50 000 entries in memory, 50 000 saved to disk.

---

## Directory Navigation

| Option | Effect |
|--------|--------|
| `AUTO_CD` | Type a directory name to cd into it — no `cd` needed |
| `AUTO_PUSHD` | Every `cd` pushes the previous directory onto a stack |
| `PUSHD_IGNORE_DUPS` | Duplicates are not pushed onto the dir stack |
| `CDABLE_VARS` | Shell variables that hold paths can be used with `cd` |

```
# AUTO_CD
$ /tmp
/tmp   (no "cd" required)

$ ..
..     (same as cd ..)

# AUTO_PUSHD — navigate back through history with cd -N
$ cd ~/code/git_hub/nandordudas
$ cd my-project
$ cd src
$ cd -1         # back to my-project
$ cd -2         # back to ~/code/git_hub/nandordudas
$ dirs -v       # show the full directory stack
0  ~/code/git_hub/nandordudas/my-project/src
1  ~/code/git_hub/nandordudas/my-project
2  ~/code/git_hub/nandordudas

# CDABLE_VARS
$ export MYPROJECT=~/code/git_hub/nandordudas/my-project
$ cd MYPROJECT   (no $ needed)
~/code/git_hub/nandordudas/my-project
```

---

## Globbing

| Option | Effect |
|--------|--------|
| `EXTENDED_GLOB` | Enables `^`, `~`, `#`, `(#i)` and other glob qualifiers |
| `NO_NOMATCH` | Unmatched globs are passed to the command as-is |
| `GLOB_DOTS` | Globs like `*` match dotfiles without an explicit `.` |

```
# EXTENDED_GLOB

# Match everything except .git
$ ls ^.git

# Case-insensitive glob
$ ls (#i)readme*
README.md

# Match files modified in the last 24h (glob qualifier)
$ ls *(m-1)
recently-edited.go

# Recursive glob (built-in, no find needed)
$ echo **/*.go
cmd/main.go internal/parser/parser.go internal/parser/parser_test.go

# NO_NOMATCH — pass *.xyz to a command that handles missing matches itself
$ rg 'pattern' *.xyz
# without NO_NOMATCH this would error with "no matches found: *.xyz"

# GLOB_DOTS — include hidden files
$ ls *
.gitignore  .zshrc  README.md  src/
# without GLOB_DOTS, .gitignore and .zshrc would be excluded
```

---

## Job Control

| Option | Effect |
|--------|--------|
| `NO_BEEP` | Terminal bell is silenced |
| `NOTIFY` | Job status changes are reported immediately, not at next prompt |
| `BG_NICE` | Background jobs run at lower CPU priority (nice +5) |

```
# NOTIFY — see job completion as soon as it happens
$ sleep 5 &
[1] 12345
$ ...typing other things...
[1]  + done       sleep 5   (appears immediately when job finishes)

# BG_NICE — background jobs don't compete with foreground work
$ cargo build &   (runs at nice 14 instead of nice 9)
```

---

## Miscellaneous

| Option | Effect |
|--------|--------|
| `INTERACTIVE_COMMENTS` | `#` starts a comment in interactive mode |
| `RC_QUOTES` | `''` inside single-quoted strings embeds a literal `'` |
| `COMBINING_CHARS` | Unicode combining characters displayed correctly (needed for WSL) |

```
# INTERACTIVE_COMMENTS — annotate commands without executing the comment
$ echo "hello"  # prints hello
hello

# RC_QUOTES — embed a single quote inside a single-quoted string
$ echo 'it''s fine'
it's fine
# without RC_QUOTES you'd need: echo 'it'"'"'s fine'

# COMBINING_CHARS — affects display of accented characters, emoji with
# skin-tone modifiers, etc. in the prompt and command output
```

---

## Completion System

Configured in `modules/completions.zsh`. Key behaviours:

| Feature | Setting |
|---------|---------|
| Case-insensitive matching | `m:{a-zA-Z}={A-Za-z}` |
| Cache location | `$XDG_CACHE_HOME/zsh/compcache` |
| Menu display | grouped by type, coloured via `LS_COLORS` |
| `special-dirs` | `.` and `..` hidden from menus |
| `git checkout` sort | alphabetical (not by recency) |

```
# Case-insensitive
$ git checkout MAIN<Tab>
→ main    (matches despite case mismatch)

# Grouped menu (fzf-tab renders this as an fzf popup)
$ kill <Tab>
  [process ID]
  12345  node
  67890  cargo

# cd preview via fzf-tab
$ cd src/<Tab>
# right panel: eza -1 listing of src/
```

---

## Eval Caching

Configured in `modules/tools.zsh`. External tool initialisation scripts
(`starship`, `zoxide`, `fnm`, `direnv`, `fzf`) are cached to
`$XDG_CACHE_HOME/zsh/` on first run and sourced directly on subsequent starts.

| Without cache | With cache |
|---------------|------------|
| ~65–85 ms of subprocess forks per tool | ~1–2 ms of file sourcing |

Cache files are regenerated automatically whenever the tool binary is newer
than the cached file (checked via `-nt`). Force a manual refresh with
`zsh-cache-clear`.

```
$ time zsh -i -c exit
# with caches warm:
zsh -i -c exit  0.06s user 0.02s system 98% cpu 0.081s total

$ zsh-cache-clear && time zsh -i -c exit
# after clearing (caches regenerated this run):
zsh -i -c exit  0.31s user 0.04s system 96% cpu 0.363s total
```
