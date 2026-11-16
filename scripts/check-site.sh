#!/usr/bin/env bash
# Builds the site and checks the built output. Usage: scripts/check-site.sh [path-to-hugo]
set -euo pipefail
HUGO=${1:-hugo}
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT

# A failed build or any warning fails the script, showing Hugo's output.
LOG=$("$HUGO" --gc --minify -d "$OUT" 2>&1) || { echo "$LOG"; echo "FAIL hugo build"; exit 1; }
if grep -q WARN <<<"$LOG"; then echo "$LOG"; echo "FAIL hugo printed warnings"; exit 1; fi

fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
HOME_HTML="$OUT/index.html"
POST_HTML="$OUT/posts/20241005/index.html"

# Home page
check "home: name, handle, avatar from params" "grep -q 'Shlomi Green' $HOME_HTML && grep -q '@shlomigreen' $HOME_HTML && grep -q 'avatars.githubusercontent.com' $HOME_HTML"
check "home: all titles in data-titles"   "grep -q 'ai-engineer' $HOME_HTML && grep -q '3d-printing-artist' $HOME_HTML && grep -q 'data-titles' $HOME_HTML"
check "home: chip width = longest title"  "grep -q -- '--w:18ch' $HOME_HTML"
check "home: 3 labeled social links"      "[ \$(grep -oE '<a [^>]*aria-label=' $HOME_HTML | wc -l) -eq 3 ]"
check "home: 3 font awesome brand icons"  "[ \$(grep -o 'fa-brands fa-' $HOME_HTML | wc -l) -eq 3 ]"
check "home: font awesome css loaded"     "grep -q 'font-awesome' $HOME_HTML"
check "home: screen-reader roles sentence" "grep -q 'Roles: ai-engineer, ' $HOME_HTML"
check "home: og:title"                    "grep -q 'og:title' $HOME_HTML"
check "home: no link to posts"            "! grep -q '/posts/' $HOME_HTML"
check "no taxonomy/list/rss output"       "[ ! -e $OUT/tags ] && [ ! -e $OUT/categories ] && [ ! -e $OUT/index.xml ] && [ ! -e $OUT/posts/index.html ]"
check "sitemap.xml lists posts"           "[ -f $OUT/sitemap.xml ] && grep -q '/posts/20241005/' $OUT/sitemap.xml"

check "css: no self-referencing variables" "! grep -qE -- '--([a-z0-9-]+): *var\\(--\\1\\)' $OUT/style.css"

# Archived posts keep their URLs
for p in 20240928 20241005; do
  check "post /posts/$p/ exists" "[ -f $OUT/posts/$p/index.html ]"
done
check "post: drafts not built"            "[ ! -e $OUT/posts/first_post ] && [ ! -e $OUT/posts/identifying-bottlenecks ]"
check "post: 2 admonitions as <details>"  "[ -f $POST_HTML ] && [ \$(grep -o '<details' $POST_HTML | wc -l) -eq 2 ]"
check "post: person shortcode -> link"    "[ -f $POST_HTML ] && grep -q 'x.com/theshlomigreen' $POST_HTML"
check "post: og:title"                    "grep -q 'og:title' $POST_HTML"
check "post: no font awesome"             "! grep -q 'font-awesome' $POST_HTML"
check "post: no rel=me"                   "! grep -qE 'rel=\"?me' $POST_HTML"

exit $fail
