#!/bin/bash
# Server side. Restore public_html exactly from an archive in ~/site-backups.
# Archives the current public_html first, so a restore can itself be undone.
# .well-known and cgi-bin are never emptied; files the archive holds under them are added
# back, so an old certificate-validation file may reappear there. That is harmless.
#
#   bash restore.sh public_html-20260913-202543.tar.gz
set -euo pipefail
shopt -s dotglob nullglob

ACCOUNT_HOME="${ACCOUNT_HOME:-/home8/sp123519}"
WEB="$ACCOUNT_HOME/public_html"
BACKUPS="${BACKUPS:-$ACCOUNT_HOME/site-backups}"
NAME="${1:-}"

fail() { echo "restore: $*" >&2; exit 1; }
[ -n "$NAME" ] || fail "name the archive, e.g. public_html-2026-09-13.tar.gz"
ARCHIVE="$BACKUPS/$(basename "$NAME")"
[ -f "$ARCHIVE" ] || fail "no archive $ARCHIVE"
tar -tzf "$ARCHIVE" | grep -q '^public_html/index.html$' || fail "$ARCHIVE does not contain public_html/index.html"

BEFORE="$BACKUPS/public_html-$(date +%Y%m%d-%H%M%S)-before-restore.tar.gz"
mkdir -p "$BACKUPS"
tar -czf "$BEFORE" -C "$ACCOUNT_HOME" public_html

for entry in "$WEB"/*; do
  case "$(basename "$entry")" in .well-known|cgi-bin) continue ;; esac
  rm -rf "$entry"
done
tar -xzf "$ARCHIVE" -C "$ACCOUNT_HOME"
[ -f "$WEB/index.html" ] || fail "index.html missing after restore; previous state is in $BEFORE"
echo "restore done from $ARCHIVE; the state before restoring is archived at $BEFORE"
