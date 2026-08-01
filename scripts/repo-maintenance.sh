#!/usr/bin/env bash
# scripts/repo-maintenance.sh
# Cleans up git repos under a root directory: prunes branches whose remote
# tracking ref is gone, runs git maintenance, removes build artifacts, and
# reports/deletes global tool caches. See
# docs/superpowers/specs/2026-08-01-repo-maintenance-design.md.

set -euo pipefail

ROOT="${CODE_DIR:-$HOME/Development/code}"
DRY_RUN=0
ASSUME_YES=0

usage() {
  cat <<USAGE
Usage: repo-maintenance.sh <branches|maintenance|clean|caches|all> [--root PATH] [--dry-run] [--yes]

Subcommands:
  maintenance  run 'git maintenance run --auto' in each repo

Not yet implemented — these list the repos they would act on, then exit 2:
  branches     delete local branches whose remote tracking ref is gone
  clean        run each ecosystem's native clean command / remove build dirs
  caches       report (and optionally delete) global tool caches
  all          run maintenance, branches, clean, then caches, in that order

Options:
  --root PATH  scan root (default: ${CODE_DIR:-\$HOME/Development/code})
  --dry-run    print actions without mutating anything
  --yes        skip confirmation prompts
USAGE
}

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

SUBCOMMAND="$1"
shift

case "$SUBCOMMAND" in
  -h|--help)
    usage
    exit 0
    ;;
  branches|maintenance|clean|caches|all)
    ;;
  *)
    printf "Unknown subcommand: %s\n" "$SUBCOMMAND" >&2
    usage >&2
    exit 1
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --yes)
      ASSUME_YES=1
      shift
      ;;
    *)
      printf "Unknown option: %s\n" "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

discover_repos() {
  find "$ROOT" -maxdepth 4 \
    \( -name node_modules -o -name vendor \) -prune -o \
    -type d -name .git -print \
    | sed 's|/\.git$||'
}

# Placeholder for the subcommands that are still specified but unwritten. It
# lists the repos the real phase would visit, then exits 2 so no caller (or
# cron job) mistakes a no-op for a completed run.
list_repos_only() {
  while IFS= read -r repo; do
    printf "==> %s: %s\n" "$SUBCOMMAND" "$repo"
  done < <(discover_repos)
  printf "\n'%s' is not implemented yet — nothing above was modified.\n" "$SUBCOMMAND" >&2
  printf "See docs/superpowers/specs/2026-08-01-repo-maintenance-design.md\n" >&2
  return 2
}

phase_maintenance() {
  while IFS= read -r repo; do
    printf "==> maintenance: %s\n" "$repo"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf "    (dry-run) git maintenance run --auto\n"
    else
      git -C "$repo" maintenance run --auto
    fi
  done < <(discover_repos)
}

case "$SUBCOMMAND" in
  maintenance) phase_maintenance ;;
  branches)    list_repos_only ;;
  clean)       list_repos_only ;;
  caches)      list_repos_only ;;
  all)         list_repos_only ;;
esac
