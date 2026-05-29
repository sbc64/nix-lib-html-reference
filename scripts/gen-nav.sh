#!/usr/bin/env bash
# Emit the sidebar nav HTML.
#
# Structure (no link inside <summary> to avoid the click-conflict between
# "toggle details" and "trigger htmx swap"):
#   <a class="nav-top" ...>intro</a>
#   <details>
#     <summary>category</summary>
#     <ul>
#       <li><a class="nav-overview" ...>overview</a></li>
#       <li><a data-anchor=... ...>fn</a></li>
#       ...
#     </ul>
#   </details>
set -euo pipefail

ORDER=(
  builtins
  lib-asserts lib-attrsets lib-cli lib-customisation lib-debug
  lib-derivations lib-fetchers lib-fileset lib-filesystem lib-fixedPoints
  lib-generators lib-gvariant lib-lists lib-meta lib-options lib-path
  lib-sources lib-strings lib-trivial lib-versions
)

fragdir=${1:?fragments dir required}

# href="#" gives the link a real cursor/keyboard semantics. htmx
# prevents default on click, so the browser never actually navigates.
attrs() {
  local frag=$1 anchor=${2:-}
  if [[ -n $anchor ]]; then
    printf 'href="#" hx-get="fragments/%s.html" hx-target="#content" hx-swap="innerHTML" hx-trigger="click" data-path="%s" data-anchor="%s"' \
           "$frag" "$frag" "$anchor"
  else
    printf 'href="#" hx-get="fragments/%s.html" hx-target="#content" hx-swap="innerHTML" hx-trigger="click" data-path="%s"' \
           "$frag" "$frag"
  fi
}

emit_category() {
  local slug=$1
  local file="$fragdir/$slug.html"
  [[ -f $file ]] || return 0

  local label
  if [[ $slug == builtins ]]; then label="builtins"
  else label="lib.${slug#lib-}"; fi

  printf '<details data-cat="%s">\n' "$slug"
  printf '  <summary>%s</summary>\n' "$label"
  printf '  <ul>\n'
  printf '    <li><a class="nav-overview" %s>overview</a></li>\n' "$(attrs "$slug")"
  tr '\n' ' ' < "$file" \
    | grep -oE '<h2[^>]*id="[^"]+"[^>]*>[[:space:]]*<code>[^<]+</code>' \
    | while IFS= read -r match; do
        id=$(printf '%s' "$match" | sed -nE 's/.*id="([^"]+)".*/\1/p')
        name=$(printf '%s' "$match" | sed -nE 's/.*<code>([^<]+)<\/code>.*/\1/p')
        short=${name#builtins.}
        short=${short#lib.}
        short=${short#*.}
        printf '    <li><a %s>%s</a></li>\n' "$(attrs "$slug" "$id")" "$short"
      done
  printf '  </ul>\n'
  printf '</details>\n'
}

printf '<a class="nav-top" %s>intro</a>\n' "$(attrs intro)"

for slug in "${ORDER[@]}"; do
  emit_category "$slug"
done
