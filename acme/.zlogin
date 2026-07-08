echo "3. Sourcing .zlogin"

if [[ -z "$HERDR_SESSION" ]]; then
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
  brew update
  brew upgrade
  brew cleanup -s
  zinit self-update
  zinit update --all
}
