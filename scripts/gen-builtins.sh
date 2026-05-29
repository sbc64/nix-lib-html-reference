#!/usr/bin/env bash
# Read `nix __dump-language` JSON from stdin, emit a Markdown fragment.
# Schema (per upstream Nix):
#   { "<name>": { "args": ["arg1", ...], "doc": "<markdown>",
#                 "type": "<type>", "impure-only": true, "experimental-feature": "<xp>" }, ... }
set -euo pipefail

jq -r '
  "# Nix language builtins & constants\n",
  (to_entries
   | sort_by(.key)
   | .[]
   | "## `builtins.\(.key)`"
     + (if (.value.args // []) | length > 0
          then " " + ((.value.args // []) | map("*\(.)*") | join(" "))
          else "" end)
     + (if .value.type then "  \n*type*: `\(.value.type)`" else "" end)
     + "\n",
     (if .value["impure-only"] then "> Only available in impure evaluation mode.\n" else empty end),
     (if .value["experimental-feature"]
        then "> Requires experimental feature `\(.value["experimental-feature"])`.\n"
        else empty end),
     ((.value.doc // "") + "\n")
  )
' | sed 's|@docroot@|https://nix.dev/manual/nix/latest|g'
