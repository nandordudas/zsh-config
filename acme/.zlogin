if [[ -z "$HERDR_SESSION" && ( -n "$FORCE_HERDR" || ( -t 0 && -z "$VSCODE_INJECTION" && -z "$TERM_PROGRAM" ) ) ]]; then
  _session="main"
  _line="$(herdr session list 2>/dev/null | grep "^${_session}[[:space:]]")"
  if [[ -n "$_line" && "$_line" == *"clients:"*[1-9]* ]]; then
    exec herdr --session "${_session}-$$"
  else
    exec herdr --session "${_session}"
  fi
  unset _session _line
fi

update() {
  set -e  # fail fast if anything breaks
  echo "Updating brew..." && brew update
  echo "Upgrading packages..." && brew upgrade
  echo "Cleaning up..." && brew cleanup -s
  echo "Updating zinit..." && zinit self-update
  echo "Updating plugins..." && zinit update --all
  echo "✓ All updates done"
}
