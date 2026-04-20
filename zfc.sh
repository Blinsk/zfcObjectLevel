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

set_name() {
    local hash
    hash=$(sort -u "$1" | sha256sum | cut -c1-8)
    echo "$hash"
}

# commit_set: persist a tmp file to universe/ and return its canonical name.
# Empty files always map to the named ∅.
commit_set() {
    local tmp="$1"
    sort -u "$tmp" -o "$tmp"
    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        touch "$U/∅"
        echo "∅"
        return
    fi
    local name
    name=$(set_name "$tmp")
    if [[ ! -f "$U/$name" ]]; then
        mv "$tmp" "$U/$name"
    else
        rm -f "$tmp"
    fi
    echo "$name"
}

exists() { [[ -f "$U/$1" ]]; }

require() { exists "$1" || { echo "ERROR: set '$1' not in universe" >&2; return 1; }; }

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
    local elements=()
    while IFS= read -r line; do
        elements+=("$line")
    done < "$U/$1"
    local n=${#elements[@]}
    local pow_tmp
    pow_tmp=$(mktemp)

    local i bit subset_tmp subset_name
    for (( i=0; i < (1 << n); i++ )); do
        subset_tmp=$(mktemp)
        for (( bit=0; bit < n; bit++ )); do
            if (( (i >> bit) & 1 )); then
                echo "${elements[$bit]}" >> "$subset_tmp"
            fi
        done
        subset_name=$(commit_set "$subset_tmp")
        echo "$subset_name" >> "$pow_tmp"
    done

    commit_set "$pow_tmp"
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
