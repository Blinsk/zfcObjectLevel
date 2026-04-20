#!/usr/bin/env bash
# numbers.sh — Natural numbers, integers, and rationals built on zfc.sh
# Source this after zfc.sh: source numbers.sh

# ---------------------------------------------------------------------------
# Natural numbers: Von Neumann ordinals
# ---------------------------------------------------------------------------

nat()     { build_ordinal "$1"; }

nat_add() {
    local n m
    n=$(cardinality "$1" | tr -d ' ')
    m=$(cardinality "$2" | tr -d ' ')
    build_ordinal $(( n + m ))
}

nat_mul() {
    local n m
    n=$(cardinality "$1" | tr -d ' ')
    m=$(cardinality "$2" | tr -d ' ')
    build_ordinal $(( n * m ))
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

rat_eq() {
    # p/q = r/s  iff  p * s = r * q  (as integers)
    local pn pd rn rd
    pn=$(fst "$1") || return 1; pd=$(snd "$1") || return 1
    rn=$(fst "$2") || return 1; rd=$(snd "$2") || return 1
    local pd_n rd_n
    pd_n=$(cardinality "$pd" | tr -d ' ')
    rd_n=$(cardinality "$rd" | tr -d ' ')
    int_eq "$(int_mul "$pn" "$(int_pos "$rd_n")")" \
           "$(int_mul "$rn" "$(int_pos "$pd_n")")"
}

rat_show() {
    local num den
    num=$(int_show "$(fst "$1")")
    den=$(cardinality "$(snd "$1")" | tr -d ' ')
    echo "${num}/${den}"
}
