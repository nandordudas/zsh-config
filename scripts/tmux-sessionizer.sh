#!/usr/bin/env bash
set -euo pipefail

TMUX_BIN="$(command -v tmux)" || { echo 'tmux not found' >&2; exit 1; }
FZF_BIN="$(command -v fzf)"   || { echo 'fzf not found — brew install fzf' >&2; exit 1; }

if [ -z "${TMUX-}" ]; then
    echo "Not inside tmux — run this via prefix+g (display-popup)." >&2
    exit 1
fi

NEW_LABEL="Create new session…"

# Exclude any real session named identically to the label so it cannot hijack the create branch.
sessions="$("$TMUX_BIN" list-sessions -F '#{session_name}' 2>/dev/null | grep -vxF "$NEW_LABEL" || true)"

if [ -n "$sessions" ]; then
    menu="$NEW_LABEL
$sessions"
else
    menu="$NEW_LABEL"
fi

choice="$(printf '%s\n' "$menu" | "$FZF_BIN" \
    --prompt='Sessions> ' \
    --reverse \
    --no-multi || true)"

[ -n "$choice" ] || exit 0

if [ "$choice" = "$NEW_LABEL" ]; then
    # Capture exit code separately so Escape (130) is distinguishable from
    # "typed a name and pressed Enter" (1 = no item selected from empty list).
    _fzf_out="$(mktemp -t tmux-sessionizer.XXXXXX)"
    "$FZF_BIN" --print-query --prompt='New session name: ' < /dev/null > "$_fzf_out" 2>/dev/null \
        || _fzf_rc=$?
    _fzf_rc="${_fzf_rc:-0}"
    new_name="$(head -n1 "$_fzf_out")"
    rm -f "$_fzf_out"
    [ "$_fzf_rc" -eq 130 ] && exit 0   # Escape / Ctrl-C — user cancelled
    [ -n "$new_name" ] || exit 0
    # new-session -ds is idempotent under races; || true lets switch-client handle it.
    "$TMUX_BIN" new-session -ds "$new_name" 2>/dev/null || true
    exec "$TMUX_BIN" switch-client -t "$new_name"
else
    exec "$TMUX_BIN" switch-client -t "$choice"
fi
