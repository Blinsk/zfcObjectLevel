#!/usr/bin/env bash
# numbers.sh — Natural numbers, integers, and rationals built on zfc.sh
# Source this after zfc.sh: source numbers.sh

# ---------------------------------------------------------------------------
# Natural numbers: Von Neumann ordinals
# ---------------------------------------------------------------------------

nat()     { build_ordinal "$1"; }

# pred_ord α — the predecessor of a non-zero Von Neumann ordinal.
# Elements are sorted by length (shorter = smaller ordinal), so the last
# line of the file is always the largest element, i.e. α − 1.
pred_ord() {
    [[ -s "$U/$1" ]] || { echo "ERROR: ∅ has no predecessor" >&2; return 1; }
    tail -1 "$U/$1"
}

# α + 0     = α
# α + S(β)  = S(α + β)
nat_add() {
    require "$1" || return 1
    require "$2" || return 1
    [[ ! -s "$U/$2" ]] && echo "$1" && return
    local pred sum
    pred=$(pred_ord "$2") || return 1
    sum=$(nat_add "$1" "$pred") || return 1
    successor "$sum"
}

# α × 0     = ∅
# α × S(β)  = (α × β) + α
nat_mul() {
    require "$1" || return 1
    require "$2" || return 1
    [[ ! -s "$U/$2" ]] && echo "∅" && return
    local pred prod
    pred=$(pred_ord "$2") || return 1
    prod=$(nat_mul "$1" "$pred") || return 1
    nat_add "$prod" "$1"
}

nat_show() { cardinality "$1" | tr -d ' '; }

# ---------------------------------------------------------------------------
# Integers: opair(pos_part, neg_part) where value = |pos| - |neg|
# ---------------------------------------------------------------------------

int_pos()  { opair "$(nat "$1")" "∅"; }
int_neg()  { opair "∅" "$(nat "$1")"; }
int_zero() { opair "∅" "∅"; }

int_add() {
    local pa na pb nb
    pa=$(fst "$1") || return 1; na=$(snd "$1") || return 1
    pb=$(fst "$2") || return 1; nb=$(snd "$2") || return 1
    opair "$(nat_add "$pa" "$pb")" "$(nat_add "$na" "$nb")"
}

int_negate() { opair "$(snd "$1")" "$(fst "$1")"; }

int_sub() { int_add "$1" "$(int_negate "$2")"; }

int_mul() {
    local a b c d
    a=$(fst "$1") || return 1; b=$(snd "$1") || return 1
    c=$(fst "$2") || return 1; d=$(snd "$2") || return 1
    opair "$(nat_add "$(nat_mul "$a" "$c")" "$(nat_mul "$b" "$d")")" \
          "$(nat_add "$(nat_mul "$a" "$d")" "$(nat_mul "$b" "$c")")"
}

int_eq() {
    local pa na pb nb
    pa=$(fst "$1") || return 1; na=$(snd "$1") || return 1
    pb=$(fst "$2") || return 1; nb=$(snd "$2") || return 1
    eq "$(nat_add "$pa" "$nb")" "$(nat_add "$pb" "$na")"
}

int_show() {
    local p n
    p=$(cardinality "$(fst "$1")" | tr -d ' ')
    n=$(cardinality "$(snd "$1")" | tr -d ' ')
    echo $(( p - n ))
}

# ---------------------------------------------------------------------------
# Rational numbers: opair(integer_numerator, natural_denominator > 0)
# ---------------------------------------------------------------------------

rat_make() { opair "$1" "$2"; }   # $1 = integer, $2 = natural > 0

# nat_to_int n — embed a natural number (ordinal) into the integers as opair(n, ∅)
nat_to_int() { opair "$1" "∅"; }

rat_eq() {
    # p/q = r/s  iff  p * s = r * q  (as integers, denominators lifted via nat_to_int)
    local pn pd rn rd
    pn=$(fst "$1") || return 1; pd=$(snd "$1") || return 1
    rn=$(fst "$2") || return 1; rd=$(snd "$2") || return 1
    int_eq "$(int_mul "$pn" "$(nat_to_int "$rd")")" \
           "$(int_mul "$rn" "$(nat_to_int "$pd")")"
}

rat_show() {
    local num den
    num=$(int_show "$(fst "$1")")
    den=$(cardinality "$(snd "$1")" | tr -d ' ')
    echo "${num}/${den}"
}
