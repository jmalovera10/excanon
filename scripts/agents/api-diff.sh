#!/usr/bin/env bash
# Shows how excanon's public API changed between a base ref and the working tree.
# Usage: scripts/agents/api-diff.sh [base-ref]   (default: origin/main)
# Exit status: 0 if the API is unchanged, 1 if it changed, 2 on error.
set -euo pipefail

base="${1:-origin/main}"
repo="$(git rev-parse --show-toplevel)"
tmp="$(mktemp -d)"
trap 'git -C "$repo" worktree remove --force "$tmp/base" >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT

# surface <project dir> <deps dir> <build dir>: compile the project and print its public API.
surface() {
  (
    cd "$1"
    export MIX_DEPS_PATH="$2" MIX_BUILD_PATH="$3"
    mix deps.get >/dev/null
    mix compile >/dev/null
    mix run --no-start --no-compile "$repo/scripts/agents/api_surface.exs"
  )
}

git -C "$repo" worktree add --detach "$tmp/base" "$base" >/dev/null 2>&1 || { echo "cannot check out $base" >&2; exit 2; }
surface "$tmp/base" "$tmp/deps-base" "$tmp/build-base" > "$tmp/base.txt" || exit 2
surface "$repo" "$tmp/deps-head" "$tmp/build-head" > "$tmp/head.txt" || exit 2

if diff -u --label "public API at $base" --label "public API in working tree" "$tmp/base.txt" "$tmp/head.txt"; then
  echo "Public API unchanged."
else
  exit 1
fi
