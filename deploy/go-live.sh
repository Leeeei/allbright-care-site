#!/bin/bash
# Replace the Sitejet site in public_html with the build in site/.
#
# Everything in public_html moves aside into OLD, except .well-known (AutoSSL needs
# it) and cgi-bin. Nothing is deleted. If any step fails, the moved entries go back.
#
#   bash deploy/go-live.sh --check   verify preconditions only, change nothing
#   bash deploy/go-live.sh           go live
set -euo pipefail
shopt -s dotglob nullglob

ACCOUNT_HOME="${ACCOUNT_HOME:-/home8/sp123519}"
WEB="$ACCOUNT_HOME/public_html"
OLD="${OLD:-$ACCOUNT_HOME/_old-site-2026-09-13}"
SRC="${SRC:-$ACCOUNT_HOME/repositories/allbright-care-site/site}"

fail() { echo "go-live: $*" >&2; exit 1; }

[ -d "$WEB" ] || fail "no $WEB"
[ -f "$SRC/index.html" ] && [ -f "$SRC/.htaccess" ] && [ -d "$SRC/assets" ] || fail "build incomplete in $SRC"
grep -q 'noindex' "$SRC/index.html" && fail "$SRC is a staging build (noindex)"
[ -e "$OLD" ] && fail "$OLD already exists; refusing to mix two old sites"

if [ "${1:-}" = "--check" ]; then
  echo "go-live check passed: $(ls -A "$WEB" | wc -l) entries in public_html, build ready"
  exit 0
fi

mkdir -p "$OLD"
moved=()
restore() {
  echo "go-live: failed, putting the old site back" >&2
  for name in "${moved[@]}"; do
    rm -rf "$WEB/$name"
    mv "$OLD/$name" "$WEB/$name"
  done
  rmdir "$OLD" 2>/dev/null || true
}
trap restore ERR

for entry in "$WEB"/*; do
  name="$(basename "$entry")"
  case "$name" in .well-known|cgi-bin) continue ;; esac
  mv "$entry" "$OLD/$name"
  moved+=("$name")
done

cp -R "$SRC"/. "$WEB"/
[ -f "$WEB/index.html" ] && [ -f "$WEB/.htaccess" ]
trap - ERR
echo "go-live done: ${#moved[@]} entries moved to $OLD"
