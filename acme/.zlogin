echo "Loading herdr..."

if [[ -z "$HERDR_SESSION" && ( -n "$FORCE_HERDR" || ( -t 0 && ( -z "$TERM_PROGRAM" || -n "$VSCODE_INJECTION" ) ) ) ]]; then
  if [[ -n "$VSCODE_INJECTION" ]]; then
    _session="vscode-$PPID"
  else
    _session="main"
  fi
  _cwd="$PWD"
  _line="$(herdr session list 2>/dev/null | grep "^${_session}[[:space:]]")"
  if [[ -n "$_line" ]]; then
    herdr tab create --session "$_session" --cwd "$_cwd" --focus >/dev/null 2>&1
  fi
  if [[ -n "$_line" && "$_line" == *"clients:"*[1-9]* ]]; then
    exec herdr --session "${_session}-$$"
  else
    exec herdr --session "${_session}"
  fi
  unset _session _line _cwd
fi

update() {
  set -e  # fail fast if anything breaks
  echo "Updating brew..." && brew update
  echo "Upgrading packages..." && brew upgrade --greedy
  echo "Cleaning up..." && brew cleanup -s
  echo "Updating zinit..." && zinit self-update
  echo "Updating plugins..." && zinit update --all
  echo "✓ All updates done"
}
