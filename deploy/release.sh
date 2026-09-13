#!/bin/bash
# Server side. Publish site/ into public_html, replacing the current release.
#
# First archives public_html exactly to ~/site-backups/public_html-<stamp>.tar.gz. Then removes
# every entry except .well-known (certificate validation) and cgi-bin, and copies site/ in.
# If anything fails after the archive exists, public_html is restored from it.
#
#   bash release.sh --check   preconditions only, changes nothing
#   bash release.sh           release
set -euo pipefail
shopt -s dotglob nullglob

ACCOUNT_HOME="${ACCOUNT_HOME:-/home8/sp123519}"
WEB="$ACCOUNT_HOME/public_html"
SRC="${SRC:-$ACCOUNT_HOME/repositories/allbright-care-site/site}"
BACKUPS="${BACKUPS:-$ACCOUNT_HOME/site-backups}"
ARCHIVE="$BACKUPS/public_html-$(date +%Y%m%d-%H%M%S).tar.gz"

fail() { echo "release: $*" >&2; exit 1; }
[ -d "$WEB" ] || fail "no $WEB"
[ -f "$SRC/index.html" ] && [ -f "$SRC/.htaccess" ] && [ -d "$SRC/assets" ] || fail "build incomplete in $SRC"
grep -q 'noindex' "$SRC/index.html" && fail "$SRC is a staging build (noindex)"
[ -e "$SRC/_redirects" ] && fail "$SRC contains Cloudflare _redirects; build with scripts/build-cpanel.sh"

if [ "${1:-}" = "--check" ]; then
  echo "release check passed: $(ls -A "$WEB" | wc -l | tr -d ' ') entries in public_html, build ready"
  exit 0
fi

mkdir -p "$BACKUPS"
tar -czf "$ARCHIVE" -C "$ACCOUNT_HOME" public_html
tar -tzf "$ARCHIVE" > /dev/null

restore() {
  echo "release: failed, restoring public_html from $ARCHIVE" >&2
  for entry in "$WEB"/*; do
    case "$(basename "$entry")" in .well-known|cgi-bin) continue ;; esac
    rm -rf "$entry"
  done
  tar -xzf "$ARCHIVE" -C "$ACCOUNT_HOME"
}
trap restore ERR

for entry in "$WEB"/*; do
  case "$(basename "$entry")" in .well-known|cgi-bin) continue ;; esac
  rm -rf "$entry"
done
cp -R "$SRC"/. "$WEB"/
[ -f "$WEB/index.html" ] && [ -f "$WEB/.htaccess" ]
trap - ERR
echo "release done; the previous public_html is archived at $ARCHIVE"
