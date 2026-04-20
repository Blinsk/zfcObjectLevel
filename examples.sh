#!/usr/bin/env bash
# Worked examples — source zfc.sh first or run: bash examples.sh

cd "$(dirname "$0")"
source zfc.sh

rm -rf universe
mkdir -p universe

echo "=== Setup ==="
empty_set
echo "∅ created"

echo ""
echo "=== Pairing and singletons ==="
a=$(singleton ∅)
echo "a = {∅}  →  $a"

b=$(pair ∅ "$a")
echo "b = {∅, {∅}} = ordinal 2  →  $b"

show "$b"

echo ""
echo "=== Power set ==="
c=$(power "$a")
echo "c = 𝒫({∅}) = {∅, {∅}}  →  $c"
eq "$b" "$c" && echo "b = c  ✓ (extensionality)"

echo ""
echo "=== Von Neumann ordinals (ω up to 6) ==="
omega=$(build_omega 6)
echo "ω_6 = $omega"
show "$omega" 1

echo ""
echo "=== Separation ==="
# All ordinals in ω_6 that are not ∅
nonempty=$(sep_fn "$omega" '_nonempty')
_nonempty() { [[ -s "$U/$1" ]]; }
nonempty=$(sep_fn "$omega" '_nonempty')
echo "Non-empty ordinals in ω_6: $(cardinality "$nonempty") elements"

echo ""
echo "=== Replacement ==="
# Map every ordinal n ↦ {n}  (successor step: singleton)
singletons=$(replace "$omega" singleton)
echo "Image of singleton over ω_6: $(cardinality "$singletons") elements"

echo ""
echo "=== Choice ==="
chosen=$(choose "$omega")
echo "choose(ω_6) = $chosen"
