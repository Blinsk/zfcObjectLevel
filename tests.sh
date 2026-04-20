#!/usr/bin/env bash
# Regression tests for zfc.sh

cd "$(dirname "$0")"
source zfc.sh

PASS=0
FAIL=0

assert_true() {
    local desc="$1"; shift
    if "$@" 2>/dev/null; then
        echo "PASS: $desc"
        (( PASS++ ))
    else
        echo "FAIL: $desc"
        (( FAIL++ ))
    fi
}

assert_false() {
    local desc="$1"; shift
    if ! "$@" 2>/dev/null; then
        echo "PASS: $desc"
        (( PASS++ ))
    else
        echo "FAIL: $desc"
        (( FAIL++ ))
    fi
}

assert_eq_sets() {
    local desc="$1" A="$2" B="$3"
    if eq "$A" "$B" 2>/dev/null; then
        echo "PASS: $desc"
        (( PASS++ ))
    else
        echo "FAIL: $desc  (got $A vs $B)"
        (( FAIL++ ))
    fi
}

assert_card() {
    local desc="$1" A="$2" expected="$3"
    local got
    got=$(cardinality "$A" 2>/dev/null | tr -d ' ')
    if [[ "$got" == "$expected" ]]; then
        echo "PASS: $desc"
        (( PASS++ ))
    else
        echo "FAIL: $desc  (expected $expected, got $got)"
        (( FAIL++ ))
    fi
}

# Setup
rm -rf universe
mkdir -p universe
empty_set > /dev/null

# 1. eq ∅ ∅
assert_true  "eq ∅ ∅" eq "∅" "∅"

# 2. pair ∅ ∅ equals singleton ∅
p=$(pair "∅" "∅")
s=$(singleton "∅")
assert_eq_sets "pair ∅ ∅ = singleton ∅" "$p" "$s"

# 3. union of { {∅}, {∅, A} } gives {∅, A}
A=$(singleton "∅")          # A = {∅}
B=$(pair "∅" "$A")          # B = {∅, {∅}}
fam=$(pair "$A" "$B")       # fam = { {∅}, {∅,{∅}} }
u=$(union "$fam")
expected=$(pair "∅" "$A")
assert_eq_sets "union {{∅},{∅,A}} = {∅,A}" "$u" "$expected"

# 4. power ∅ gives {∅}  (one element)
p0=$(power "∅")
assert_card "power ∅ has 1 element" "$p0" "1"
assert_true "power ∅ contains ∅" member "∅" "$p0"

# 5. power of singleton has 2 elements
s1=$(singleton "∅")
ps=$(power "$s1")
assert_card "power {∅} has 2 elements" "$ps" "2"

# 6. sep with non-matching pattern gives ∅
nomatch=$(sep "$s1" "NOMATCH_XYZ")
assert_true "sep non-matching = ∅" eq "$nomatch" "∅"

# 7. successor ∅ = singleton ∅
succ0=$(successor "∅")
sin0=$(singleton "∅")
assert_eq_sets "successor ∅ = {∅}" "$succ0" "$sin0"

# 8. successor {∅} = pair ∅ {∅}
succ1=$(successor "$sin0")
expected2=$(pair "∅" "$sin0")
assert_eq_sets "successor {∅} = {∅,{∅}}" "$succ1" "$expected2"

# 9. intersection A B ⊆ A and ⊆ B
C=$(pair "∅" "$sin0")        # C = {∅, {∅}}
D=$(singleton "$sin0")       # D = {{∅}}
inter=$(intersection "$C" "$D")
assert_true  "intersection C D ⊆ C" subset "$inter" "$C"
assert_true  "intersection C D ⊆ D" subset "$inter" "$D"

# 10. difference A B ∩ B = ∅
diff=$(difference "$C" "$D")
inter2=$(intersection "$diff" "$D")
assert_true "difference C D disjoint from D" eq "$inter2" "∅"

# 11. member
assert_true  "member ∅ {∅}" member "∅" "$sin0"
assert_false "member {∅} ∅" member "$sin0" "∅"

# 12. is_regular ∅
assert_true "∅ is regular" is_regular "∅"

# 13. build_omega gives ordinals
omega=$(build_omega 5)
assert_card "ω_5 has 5 ordinals" "$omega" "5"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
