#!/usr/bin/env bash
# Regenerate the CV PDF from cv/index.html.
# One source of truth: edit index.html, re-run this, commit both.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT="$DIR/Hrvoje-Grdic-CV.pdf"

[ -x "$CHROME" ] || { echo "Chrome not found at $CHROME" >&2; exit 1; }

# Isolated profile so this never touches a running Chrome session.
PROFILE="$(mktemp -d)"
rm -f "$OUT"

# Headless Chrome does not always exit on its own here, so run it detached,
# wait for the file to appear and settle, then stop it.
"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-first-run \
  --no-pdf-header-footer \
  --user-data-dir="$PROFILE" \
  --print-to-pdf="$OUT" \
  "file://$DIR/index.html" >/dev/null 2>&1 &
PID=$!

for _ in $(seq 1 30); do [ -s "$OUT" ] && break; sleep 1; done
sleep 2
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
rm -rf "$PROFILE" 2>/dev/null || true

[ -s "$OUT" ] || { echo "PDF was not produced" >&2; exit 1; }
echo "Wrote $OUT ($(mdls -name kMDItemNumberOfPages -raw "$OUT") pages)"
