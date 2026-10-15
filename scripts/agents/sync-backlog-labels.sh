#!/usr/bin/env bash
# Creates or updates labels from a TSV file (name, color, description) in a repository.
# Usage: scripts/agents/sync-backlog-labels.sh [--prune] [--file labels.tsv] [owner/repo]
#   --prune     also delete labels that are not in the file (asks for confirmation)
#   --file      defaults to .agents/backlog/labels.tsv
#   owner/repo  defaults to jmalovera10/excanon-backlog
# Public issue labels: scripts/agents/sync-backlog-labels.sh --file .agents/backlog/public-labels.tsv jmalovera10/excanon
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
prune=false
labels_file="$root/.agents/backlog/labels.tsv"
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --prune) prune=true; shift ;;
    --file) labels_file="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift 2 ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done
repo="${1:-jmalovera10/excanon-backlog}"

command -v gh >/dev/null || { echo "gh CLI is required" >&2; exit 1; }

declare -A wanted=()
while IFS=$'\t' read -r name color description; do
  [[ -z "$name" ]] && continue
  wanted["$name"]=1
  gh label create "$name" --repo "$repo" --color "$color" --description "$description" --force >/dev/null
  echo "synced  $name"
done < "$labels_file"

if $prune; then
  extra=()
  while IFS= read -r name; do
    [[ -z "${wanted[$name]:-}" ]] && extra+=("$name")
  done < <(gh label list --repo "$repo" --limit 500 --json name --jq '.[].name')

  if (( ${#extra[@]} )); then
    printf 'Labels not in labels.tsv:\n'; printf '  %s\n' "${extra[@]}"
    read -r -p "Delete these ${#extra[@]} labels from $repo? [y/N] " answer
    if [[ "$answer" == "y" ]]; then
      for name in "${extra[@]}"; do
        gh label delete "$name" --repo "$repo" --yes >/dev/null
        echo "deleted $name"
      done
    fi
  fi
fi
