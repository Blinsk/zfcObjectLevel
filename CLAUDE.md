# CLAUDE.md — ZFC Object Layer in Bash

## Concept

Sets are files. Elements are lines. Every ZFC construction axiom is a bash
function that reads files and produces files. We work directly in the model —
no formal language, no proof terms, just objects.

The universe lives in a single directory: `universe/`. All set-files live
there. Functions operate on filenames (strings naming files in `universe/`).

---

## Representation

```
universe/
    ∅               # empty file — the empty set
    ω               # the first infinite ordinal (lines: ∅, 1, 2, 3, ...)
    ...             # all constructed sets live here
```

**An element is a line.** Each line in a set-file is the *name* of another
set-file in `universe/`. So every element is itself a set (as ZFC requires).

```
universe/A:
    ∅
    B
    C
```
means A = { ∅, B, C }, where B and C are also files in `universe/`.

**Extensionality:** two sets are equal iff their files have the same lines
(after sorting). Never compare by filename — only by content. The canonical
form of every file is sorted, deduplicated lines (`sort -u`).

**Naming convention:** constructed sets get auto-generated names when no
natural name exists. Use a content hash: `sha256sum` truncated to 8 chars.
This makes equal sets automatically get the same name.

---

## File: `zfc.sh`

Source this file to get all functions: `source zfc.sh`

### Utilities

```bash
U="universe"   # global universe directory

# Canonical form: sort and dedup a set-file in place
canonicalize() {
    local s="$U/$1"
    sort -u "$s" -o "$s"
}

# Content-addressed name: sha256 of sorted content, 8 chars
set_name() {
    # $1 is a temp file path; return a canonical name
    local hash
    hash=$(sort -u "$1" | sha256sum | cut -c1-8)
    echo "$hash"
}

# Check if a set (file) exists in the universe
exists() { [[ -f "$U/$1" ]]; }

# Assert existence or abort
require() { exists "$1" || { echo "ERROR: set '$1' not in universe" >&2; exit 1; }; }
```

### Axiom 1 — Extensionality (predicate, not construction)

```bash
# eq A B — are A and B the same set?
# True iff their sorted contents are identical.
eq() {
    require "$1"; require "$2"
    diff <(sort "$U/$1") <(sort "$U/$2") > /dev/null
}
```

### Axiom 2 — Empty Set

```bash
# empty_set — ensure ∅ exists; return its name
empty_set() {
    touch "$U/∅"
    echo "∅"
}
```

### Axiom 3 — Pairing

```bash
# pair A B — return name of { A, B }
pair() {
    require "$1"; require "$2"
    local tmp
    tmp=$(mktemp)
    printf "%s\n%s\n" "$1" "$2" | sort -u > "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}

# singleton A — return name of { A }
singleton() {
    require "$1"
    local tmp
    tmp=$(mktemp)
    echo "$1" > "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}
```

### Axiom 4 — Union

```bash
# union F — big union of a family of sets
# F is a set-of-sets (file whose lines are set names)
# returns name of ⋃F
union() {
    require "$1"
    local tmp
    tmp=$(mktemp)
    while IFS= read -r member; do
        require "$member"
        cat "$U/$member" >> "$tmp"
    done < "$U/$1"
    sort -u "$tmp" -o "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}

# binary_union A B — return A ∪ B
binary_union() {
    local fam
    fam=$(pair "$1" "$2")
    union "$fam"
}
```

### Axiom 5 — Power Set

```bash
# power A — return name of 𝒫(A)
# Elements of A must be listed; generates all subsets.
# WARNING: exponential in |A|. Use only on small sets (|A| ≤ 8).
power() {
    require "$1"
    local elements
    mapfile -t elements < "$U/$1"
    local n=${#elements[@]}
    local pow_tmp
    pow_tmp=$(mktemp)

    # Each integer i from 0 to 2^n-1 represents a subset via bitmask
    local i bit subset_tmp subset_name
    for (( i=0; i < (1 << n); i++ )); do
        subset_tmp=$(mktemp)
        for (( bit=0; bit < n; bit++ )); do
            if (( (i >> bit) & 1 )); then
                echo "${elements[$bit]}" >> "$subset_tmp"
            fi
        done
        sort -u "$subset_tmp" -o "$subset_tmp"
        subset_name=$(set_name "$subset_tmp")
        mv "$subset_tmp" "$U/$subset_name"
        echo "$subset_name" >> "$pow_tmp"
    done

    sort -u "$pow_tmp" -o "$pow_tmp"
    local name
    name=$(set_name "$pow_tmp")
    mv "$pow_tmp" "$U/$name"
    echo "$name"
}
```

### Axiom 6 — Infinity

```bash
# Build ω = { ∅, {∅}, {∅,{∅}}, ... } up to n steps
# Von Neumann ordinals: 0=∅, n+1 = n ∪ {n}
successor() {
    # successor of ordinal n: n ∪ {n}
    require "$1"
    local sn
    sn=$(singleton "$1")
    binary_union "$1" "$sn"
}

build_omega() {
    local n="${1:-10}"   # build first n ordinals
    empty_set > /dev/null
    local prev="∅"
    local omega_tmp
    omega_tmp=$(mktemp)
    echo "∅" >> "$omega_tmp"
    local i cur
    for (( i=1; i<n; i++ )); do
        cur=$(successor "$prev")
        echo "$cur" >> "$omega_tmp"
        prev="$cur"
    done
    sort -u "$omega_tmp" -o "$omega_tmp"
    local name
    name=$(set_name "$omega_tmp")
    mv "$omega_tmp" "$U/$name"
    # Also store under friendly name
    cp "$U/$name" "$U/ω_$n"
    echo "ω_$n"
}
```

### Axiom 7 — Separation (this is `grep`)

```bash
# sep A pattern — { x ∈ A : x matches pattern }
# pattern is a grep extended regex applied to element names
# This IS Separation: grep is the predicate φ(x)
sep() {
    require "$1"
    local tmp
    tmp=$(mktemp)
    grep -E "$2" "$U/$1" > "$tmp" || true
    sort -u "$tmp" -o "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}

# sep_fn A func — { x ∈ A : func x returns 0 (true) }
# For predicates that need to inspect set content, not just names
sep_fn() {
    require "$1"
    local pred="$2"
    local tmp
    tmp=$(mktemp)
    while IFS= read -r x; do
        if $pred "$x"; then
            echo "$x" >> "$tmp"
        fi
    done < "$U/$1"
    sort -u "$tmp" -o "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}
```

### Axiom 8 — Replacement (this is `sed` / mapped function)

```bash
# replace A func — { func(x) : x ∈ A }
# func is a bash function: takes a set name, returns a set name
# This IS Replacement: func is the functional formula φ(x,y)
replace() {
    require "$1"
    local func="$2"
    local tmp
    tmp=$(mktemp)
    while IFS= read -r x; do
        local y
        y=$($func "$x")
        echo "$y" >> "$tmp"
    done < "$U/$1"
    sort -u "$tmp" -o "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}

# sed_replace A sed_expr — apply sed expression to each element name
# e.g. rename elements matching a pattern
# Weaker than replace but fast for name-level transformations
sed_replace() {
    require "$1"
    local tmp
    tmp=$(mktemp)
    sed "$2" "$U/$1" > "$tmp"
    sort -u "$tmp" -o "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}
```

### Axiom 9 — Regularity (guard, not construction)

```bash
# is_regular A — check A does not contain itself (no x ∈ A with x = A)
# Full regularity (no ∈-cycles) would require a reachability check;
# this checks the immediate case.
is_regular() {
    require "$1"
    ! grep -qxF "$1" "$U/$1"
}
```

### Axiom 10 — Choice

```bash
# choose A — pick one element from a non-empty set
# Uses head -1 (deterministic on sorted files)
choose() {
    require "$1"
    [[ -s "$U/$1" ]] || { echo "ERROR: cannot choose from empty set" >&2; return 1; }
    head -1 "$U/$1"
}

# choice_fn F — given a family F of non-empty sets,
# return a set C containing exactly one element from each member
choice_fn() {
    require "$1"
    local tmp
    tmp=$(mktemp)
    while IFS= read -r A; do
        require "$A"
        choose "$A" >> "$tmp"
    done < "$U/$1"
    sort -u "$tmp" -o "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}
```

### Derived operations

```bash
# intersection A B — A ∩ B  (Separation on A with predicate "x ∈ B")
intersection() {
    require "$1"; require "$2"
    local b="$2"
    sep_fn "$1" "$(declare -f _in_set); _in_set '$b'"
    # helper: _in_set B x — is x an element of B?
}

_in_set() {
    grep -qxF "$2" "$U/$1"
}

intersection() {
    require "$1"; require "$2"
    local A="$1" B="$2"
    local tmp
    tmp=$(mktemp)
    grep -xFf "$U/$B" "$U/$A" > "$tmp" || true
    sort -u "$tmp" -o "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}

# difference A B — A \ B
difference() {
    require "$1"; require "$2"
    local tmp
    tmp=$(mktemp)
    grep -vxFf "$U/$2" "$U/$1" > "$tmp" || true
    sort -u "$tmp" -o "$tmp"
    local name
    name=$(set_name "$tmp")
    mv "$tmp" "$U/$name"
    echo "$name"
}

# subset A B — is A ⊆ B?
subset() {
    require "$1"; require "$2"
    # A ⊆ B iff A \ B = ∅
    local diff
    diff=$(difference "$1" "$2")
    [[ ! -s "$U/$diff" ]]
}

# member x A — is x ∈ A?
member() {
    require "$2"
    grep -qxF "$1" "$U/$2"
}

# cardinality A — number of elements (lines)
cardinality() {
    require "$1"
    wc -l < "$U/$1"
}
```

### Display

```bash
# show A — print set contents, recursively up to depth d
show() {
    local name="$1" depth="${2:-2}" indent="${3:-}"
    require "$name"
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
```

---

## Directory layout

```
sets/
    universe/       # all set-files live here
    zfc.sh          # source this
    examples.sh     # worked examples
    tests.sh        # regression tests
    scratch.sh      # your experiments
```

---

## Implementation notes for Claude Code

- **Create `universe/` and `touch universe/∅` first.** ∅ must always exist.
- **All functions are pure** in the sense that they only append to `universe/`
  — they never delete or modify existing files. Sets are immutable once written.
- **Content-addressing** means equal sets automatically converge to the same
  file. The name is the hash of the content. Friendly aliases (like `∅`, `ω`)
  are symlinks or copies stored alongside.
- **`grep -xF`** matches whole lines, fixed strings — use this for membership
  tests to avoid regex false positives on set names containing special chars.
- **`sep` with a grep pattern** is exact Separation for predicates on names.
  **`sep_fn`** handles predicates that need to inspect set *content* (e.g.
  "all elements of A that are non-empty sets").
- **`replace` with a bash function** is exact Replacement. The function must
  be a total map on set names — it receives a name, returns a name.
- **`sed_replace`** is a fast but weaker variant: it transforms the *names*
  of elements via sed. Useful for ordinal arithmetic where names encode values.
- **Regularity** is a postcondition check, not a construction. The construction
  functions cannot produce ∈-cycles given the axioms, but `is_regular` is
  there for assertions in tests.
- **Tests in `tests.sh`** should cover:
  - `eq ∅ ∅` is true
  - `pair ∅ ∅` equals `singleton ∅`
  - `union` of `{ {∅}, {∅,A} }` gives `{∅, A}`
  - `power ∅` gives `{∅}` (one element: the empty set)
  - `power (pair ∅ ∅)` — power set of a singleton has 2 elements
  - `sep` with a pattern that matches nothing gives ∅
  - `successor ∅` equals `singleton ∅`
  - `successor (singleton ∅)` equals `pair ∅ (singleton ∅)`

## Example session

```bash
source zfc.sh
mkdir -p universe
empty_set                          # creates ∅

a=$(singleton ∅)                   # a = {∅}
b=$(pair ∅ "$a")                   # b = {∅, {∅}}  = ordinal 2
show "$b"

c=$(power "$a")                    # c = 𝒫({∅}) = {∅, {∅}}
eq "$b" "$c" && echo "equal"       # should print "equal"

omega=$(build_omega 6)
show "$omega" 1                    # first 6 von Neumann ordinals
```
