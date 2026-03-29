# Keybindings

All bindings defined in `modules/keybindings.zsh`. Base mode: **Emacs** (`bindkey -e`).

---

## Line Navigation

| Key | Action |
|-----|--------|
| `Home` | Move to beginning of line |
| `End` | Move to end of line |
| `Ctrl+Right` | Move forward one word |
| `Ctrl+Left` | Move backward one word |

```
$ git commit -m "fix: correct parser|"   (cursor at end)
  Home →
$ |git commit -m "fix: correct parser"

$ git commit -m "fix: correct |parser"
  Ctrl+Right →
$ git commit -m "fix: correct parser|"

$ git commit -m "fix: correct |parser"
  Ctrl+Left →
$ git commit -m "fix: |correct parser"
```

---

## Deletion

| Key | Action |
|-----|--------|
| `Backspace` | Delete character to the left |
| `Delete` | Delete character to the right |
| `Ctrl+Backspace` | Delete word to the left |
| `Ctrl+W` | Delete word to the left (standard Unix) |
| `Alt+D` | Delete word to the right |

```
$ git checkout feat/my-feature|
  Ctrl+W →
$ git checkout |

$ git checkout |feat/my-feature
  Alt+D →
$ git checkout |/my-feature
```

> `Ctrl+Backspace` and `Ctrl+W` do the same thing. The VS Code integrated
> terminal sends `^H` for Ctrl+Backspace; both are bound for compatibility.

---

## History Search

| Key | Action |
|-----|--------|
| `Up` | Search history backward by current prefix |
| `Down` | Search history forward by current prefix |
| `Ctrl+P` | Same as Up |
| `Ctrl+N` | Same as Down |
| `Ctrl+R` | Incremental backward search (overridden by fzf) |

Powered by **zsh-history-substring-search** for Up/Down — prefix-aware, not
just last command.

```
$ got|           (type "got" then press Up)
  Up →
$ got ./...      (last time you ran got)
  Up →
$ got -run TestParser ./...   (the time before)
```

When fzf is loaded, `Ctrl+R` opens a full-screen fuzzy history search instead
of the built-in incremental search.

---

## Completion Navigation

| Key | Action |
|-----|--------|
| `Tab` | Open completion menu / select next item |
| `Shift+Tab` | Select previous item in completion menu |
| `Space` | Expand history expression inline (`magic-space`) |

```
$ git check|
  Tab →
# fzf-tab opens a fuzzy completion menu:
#   checkout
#   check-ignore
#   check-mailmap

$ echo !$|
  Space →
$ echo previous-argument   (history expansion happens inline)
```

---

## Editing Conveniences

| Key | Action |
|-----|--------|
| `Ctrl+X Ctrl+E` | Open current command in `$EDITOR` (VS Code) |
| `Alt+M` | Copy the previous word onto the cursor |
| `PageUp` | Navigate history up |
| `PageDown` | Navigate history down |

```
# Ctrl+X Ctrl+E
$ docker run --rm -it -v $(pwd):/work -w /work -e FOO=bar ubuntu:24.04|
  Ctrl+X Ctrl+E →
# opens the full command in VS Code for editing
# saving and closing VS Code executes the edited command

# Alt+M — "copy previous shell word"
$ mv config.toml |
  Alt+M →
$ mv config.toml config.toml|
# now append: $ mv config.toml config.toml.bak
```

---

## Key Reference Card

```
Movement
  Home / End         beginning / end of line
  Ctrl+Right/Left    forward / backward word

Deletion
  Backspace          delete char left
  Delete             delete char right
  Ctrl+W             delete word left
  Ctrl+Backspace     delete word left (VS Code)
  Alt+D              delete word right

History
  Up / Ctrl+P        search backward by prefix
  Down / Ctrl+N      search forward by prefix
  Ctrl+R             fzf history search

Completion
  Tab                open menu / next item
  Shift+Tab          previous item
  Space              expand history inline

Editing
  Ctrl+X Ctrl+E      open in $EDITOR
  Alt+M              copy previous word
  PageUp / PageDown  scroll history
```
