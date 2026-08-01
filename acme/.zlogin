# acme/.zlogin
#
# The `update()` function that used to live here has been removed. It ran a
# bare `set -e` inside a shell function, and zsh has no function-scoped `set`,
# so errexit stayed on in the calling shell after the function returned — the
# next command with a non-zero status (a grep with no match, a false [[ ]] test,
# a Ctrl-C) then killed the terminal.
#
# That same `set -e` also meant a single brew hiccup aborted the function
# before the zinit steps ever ran.
#
# `upgrade` in modules/functions.zsh does the same work with per-tool failure
# isolation, --dry-run/--only, and errexit confined to a subshell. The two
# things this function did better — `--greedy` casks and `softwareupdate -l` —
# have been folded into it.
