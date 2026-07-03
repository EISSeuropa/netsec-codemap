#!/usr/bin/env bash
#
# publish.sh — rebuild the codemap bundle from netsec.github.io's current
# knowledge graph and push it live to codemap.netsec-cost.eu.
#
# Run from a clone of THIS repo:  ./publish.sh /path/to/netsec.github.io [--dry-run]
#
# Prerequisite: regenerate the graph first (the /understand skill in a
# netsec.github.io checkout) so .understand-anything/knowledge-graph.json is
# current. This script does the build + publish, not the analysis.
#
# --dry-run builds and syncs but skips the commit + push, so you can inspect
# the working tree before anything leaves the machine.
set -euo pipefail

REPO="${1:-}"
DRY_RUN=""
[[ "${2:-}" == "--dry-run" || "${1:-}" == "--dry-run" ]] && DRY_RUN=1
[[ "$REPO" == "--dry-run" ]] && REPO=""

# Locate the Understand-Anything dashboard in the plugin cache (newest version).
PLUGIN="${PLUGIN:-$(ls -d "$HOME"/.claude/plugins/cache/understand-anything/understand-anything/*/packages/dashboard 2>/dev/null | sort -V | tail -1)}"

if [[ -z "$REPO" || ! -f "$REPO/.understand-anything/knowledge-graph.json" ]]; then
  echo "usage: ./publish.sh /path/to/netsec.github.io [--dry-run]" >&2
  echo "  that checkout must hold a fresh .understand-anything/knowledge-graph.json" >&2
  echo "  (run the /understand skill there first)" >&2
  exit 1
fi
if [[ -z "$PLUGIN" || ! -f "$PLUGIN/package.json" ]]; then
  echo "error: could not find the Understand-Anything dashboard in the plugin cache." >&2
  echo "  set PLUGIN=/path/to/.../packages/dashboard and retry." >&2
  exit 1
fi

HERE="$(cd "$(dirname "$0")" && pwd)"   # this script sits at the repo root

echo "→ staging graph from $REPO"
cp "$REPO/.understand-anything/knowledge-graph.json" "$PLUGIN/public/"
cp "$REPO/.understand-anything/meta.json"            "$PLUGIN/public/"

echo "→ building bundle (base=/)"
( cd "$PLUGIN" && npm run build:demo -- --base=/ )

echo "→ syncing dist into $HERE"
rsync -a --delete \
  --exclude='.git' --exclude='CNAME' --exclude='.nojekyll' \
  --exclude='README.md' --exclude='publish.sh' \
  "$PLUGIN/dist/" "$HERE/"

cd "$HERE"
if git diff --quiet && git diff --cached --quiet; then
  echo "✓ no changes — the published graph already matches this snapshot."
  exit 0
fi

commit_hash="$(python3 -c "import json;print(json.load(open('meta.json'))['gitCommitHash'][:8])" 2>/dev/null || echo unknown)"

if [[ -n "$DRY_RUN" ]]; then
  echo "→ dry run: built and synced, skipping commit + push. Pending changes:"
  git status --short
  echo "  (graph @ $commit_hash — commit message would record it)"
  exit 0
fi

echo "→ committing + pushing"
git add -A
git commit -q -m "Refresh codemap snapshot (graph @ $commit_hash)"
git push -q
echo "✓ pushed. GitHub Pages redeploys in under a minute → https://codemap.netsec-cost.eu/"
