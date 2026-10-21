#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/setup-sandbox
# Copyright (c) 2026 infraguide.org, MIT License
#
# Builds the decks in the requested formats into the output directory of .marprc.yml
# and copies assets/ next to them, so the pictures also load in the built html.
# The decks are built from a copy of the sources in which plantuml-embed.py turns the
# plantuml code blocks into images of a PlantUML server, so the diagrams render as well.
# Usage: build.sh [src-dir] [format...]   (default: src-dir = slides/src, html only)
# Set MARP to pick the Marp CLI command, e.g. MARP="npx --yes @marp-team/marp-cli@4",
# and PLANTUML_SERVER to render the diagrams on another PlantUML server.
# Set DEBUG to keep the sources the decks are built from, to look at the embedded diagrams;
# the script then also tells how to remove them again.
set -euo pipefail

scripts=$(dirname "$(realpath "$0")")
src=$(realpath "${1:-$scripts/../src}")
shift || true
formats=("$@")
[ ${#formats[@]} -eq 0 ] && formats=(html)   # pdf and pptx are slow, so ask for them

if [ -z "${MARP:-}" ]; then
  MARP=$(command -v marp >/dev/null && echo marp || echo "npx --yes @marp-team/marp-cli@4")
fi

out=$(cd "$src" && realpath -m "$(sed -n 's/^output: *//p' .marprc.yml | head -1 | sed 's/^"//; s/"$//')")

# The sources stay untouched, so the diagram urls only ever live in the built decks.
work=$(mktemp -d "${TMPDIR:-/tmp}/slides-build-XXXXXXXX")
if [ -n "${DEBUG:-}" ]; then
  trap 'echo "build.sh: the build sources stay in $work, remove them with: rm -rf $work" >&2' EXIT
else
  trap 'rm -rf "$work"' EXIT
fi
cp -r "$src"/. "$work/"
sed -i "s|^output:.*|output: \"$out\"|" "$work/.marprc.yml"   # inputDir stays the copy

if command -v python3 >/dev/null; then
  python3 "$scripts/plantuml-embed.py" "${PLANTUML_SERVER:-https://www.plantuml.com/plantuml}" "$work"/*.md
else
  echo "build.sh: no python3, the plantuml blocks stay code blocks" >&2
fi

cd "$work"
for format in "${formats[@]}"; do
  case $format in
    html) $MARP ;;
    *) $MARP "--$format" ;;
  esac
done

# The html keeps the image paths relative to itself, so assets/ has to sit in $out too.
mkdir -p "$out"
if [ -d "$src/assets" ]; then
  cp -r "$src/assets" "$out/"
fi
