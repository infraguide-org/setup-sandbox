#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
#
# Writes index.json (machine-readable list of decks and files) and index.html
# (download page) into the built slides directory.
# Usage: make-index.sh <name> <src-dir> <dist-dir>
set -euo pipefail

name=$1
src=$(realpath "$2")
cd "$3"

rm -f README.*

decks='[]'
for md in "$src"/*.md; do
  deck=$(basename "$md" .md)
  [ "$deck" = README ] && continue
  [ -f "$deck.html" ] || continue
  title=$(sed -n '/^---$/,/^---$/{s/^title: *//p;}' "$md" | head -1 | sed 's/^"//; s/"$//')
  order=$(sed -n '/^---$/,/^---$/{s/^order: *//p;}' "$md" | head -1)
  covers=${deck#slides-}
  covers=${covers^}
  decks=$(jq -c --arg n "$deck" --arg t "${title:-$deck}" --arg c "$covers" --argjson o "${order:-999}" \
    '. + [{name: $n, title: $t, covers: $c, order: $o, html: "\($n).html", pdf: "\($n).pdf", pptx: "\($n).pptx"}]' <<<"$decks")
done

files=$(find . -type f ! -name 'index.*' | sed 's#^\./##' | sort | jq -R -s -c 'split("\n") | map(select(length > 0))')

jq -n --arg name "$name" --argjson decks "$(jq -c 'sort_by(.order)' <<<"$decks")" --argjson files "$files" \
  '{schema: 1, name: $name, decks: $decks, files: $files}' > index.json

{
  cat <<HTML
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Setup Sandbox</title>
<style>
  body { font: 16px/1.5 system-ui, sans-serif; max-width: 52rem; margin: 2rem auto; padding: 0 1rem; color: #111; background: #fff; }
  img.logo { height: 44px; display: block; margin-bottom: 1.5rem; }
  table { width: 100%; border-collapse: collapse; table-layout: fixed; }
  th, td { padding: .6rem .8rem; border-bottom: 1px solid #e5e7eb; text-align: left; }
  table.decks th:nth-child(1) { width: 52%; }
  table.decks th:nth-child(n+2), table.decks td:nth-child(n+2) { width: 16%; text-align: center; }
  a { color: #2b6cb0; text-decoration: none; }
  a:hover { text-decoration: underline; }
  footer { margin-top: 2rem; font-size: .8rem; color: #fff; }
  footer ::selection, footer::selection { background: #2b6cb0; color: #fff; }
</style>
<a href="https://infraguide.org"><img class="logo" src="assets/logo/logo.svg" alt="infraguide.org"></a>
<h1>Setup Sandbox</h1>
<h2>Slides</h2>
<table class="decks">
  <thead><tr><th>Deck</th><th>HTML</th><th>PDF</th><th>PPTX</th></tr></thead>
  <tbody>
HTML
  jq -r '.decks[] | "    <tr><td>\(.covers | gsub("&"; "&amp;") | gsub("<"; "&lt;"))</td><td><a href=\"\(.html)\">View</a></td><td><a href=\"\(.pdf)\">Download</a></td><td><a href=\"\(.pptx)\">Download</a></td></tr>"' index.json
  cat <<HTML
  </tbody>
</table>
HTML
  echo "<footer>built <time datetime=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\">$(date -u '+%Y-%m-%d %H:%M UTC')</time></footer>"
  echo '</html>'
} > index.html
