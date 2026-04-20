#!/usr/bin/env bash
# ZFC Object Layer — source this file: source zfc.sh

U="universe"

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

canonicalize() {
    local s="$U/$1"
    sort -u "$s" -o "$s"
}

structural_name() {
    local tmp="$1"
    [[ -s "$tmp" ]] || { echo "∅"; return; }
    local name="{"
    local first=1
    while IFS= read -r e; do
        [[ $first -eq 0 ]] && name+=","
        name+="$e"
        first=0
    done < "$tmp"
    name+="}"
    echo "$name"
}

# commit_set: persist a tmp file to universe/ and return its canonical name.
# Empty files always map to ∅. Elements are sorted by length then lexicographic,
# so simpler (shorter-named) sets appear first — giving ordinals their natural order.
commit_set() {
    local tmp="$1"
    local stmp="${tmp}.s"
    # Sort: deduplicate, then order by name-length (shorter = simpler set first)
    sort -u "$tmp" | awk '{ print length" "$0 }' | sort -n -s | sed 's/^[0-9]* //' > "$stmp"
    mv "$stmp" "$tmp"
    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        touch "$U/∅"
        echo "∅"
        return
    fi
    local name
    name=$(structural_name "$tmp")
    if [[ ${#name} -gt 200 ]]; then
        echo "ERROR: set too large to handle (name would be ${#name} chars — use smaller sets)" >&2
        rm -f "$tmp"
        return 1
    fi
    if [[ ! -f "$U/$name" ]]; then
        mv "$tmp" "$U/$name"
    else
        rm -f "$tmp"
    fi
    echo "$name"
}

exists() { [[ -f "$U/$1" ]]; }

require() { exists "$1" || { echo "ERROR: set '$1' not in universe" >&2; return 1; }; }

# is_singleton A — true iff A has exactly one element (A ≠ ∅ and A \ {choose A} = ∅)
is_singleton() {
    require "$1" || return 1
    [[ -s "$U/$1" ]] || return 1
    local a rest
    a=$(choose "$1") || return 1
    rest=$(difference "$1" "$(singleton "$a")") || return 1
    [[ ! -s "$U/$rest" ]]
}

# ---------------------------------------------------------------------------
# Axiom 1 — Extensionality
# ---------------------------------------------------------------------------

eq() {
    require "$1" || return 1
    require "$2" || return 1
    diff <(sort "$U/$1") <(sort "$U/$2") > /dev/null
}

# ---------------------------------------------------------------------------
# Axiom 2 — Empty Set
# ---------------------------------------------------------------------------

empty_set() {
    touch "$U/∅"
    echo "∅"
}

# ---------------------------------------------------------------------------
# Axiom 3 — Pairing
# ---------------------------------------------------------------------------

pair() {
    require "$1" || return 1
    require "$2" || return 1
    local tmp
    tmp=$(mktemp)
    printf "%s\n%s\n" "$1" "$2" | sort -u > "$tmp"
    commit_set "$tmp"
}

singleton() {
    require "$1" || return 1
    local tmp
    tmp=$(mktemp)
    echo "$1" > "$tmp"
    commit_set "$tmp"
}

# ---------------------------------------------------------------------------
# Axiom 4 — Union
# ---------------------------------------------------------------------------

union() {
    require "$1" || return 1
    local tmp
    tmp=$(mktemp)
    while IFS= read -r member; do
        require "$member" || return 1
        cat "$U/$member" >> "$tmp"
    done < "$U/$1"
    commit_set "$tmp"
}

binary_union() {
    local fam
    fam=$(pair "$1" "$2") || return 1
    union "$fam"
}

# ---------------------------------------------------------------------------
# Axiom 5 — Power Set
# ---------------------------------------------------------------------------

power() {
    require "$1" || return 1
    # 𝒫(∅) = {∅}
    if [[ ! -s "$U/$1" ]]; then
        singleton "∅"
        return
    fi
    # 𝒫(A) = 𝒫(A') ∪ { B ∪ {a} : B ∈ 𝒫(A') }   where a = choose(A), A' = A \ {a}
    local a sa A_prime prev_power
    a=$(choose "$1") || return 1
    sa=$(singleton "$a") || return 1
    A_prime=$(difference "$1" "$sa") || return 1
    prev_power=$(power "$A_prime") || return 1
    local extended_tmp
    extended_tmp=$(mktemp)
    while IFS= read -r B; do
        local B_ext
        B_ext=$(binary_union "$B" "$sa") || return 1
        echo "$B_ext" >> "$extended_tmp"
    done < "$U/$prev_power"
    local extended
    extended=$(commit_set "$extended_tmp") || return 1
    binary_union "$prev_power" "$extended"
}

# ---------------------------------------------------------------------------
# Axiom 6 — Infinity
# ---------------------------------------------------------------------------

successor() {
    require "$1" || return 1
    local sn
    sn=$(singleton "$1") || return 1
    binary_union "$1" "$sn"
}

build_omega() {
    local n="${1:-10}"
    empty_set > /dev/null
    local prev="∅"
    local omega_tmp
    omega_tmp=$(mktemp)
    echo "∅" >> "$omega_tmp"
    local i cur
    for (( i=1; i<n; i++ )); do
        cur=$(successor "$prev") || return 1
        echo "$cur" >> "$omega_tmp"
        prev="$cur"
    done
    local name
    name=$(commit_set "$omega_tmp")
    cp "$U/$name" "$U/ω_$n"
    echo "ω_$n"
}

# ---------------------------------------------------------------------------
# Axiom 7 — Separation
# ---------------------------------------------------------------------------

sep() {
    require "$1" || return 1
    local tmp
    tmp=$(mktemp)
    grep -E "$2" "$U/$1" > "$tmp" || true
    commit_set "$tmp"
}

sep_fn() {
    require "$1" || return 1
    local pred="$2"
    local tmp
    tmp=$(mktemp)
    while IFS= read -r x; do
        if $pred "$x"; then
            echo "$x" >> "$tmp"
        fi
    done < "$U/$1"
    commit_set "$tmp"
}

# ---------------------------------------------------------------------------
# Axiom 8 — Replacement
# ---------------------------------------------------------------------------

replace() {
    require "$1" || return 1
    local func="$2"
    local tmp
    tmp=$(mktemp)
    while IFS= read -r x; do
        local y
        y=$($func "$x") || return 1
        echo "$y" >> "$tmp"
    done < "$U/$1"
    commit_set "$tmp"
}

sed_replace() {
    require "$1" || return 1
    local tmp
    tmp=$(mktemp)
    sed "$2" "$U/$1" > "$tmp"
    commit_set "$tmp"
}

# ---------------------------------------------------------------------------
# Axiom 9 — Regularity
# ---------------------------------------------------------------------------

is_regular() {
    require "$1" || return 1
    ! grep -qxF "$1" "$U/$1"
}

# ---------------------------------------------------------------------------
# Axiom 10 — Choice
# ---------------------------------------------------------------------------

choose() {
    require "$1" || return 1
    [[ -s "$U/$1" ]] || { echo "ERROR: cannot choose from empty set" >&2; return 1; }
    head -1 "$U/$1"
}

choice_fn() {
    require "$1" || return 1
    local tmp
    tmp=$(mktemp)
    while IFS= read -r A; do
        require "$A" || return 1
        choose "$A" >> "$tmp"
    done < "$U/$1"
    commit_set "$tmp"
}

# ---------------------------------------------------------------------------
# Derived operations
# ---------------------------------------------------------------------------

_in_set() {
    grep -qxF "$2" "$U/$1"
}

intersection() {
    require "$1" || return 1
    require "$2" || return 1
    local tmp
    tmp=$(mktemp)
    grep -xFf "$U/$2" "$U/$1" > "$tmp" || true
    commit_set "$tmp"
}

difference() {
    require "$1" || return 1
    require "$2" || return 1
    local tmp
    tmp=$(mktemp)
    grep -vxFf "$U/$2" "$U/$1" > "$tmp" || true
    commit_set "$tmp"
}

subset() {
    require "$1" || return 1
    require "$2" || return 1
    local diff
    diff=$(difference "$1" "$2") || return 1
    [[ ! -s "$U/$diff" ]]
}

member() {
    require "$2" || return 1
    grep -qxF "$1" "$U/$2"
}

cardinality() {
    require "$1" || return 1
    wc -l < "$U/$1"
}

# ---------------------------------------------------------------------------
# Ordered Pairs (Kuratowski): (a,b) = {{a},{a,b}}
# ---------------------------------------------------------------------------

opair() {
    require "$1" || return 1
    require "$2" || return 1
    local sa p
    sa=$(singleton "$1") || return 1
    p=$(pair "$1" "$2") || return 1
    pair "$sa" "$p"
}

# fst p — first component of a Kuratowski ordered pair
fst() {
    require "$1" || return 1
    if is_singleton "$1"; then
        # p = {{a}}: a = b case
        choose "$(choose "$1")"
    else
        # p = {{a},{a,b}}: find the singleton element {a}
        while IFS= read -r elem; do
            if is_singleton "$elem"; then
                choose "$elem"
                return
            fi
        done < "$U/$1"
        echo "ERROR: fst: not an ordered pair" >&2; return 1
    fi
}

# snd p — second component of a Kuratowski ordered pair
snd() {
    require "$1" || return 1
    if is_singleton "$1"; then
        # p = {{a}}: a = b, snd = fst
        fst "$1"
    else
        local a sa
        a=$(fst "$1") || return 1
        sa=$(singleton "$a") || return 1
        # find the non-singleton element {a,b}, remove a, choose b
        while IFS= read -r elem; do
            if ! is_singleton "$elem"; then
                local rest
                rest=$(difference "$elem" "$sa") || return 1
                choose "$rest"
                return
            fi
        done < "$U/$1"
        echo "ERROR: snd: not an ordered pair" >&2; return 1
    fi
}

# is_opair p — true if p looks like a Kuratowski ordered pair
is_opair() {
    require "$1" || return 1
    [[ -s "$U/$1" ]] || return 1
    while IFS= read -r elem; do
        exists "$elem" || return 1
        is_singleton "$elem" && return 0
    done < "$U/$1"
    return 1
}

# ---------------------------------------------------------------------------
# Cartesian Product: A × B = {(a,b) : a ∈ A, b ∈ B}
# ---------------------------------------------------------------------------

cartesian() {
    require "$1" || return 1
    require "$2" || return 1
    local B="$2"
    local tmp
    tmp=$(mktemp)
    while IFS= read -r a; do
        while IFS= read -r b; do
            local p
            p=$(opair "$a" "$b") || return 1
            echo "$p" >> "$tmp"
        done < "$U/$B"
    done < "$U/$1"
    commit_set "$tmp"
}

# ---------------------------------------------------------------------------
# Relations (sets of ordered pairs)
# ---------------------------------------------------------------------------

# dom R — domain: {a : ∃b, (a,b) ∈ R}
dom() {
    require "$1" || return 1
    local tmp
    tmp=$(mktemp)
    while IFS= read -r p; do
        fst "$p" >> "$tmp" || return 1
    done < "$U/$1"
    commit_set "$tmp"
}

# ran R — range: {b : ∃a, (a,b) ∈ R}
ran() {
    require "$1" || return 1
    local tmp
    tmp=$(mktemp)
    while IFS= read -r p; do
        snd "$p" >> "$tmp" || return 1
    done < "$U/$1"
    commit_set "$tmp"
}

# rel_apply R a — relational image of a under R: {b : (a,b) ∈ R}
rel_apply() {
    require "$1" || return 1
    require "$2" || return 1
    local R="$1" a="$2"
    local tmp
    tmp=$(mktemp)
    while IFS= read -r p; do
        local first
        first=$(fst "$p") || return 1
        if [[ "$first" == "$a" ]]; then
            snd "$p" >> "$tmp" || return 1
        fi
    done < "$U/$R"
    commit_set "$tmp"
}

# is_function R A B — true if R is a function from A to B
# (total, single-valued relation whose domain = A and range ⊆ B)
is_function() {
    require "$1" || return 1; require "$2" || return 1; require "$3" || return 1
    local R="$1" A="$2" B="$3"
    local d r
    d=$(dom "$R") || return 1
    eq "$d" "$A" || return 1
    r=$(ran "$R") || return 1
    subset "$r" "$B" || return 1
    while IFS= read -r a; do
        local img
        img=$(rel_apply "$R" "$a") || return 1
        is_singleton "$img" || return 1
    done < "$U/$A"
}

# ---------------------------------------------------------------------------
# Undecidability guard
# ---------------------------------------------------------------------------

# halts PROGRAM INPUT — you cannot decide this
halts() {
    echo "ERROR: Machine will get stuck! (Halting Problem — undecidable)" >&2
    return 1
}

# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

show() {
    local name="$1" depth="${2:-2}" indent="${3:-}"
    require "$name" || return 1
    if [[ ! -s "$U/$name" ]]; then
        echo "${indent}${name} = ∅"
        return
    fi
    echo "${indent}${name} = {"
    while IFS= read -r elem; do
        if [[ $depth -gt 0 ]] && exists "$elem"; then
            show "$elem" $(( depth - 1 )) "${indent}  "
        else
            echo "${indent}  ${elem}"
        fi
    done < "$U/$name"
    echo "${indent}}"
}

# build_ordinal n — construct Von Neumann ordinal n (successor applied n times to ∅)
build_ordinal() {
    local n="$1"
    local cur="∅"
    local i
    for (( i=0; i<n; i++ )); do
        cur=$(successor "$cur")
    done
    echo "$cur"
}

# is_ordinal A — true if A is a Von Neumann ordinal
is_ordinal() {
    require "$1" || return 1
    local n
    n=$(cardinality "$1" | tr -d ' ')
    local ord
    ord=$(build_ordinal "$n")
    eq "$1" "$ord"
}

# show_pretty — display any set purely as nested { } notation, no hash names.
show_pretty() {
    local name="$1" depth="${2:-4}" indent="${3:-}"
    require "$name" || return 1

    if [[ ! -s "$U/$name" ]]; then
        echo -n "${indent}∅"
        return
    fi

    if [[ $depth -le 0 ]]; then
        echo -n "${indent}{...}"
        return
    fi

    local elements=()
    while IFS= read -r elem; do
        elements+=("$elem")
    done < "$U/$name"

    if [[ ${#elements[@]} -eq 1 ]]; then
        echo -n "${indent}{ "
        show_pretty "${elements[0]}" $(( depth - 1 )) ""
        echo -n " }"
    else
        echo "${indent}{"
        for elem in "${elements[@]}"; do
            show_pretty "$elem" $(( depth - 1 )) "${indent}  "
            echo
        done
        echo -n "${indent}}"
    fi
}
