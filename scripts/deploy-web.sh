#!/bin/sh
# Publish builds/web/ to https://nim.yermom.dev
# Git push does not do this. Jupiter nginx bind-mounts /home/aaron/docker/nim/html/
set -e
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
WEB="$ROOT/builds/web"
HOST="aaron@192.168.1.40"
DEST="/home/aaron/docker/nim/html/"

test -f "$WEB/index.pck" || { echo "missing $WEB/index.pck — export Web first"; exit 1; }
test -f "$WEB/cachebust.js" || { echo "missing $WEB/cachebust.js — do not deploy without it"; exit 1; }
test -f "$WEB/index.service.worker.js" || { echo "missing $WEB/index.service.worker.js — do not deploy without the SW kill-switch"; exit 1; }

# Versioned pack name so browsers cannot reuse a cached index.pck (the 2D build was 78 KB).
cp -f "$WEB/index.pck" "$WEB/nim3d.pck"

rsync -av --exclude '*.import' "$WEB/" "$HOST:$DEST"

echo "deployed. live HTML should mention cachebust.js / nim3d.pck"
ssh "$HOST" 'grep -E "nim-3d|cachebust|nim3d.pck" /home/aaron/docker/nim/html/index.html | head'
