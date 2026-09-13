#!/bin/bash
# Put the old site back after go-live.sh.
#
# The new site's files move aside into FAILED (kept for inspection), then every
# entry go-live.sh moved into OLD returns to public_html. .well-known and cgi-bin
# never moved, so they are left alone.
set -euo pipefail
shopt -s dotglob nullglob

ACCOUNT_HOME="${ACCOUNT_HOME:-/home8/sp123519}"
WEB="$ACCOUNT_HOME/public_html"
OLD="${OLD:-$ACCOUNT_HOME/_old-site-2026-09-13}"
FAILED="${FAILED:-$ACCOUNT_HOME/_rolled-back-site-$(date +%Y%m%d-%H%M%S)}"

fail() { echo "rollback: $*" >&2; exit 1; }
[ -d "$OLD" ] && [ -f "$OLD/index.html" ] || fail "no old site in $OLD"

mkdir -p "$FAILED"
for entry in "$WEB"/*; do
  name="$(basename "$entry")"
  case "$name" in .well-known|cgi-bin) continue ;; esac
  mv "$entry" "$FAILED/$name"
done
for entry in "$OLD"/*; do
  mv "$entry" "$WEB/$(basename "$entry")"
done
rmdir "$OLD"
echo "rollback done: old site restored, new site kept in $FAILED"
