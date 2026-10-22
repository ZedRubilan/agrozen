#!/usr/bin/env bash
# Builds the GitHub Pages site into a gh-pages worktree and commits it.
#
#   zedrubilan.github.io/agrozen/       download page (site/index.html)
#   zedrubilan.github.io/agrozen/app/   Flutter web app
#   zedrubilan.github.io/agrozen/bank/  bank dashboard demo
#
# The web build carries no API keys, so it runs on local knowledge only.
# Push afterwards with: git push origin gh-pages
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/../agrozen-gh-pages}"
cd "$ROOT"

flutter build web --release --base-href /agrozen/app/

if [ ! -d "$OUT/.git" ] && [ ! -f "$OUT/.git" ]; then
  git fetch origin gh-pages
  git worktree add "$OUT" gh-pages
fi

# Replace everything except git metadata.
find "$OUT" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +

cp -r build/web "$OUT/app"
cp site/index.html site/icon.png "$OUT/"
cp -r site/shots "$OUT/shots"
# The bank dashboard links ../favicon.png and ../icons/.
cp -r web/bank web/icons web/favicon.png "$OUT/"
touch "$OUT/.nojekyll"

cd "$OUT"
git add -A
git commit -m "Deploy AgroZen site ($(git -C "$ROOT" rev-parse --short HEAD)): download page + web app at /app/"
echo "Committed to gh-pages in $OUT — now run: git push origin gh-pages"
