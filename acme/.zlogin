update() {
  set -e  # fail fast if anything breaks
  echo "Updating brew..." && brew update
  echo "Upgrading packages..." && brew upgrade --greedy
  echo "Cleaning up..." && brew cleanup -s
  echo "Updating zinit..." && zinit self-update
  echo "Updating plugins..." && zinit update --all
  echo "✓ All updates done"
}
