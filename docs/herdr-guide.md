# herdr Everyday Guide

[herdr](https://herdr.dev) replaces tmux in this config: same prefix-driven
multiplexer model, plus native agent-state awareness for Claude Code and
friends. Config lives at [`herdr/config.toml`](../herdr/config.toml),
symlinked to `~/.config/herdr/config.toml` by `install.sh`.

Prefix = `Ctrl+a` (`C-a`), same key as the old tmux setup. Almost every
binding below is herdr's **default** — the config file only overrides the
prefix and adds two commands herdr has no native equivalent for (scratch
terminal, btop popup). Press `prefix+?` any time for the live keymap.

---

## Workspaces — the top level (was: tmux sessions)

| Action | Key |
|---|---|
| Start herdr | `herdr` in terminal (attaches to the default session, or creates one) |
| Attach to a named session | `herdr --session work` |
| List sessions | `herdr session list` |
| **Fuzzy workspace picker** | `C-a w` |
| **Goto picker** (jump to any workspace/tab/pane) | `C-a g` |
| New workspace | `C-a Shift+n` |
| Rename current workspace | `C-a Shift+w` (prompts inline) |
| Close current workspace | `C-a Shift+d` (prompts) |
| Detach (leave agents running) | `C-a q` |

> herdr's `goto`/`workspace_picker` pickers are mouse-native and fuzzy by
> default — there's no `tmux-sessionizer.sh`-style custom script anymore.
> That script is retired; these two bindings cover the same job natively.

---

## Tabs — like browser tabs (was: tmux windows)

| Action | Key |
|---|---|
| New tab | `C-a c` |
| Next tab | `C-a n` |
| Previous tab | `C-a p` |
| Jump to tab 1–9 | `C-a 1`…`C-a 9` |
| Rename tab | `C-a Shift+t` |
| Close tab | `C-a Shift+x` |

---

## Panes — splits inside a tab

| Action | Key |
|---|---|
| Split right (side by side) | `C-a v` |
| Split down (top/bottom) | `C-a -` |
| Navigate panes | `C-a h/j/k/l` (vim-style) |
| Swap panes | `C-a Shift+h/j/k/l` |
| Zoom/unzoom pane | `C-a z` |
| Resize mode (then h/j/k/l) | `C-a r` |
| Close pane | `C-a x` |
| Cycle panes | `C-a Tab` / `C-a Shift+Tab` |

---

## Copy mode — scrollback & search

herdr's copy mode is vi-style out of the box — no custom bindings needed
(the old tmux config hand-wired `v`/`C-v`/`y`/`Enter`/`Escape`; herdr already
behaves the same way natively).

| Action | Key |
|---|---|
| Enter copy mode | `C-a [` |
| Move | `h/j/k/l`, `w/b/e`, `{`/`}` |
| Start selection | `v` or `Space` |
| Rectangle select | `C-v` |
| Copy & exit | `y` or `Enter` |
| Cancel | `q` or `Escape` |

Mouse drag-select copies without entering copy mode at all.

---

## Reload config

```
C-a Shift+r
```

Or from the shell: `herdr server reload-config`.

---

## Custom commands

Two bindings herdr has no built-in action for:

| Action | Key |
|---|---|
| Scratch terminal (temp pane, closes on exit) | `C-a t` |
| System monitor (btop, temp pane) | `C-a Shift+b` |

---

## Theme — auto light/dark switching

```toml
[theme]
name        = "gruvbox"
auto_switch = true
light_name  = "gruvbox-light"
dark_name   = "gruvbox"
```

herdr switches its own UI theme automatically when the host terminal reports
a light/dark appearance change — no manual toggle needed. Pick from any of
herdr's built-in themes (`catppuccin`, `tokyo-night`, `dracula`, `nord`,
`kanagawa`, `rose-pine`, …) by editing `name`/`light_name`/`dark_name` in
`herdr/config.toml`.

---

## Claude Code integration

`install.sh` runs `herdr integration install claude` automatically when both
`herdr` and `claude` are on `PATH`. This writes a hook to
`~/.claude/hooks/herdr-agent-state.sh` and registers it in Claude Code's
`settings.json`, so herdr can report native session identity and (with
Claude Code 6+) resume the same conversation after a full `herdr` restart —
see `[session] resume_agents_on_restore` in `herdr/config.toml`.

Combined with `show_agent_labels_on_pane_borders = true` and
`agent_panel_sort = "priority"`, every pane running Claude Code is labeled on
its border and surfaces first in the agent panel whenever it's blocked or
done — no more guessing which pane needs you.

To manage the integration by hand:

```sh
herdr integration install claude      # (re)install the hook
herdr integration uninstall claude    # remove it
herdr integration status              # check what's installed
```

---

## Notifications

```toml
[ui.toast]
delivery = "herdr"
```

Replaces tmux's `monitor-activity` (which only recolored the tab list).
herdr's toasts name the agent and the workspace/tab/pane it's in — click one,
or press `C-a o`, to jump straight there.

---

## Machine-local overrides

herdr's `config.toml` has no tmux-style `source-file`/include directive, so
there's no `local.conf` layered on top the way `tmux/local.conf` used to
work. This file holds no secrets (just UI/keybindings), so machine-specific
tweaks go directly into `herdr/config.toml`. For a genuinely different
per-machine profile, point `HERDR_CONFIG_PATH` at a separate file instead —
see `modules/local.zsh`.

---

## Daily workflow pattern

```sh
herdr --session dev      # morning: one named session
C-a c                    # tab 1: editor
C-a c                    # tab 2: git/shell
C-a c                    # tab 3: Claude Code
C-a v                    # split for a quick side pane
C-a z                    # zoom in to focus
C-a q                    # detach at end of day — agents keep running
herdr --session dev      # next morning: pick up exactly where you left,
                         # Claude Code panes resume their conversation
```
