#!/usr/bin/env bash
# Bumps the CACHE version in sw.js, commits, and pushes to main.
# GitHub Pages (main /root) redeploys automatically on push.
set -euo pipefail
cd "$(dirname "$0")"

SW_FILE="sw.js"

CURRENT=$(grep -oE 'fingerblock-v[0-9]+' "$SW_FILE" | head -1)
NUM=$(echo "$CURRENT" | grep -oE '[0-9]+$')
NEXT_NUM=$((NUM + 1))
NEXT="fingerblock-v${NEXT_NUM}"

sed -i "s/$CURRENT/$NEXT/" "$SW_FILE"
echo "Bumped cache version: $CURRENT -> $NEXT"

git add -A
git commit -m "Deploy: bump cache to $NEXT"
git push origin main

echo "Pushed to main. GitHub Pages will redeploy shortly:"
echo "https://foodwise-hub.github.io/finger-block/"
