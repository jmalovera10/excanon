#!/usr/bin/env bash
# Creates or updates the labels from .agents/backlog/labels.tsv in the backlog repository.
# Usage: scripts/agents/sync-backlog-labels.sh [--prune] [owner/repo]
#   --prune     also delete labels that are not in labels.tsv (asks for confirmation)
#   owner/repo  defaults to jmalovera10/excanon-backlog
set -euo pipefail

prune=false
if [[ "${1:-}" == "--prune" ]]; then
  prune=true
  shift
fi
repo="${1:-jmalovera10/excanon-backlog}"
labels_file="$(cd "$(dirname "$0")/../.." && pwd)/.agents/backlog/labels.tsv"

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
