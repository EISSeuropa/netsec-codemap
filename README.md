# netsec-codemap

Interactive architecture map of the [netsec.github.io](https://github.com/EISSeuropa/netsec.github.io) codebase, generated with the Understand-Anything knowledge-graph tool.

**Live view: <https://codemap.netsec-cost.eu/>**

This is a hand-refreshed snapshot, not a live view. It reflects the repository at the commit and date recorded in `meta.json`, so it can lag the current `main`. The maintainer rebuilds it when a refresh is worthwhile.

## Refreshing the snapshot

The bundle is a static export of the Understand-Anything dashboard with the knowledge graph baked in as a plain JSON file.

**1. Regenerate the graph.** In a checkout of `netsec.github.io`, run the Understand-Anything analysis (the `/understand` skill) so `.understand-anything/knowledge-graph.json` and `.understand-anything/meta.json` are current. This is the one step the script cannot do for you, as the analysis is interactive.

**2. Run the publish script.** From a clone of this repo:

```bash
./publish.sh /path/to/netsec.github.io
```

It stages the fresh graph into the dashboard, rebuilds the bundle at the site root, syncs the result over this repo (preserving `CNAME`, `.nojekyll`, `README.md` and the script itself), then commits and pushes. GitHub Pages redeploys in under a minute. If the graph is unchanged it exits without a commit, so re-running is safe.

Add `--dry-run` to build and sync without committing or pushing, so you can inspect the working tree first:

```bash
./publish.sh /path/to/netsec.github.io --dry-run
```

The script auto-detects the dashboard in the Understand-Anything plugin cache. If that lookup fails on an unusual plugin layout, point it explicitly with `PLUGIN=/path/to/.../packages/dashboard ./publish.sh ...`.

### Doing it by hand

If you would rather not use the script, the same moves are:

```bash
PLUGIN="$HOME/.claude/plugins/cache/understand-anything/understand-anything/2.8.1/packages/dashboard"
REPO="/path/to/netsec.github.io"

cp "$REPO/.understand-anything/knowledge-graph.json" "$PLUGIN/public/"
cp "$REPO/.understand-anything/meta.json"            "$PLUGIN/public/"
( cd "$PLUGIN" && npm run build:demo -- --base=/ )

# from a clone of this repo
rsync -a --delete --exclude='.git' --exclude='CNAME' --exclude='.nojekyll' \
  --exclude='README.md' --exclude='publish.sh' "$PLUGIN/dist/" ./
git add -A && git commit -m "Refresh codemap snapshot" && git push
```

The `--base=/` matters: this site is served at the root of `codemap.netsec-cost.eu`. If it is ever moved to a subpath, rebuild with `--base=/that-path/` instead.

## Hosting

- Static files served by GitHub Pages from the `main` branch, root.
- Custom domain `codemap.netsec-cost.eu`, set by the `CNAME` file in this repo plus a DNS `CNAME` record pointing `codemap` at `eisseuropa.github.io`.
- No build step or automation runs in this repo. Everything is committed pre-built, so a refresh is a manual rebuild-and-push as above.
