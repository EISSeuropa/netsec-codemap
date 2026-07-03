# netsec-codemap

Interactive architecture map of the [netsec.github.io](https://github.com/EISSeuropa/netsec.github.io) codebase, generated with the Understand-Anything knowledge-graph tool.

**Live view: <https://codemap.netsec-cost.eu/>**

This is a hand-refreshed snapshot, not a live view. It reflects the repository at the commit and date recorded in `meta.json`, so it can lag the current `main`. The maintainer rebuilds it when a refresh is worthwhile.

## Refreshing the snapshot

The bundle is a static export of the Understand-Anything dashboard with the knowledge graph baked in as a plain JSON file. To refresh it against the current codebase:

**1. Regenerate the graph.** In a checkout of `netsec.github.io`, run the Understand-Anything analysis (the `/understand` skill) so `.understand-anything/knowledge-graph.json` and `.understand-anything/meta.json` are current.

**2. Stage the graph into the dashboard and build.** The dashboard lives in the Understand-Anything plugin cache. Copy the two files into its `public/` directory, then build the demo bundle at the site root:

```bash
# adjust the plugin version and repo path to your machine
PLUGIN="$HOME/.claude/plugins/cache/understand-anything/understand-anything/2.8.1/packages/dashboard"
REPO="/path/to/netsec.github.io"

cp "$REPO/.understand-anything/knowledge-graph.json" "$PLUGIN/public/"
cp "$REPO/.understand-anything/meta.json"            "$PLUGIN/public/"

cd "$PLUGIN"
npm run build:demo -- --base=/
```

The finished bundle is in `$PLUGIN/dist/`.

**3. Publish.** Replace this repository's tracked files with the new `dist/` contents, keeping `CNAME`, `.nojekyll` and this `README.md`. Commit and push to `main`. GitHub Pages redeploys in under a minute.

```bash
# from a clone of this repo
rsync -a --delete --exclude='.git' --exclude='CNAME' --exclude='.nojekyll' --exclude='README.md' "$PLUGIN/dist/" ./
git add -A && git commit -m "Refresh codemap snapshot" && git push
```

The `--base=/` matters: this site is served at the root of `codemap.netsec-cost.eu`. If it is ever moved to a subpath, rebuild with `--base=/that-path/` instead.

## Hosting

- Static files served by GitHub Pages from the `main` branch, root.
- Custom domain `codemap.netsec-cost.eu`, set by the `CNAME` file in this repo plus a DNS `CNAME` record pointing `codemap` at `eisseuropa.github.io`.
- No build step or automation runs in this repo. Everything is committed pre-built, so a refresh is a manual rebuild-and-push as above.
