#!/usr/bin/env bash
# Builds the site and checks the built output. Usage: scripts/check-site.sh [path-to-hugo]
set -euo pipefail
HUGO=${1:-hugo}
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT
"$HUGO" --gc --minify -d "$OUT" | grep -iE "error|warn" || true

fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
I="$OUT/index.html"
P="$OUT/posts/20241005/index.html"

# Home page
check "home: name, handle, avatar from params" "grep -q 'Shlomi Green' $I && grep -q '@shlomigreen' $I && grep -q 'avatars.githubusercontent.com' $I"
check "home: all titles in data-titles"   "grep -q 'ai-engineer' $I && grep -q '3d-printing-artist' $I && grep -q 'data-titles' $I"
check "home: chip width = longest title"  "grep -q -- '--w:18ch' $I"
check "home: 3 labeled social links"      "[ \$(grep -oE '<a [^>]*aria-label=' $I | wc -l) -eq 3 ]"
check "home: 3 font awesome brand icons"  "[ \$(grep -o 'fa-brands fa-' $I | wc -l) -eq 3 ]"
check "home: no link to posts"            "! grep -q '/posts/' $I"
check "no taxonomy/list/rss output"       "[ ! -e $OUT/tags ] && [ ! -e $OUT/categories ] && [ ! -e $OUT/index.xml ] && [ ! -e $OUT/posts/index.html ]"

# Archived posts keep their URLs
for p in 20240928 20241005; do
  check "post /posts/$p/ exists" "[ -f $OUT/posts/$p/index.html ]"
done
check "post: drafts not built"            "[ ! -e $OUT/posts/first_post ] && [ ! -e $OUT/posts/identifying-bottlenecks ]"
check "post: 2 admonitions as <details>"  "[ -f $P ] && [ \$(grep -o '<details' $P | wc -l) -eq 2 ]"
check "post: person shortcode -> link"    "[ -f $P ] && grep -q 'x.com/theshlomigreen' $P"

exit $fail
