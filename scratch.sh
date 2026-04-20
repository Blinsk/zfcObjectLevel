#!/usr/bin/env bash
# Interactive helper for ZFC experimentation.
# Usage: source scratch.sh
#
# QUOTING RULE: set names with commas must be in variables or $().
#   good:  two=$(successor $(successor ∅)); show_pretty "$two"
#   bad:   show_pretty {∅,{∅}}   ← zsh will brace-expand this

source "$(dirname "${BASH_SOURCE[0]}")/zfc.sh"

mkdir -p "$U"
empty_set > /dev/null

# lsu — list the universe with element counts
lsu() {
    echo "universe/ ($(ls "$U" | wc -l | tr -d ' ') sets)"
    for f in "$U"/*; do
        local name="${f##*/}"
        local card
        card=$(wc -l < "$f" | tr -d ' ')
        printf "  %-40s  |%s|\n" "$name" "$card"
    done
}

# ord N — construct and show Von Neumann ordinal N
ord() {
    local n="$1"
    local cur="∅"
    local i
    for (( i=0; i<n; i++ )); do
        cur=$(successor "$cur")
    done
    echo "ordinal $n = $cur"
    show_pretty "$cur"
    echo
}

# sp SET — shorthand for show_pretty
sp() { show_pretty "$1"; echo; }

echo "ZFC scratch session ready."
echo "  lsu         — list universe"
echo "  ord N       — build and show ordinal N"
echo "  sp \"\$set\"   — pretty-print a set"
echo "  source scratch.sh to reload"
