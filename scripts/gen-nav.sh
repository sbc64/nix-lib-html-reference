#!/usr/bin/env bash
# Read fragment HTML files passed as args; emit a collapsible <details> tree
# for the sidebar nav. Each h2 inside a fragment becomes a child link with a
# data-anchor attribute so the page can scroll-into-view after htmx swap.
set -euo pipefail

# Hard-coded order so builtins comes first and lib-* are alphabetical.
ORDER=(
  builtins
  lib-asserts lib-attrsets lib-cli lib-customisation lib-debug
  lib-derivations lib-fetchers lib-fileset lib-filesystem lib-fixedPoints
  lib-generators lib-gvariant lib-lists lib-meta lib-options lib-path
  lib-sources lib-strings lib-trivial lib-versions
)

fragdir=${1:?fragments dir required}

emit_category() {
  local slug=$1
  local file="$fragdir/$slug.html"
  [[ -f $file ]] || return 0

  local label
  if [[ $slug == builtins ]]; then
    label="builtins"
  else
    label="${slug#lib-}"
    label="lib.$label"
  fi

  printf '<details data-cat="%s">\n' "$slug"
  printf '  <summary><a hx-get="fragments/%s.html" hx-target="#content" hx-push-url="true" data-path="%s">%s</a></summary>\n' \
         "$slug" "$slug" "$label"
  printf '  <ul>\n'
  # Match <h2 ... id="X" ...> ... <code>Y</code>
  # Pandoc's output may have whitespace/linebreaks between h2 and code, so
  # collapse to a single line first.
  tr '\n' ' ' < "$file" \
    | grep -oE '<h2[^>]*id="[^"]+"[^>]*>[[:space:]]*<code>[^<]+</code>' \
    | while IFS= read -r match; do
        id=$(printf '%s' "$match" | sed -nE 's/.*id="([^"]+)".*/\1/p')
        name=$(printf '%s' "$match" | sed -nE 's/.*<code>([^<]+)<\/code>.*/\1/p')
        # Strip the lib.<category>. or builtins. prefix for a tighter label.
        short=${name#builtins.}
        short=${short#lib.}
        short=${short#*.}
        printf '    <li><a hx-get="fragments/%s.html" hx-target="#content" hx-push-url="true" data-path="%s" data-anchor="%s">%s</a></li>\n' \
               "$slug" "$slug" "$id" "$short"
      done
  printf '  </ul>\n'
  printf '</details>\n'
}

printf '<details data-cat="intro" open>\n'
printf '  <summary><a hx-get="fragments/intro.html" hx-target="#content" hx-push-url="true" data-path="intro">intro</a></summary>\n'
printf '</details>\n'

for slug in "${ORDER[@]}"; do
  emit_category "$slug"
done
