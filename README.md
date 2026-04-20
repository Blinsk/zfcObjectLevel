# ZFC Object Layer — Field Manual

> Sets are files. Elements are lines. The universe is a directory.
> Every object in this manual exists on disk.
> Every operation is defined set-theoretically — no arithmetic shortcuts.

---

## Setup

```bash
git clone <this-repo> && cd zfcObjectLevel
mkdir -p universe
source zfc.sh
source numbers.sh
empty_set          # seeds universe/∅
```

From here on, every name printed by a function is a filename in `universe/`.
You can inspect, `ls`, `grep`, and `cat` any of them directly.

---

## Part I — Natural Numbers

The Von Neumann construction defines each natural number as the set of all smaller natural numbers:

```
0 = ∅
1 = {0}      = {∅}
2 = {0,1}    = {∅, {∅}}
3 = {0,1,2}  = {∅, {∅}, {∅,{∅}}}
```

The genius: *n = |n|*. A natural number IS its own cardinality.

```bash
zero=$(nat 0)   #  ∅
one=$(nat 1)    #  {∅}
two=$(nat 2)    #  {∅,{∅}}
three=$(nat 3)  #  {∅,{∅},{∅,{∅}}}

echo "$zero $one $two $three"
# ∅  {∅}  {∅,{∅}}  {∅,{∅},{∅,{∅}}}
```

```bash
ls universe/
# ∅  {∅}  {∅,{∅}}  {∅,{∅},{∅,{∅}}}
```

Every ordinal is visibly a set on disk.

### Successor

`successor n` = n ∪ {n} — append n itself as a new element:

```bash
four=$(successor "$three")
echo "$four"
# {∅,{∅},{∅,{∅}},{∅,{∅},{∅,{∅}}}}
```

Notice the name length doubles each step:

| n | `nat n` | chars |
|---|---------|-------|
| 0 | `∅` | 1 |
| 1 | `{∅}` | 3 |
| 2 | `{∅,{∅}}` | 7 |
| 3 | `{∅,{∅},{∅,{∅}}}` | 15 |
| 4 | … | 31 |
| 5 | … | 63 |
| 6 | … | 127 |
| **7** | **— too large —** | **> 200** |

### Arithmetic

`nat_add` and `nat_mul` follow the recursive set-theoretic definitions:

```
α + 0     = α
α + S(β)  = S(α + β)

α × 0     = ∅
α × S(β)  = (α × β) + α
```

The predecessor `S(β) → β` is the last line of the file — our sort order (by name length) puts larger ordinals last, so `tail -1` of an ordinal file is always its immediate predecessor.

```bash
five=$(nat_add "$two" "$three")
echo "2 + 3 = $(nat_show "$five")"   # 2 + 3 = 5

echo "2 × 3 = $(nat_show "$(nat_mul "$two" "$three")")"  # 2 × 3 = 6
```

### Power sets and membership

`power` uses the set-theoretic recursion — no bitmask arithmetic:

```
𝒫(∅) = {∅}
𝒫(A) = 𝒫(A') ∪ { B ∪ {a} : B ∈ 𝒫(A') }    where a = choose(A),  A' = A \ {a}
```

The power set of `n` has 2ⁿ elements — all subsets of n:

```bash
p=$(power "$two")                    # 𝒫({∅,{∅}})
echo "𝒫(2) has $(cardinality "$p") elements"  # 4 = 2²

grep -l "{∅}" universe/*             # every set containing ordinal 1
```

### Exploring the universe

```bash
ls universe/                          # all constructed sets, named by structure
cat "universe/{∅,{∅}}"               # shows: ∅  and  {∅}  — the two elements of 2
grep -c "" universe/*                 # cardinality of each set
```

---

## Part II — Integers

Natural numbers only go forward. Subtraction can take us below zero. The standard ZFC fix: represent an integer as a **pair of naturals** (positive part, negative part), where the value is their difference.

```
integer z  =  opair(pos, neg)   where  z = |pos| − |neg|
```

```
+3  =  (3, 0)  =  opair(ordinal_3, ∅)
−2  =  (0, 2)  =  opair(∅, ordinal_2)
 0  =  (0, 0)  =  opair(∅, ∅)
```

The representation is not unique: `(5, 2)` and `(3, 0)` both represent `+3`. Equality requires checking that `pos_a + neg_b = pos_b + neg_a`.

```bash
plus_three=$(int_pos 3)
minus_two=$(int_neg 2)

echo "+3 as a set: $plus_three"
echo "−2 as a set: $minus_two"
```

What does `+3` look like inside? It's the Kuratowski pair `(ordinal_3, ∅)`:

```bash
show_pretty "$plus_three"
# {
#   { {∅,{∅},{∅,{∅}}} }          ← {ordinal_3}  — the singleton
#   {
#     {∅,{∅},{∅,{∅}}}            ← ordinal_3
#     ∅                           ← ∅
#   }
# }
```

### Set structure

`fst` and `snd` identify the singleton element of a Kuratowski pair using `is_singleton` — a purely set-theoretic test (`A ≠ ∅ ∧ A \ {choose A} = ∅`), with no element counting.

### Arithmetic on integers

```bash
result=$(int_add "$minus_two" "$plus_three")
int_eq "$result" "$(int_pos 1)" && echo "−2 + 3 = +1  ✓"

echo "value: $(int_show "$result")"   # 1
```

```bash
product=$(int_mul "$(int_neg 2)" "$(int_neg 2)")
int_eq "$product" "$(int_pos 4)" && echo "(−2) × (−2) = +4  ✓"
```

Integer multiplication: `(a,b) × (c,d) = (ac+bd, ad+bc)`. The sign rule falls out naturally — it is not assumed.

### The size wall

Integer `+5` works (135-char name). Integer `+6` fails:

```bash
int_pos 6
# ERROR: set too large to handle (name would be 263 chars — use smaller sets)
```

This is not arbitrary. The structural name of `+6` wraps ordinal 6 (127 chars) in two more layers of pairing, pushing the total to 263 chars. The name encodes the entire set hierarchy — there is no shortcut.

---

## Part III — Rational Numbers

Division can leave the integers. The fix: represent a rational as a pair of an integer numerator and a natural-number denominator:

```
rational r  =  opair(integer_numerator, natural_denominator)

1/2   =  opair(+1, 2)  =  opair(int_pos 1,  nat 2)
−3/4  =  opair(−3, 4)  =  opair(int_neg 3,  nat 4)
```

Equality: `p/q = r/s` iff `p × s = r × q` as integers. Denominators (naturals) are lifted to integers via `nat_to_int n = opair(n, ∅)` — no bash arithmetic involved.

```bash
one_half=$(rat_make "$(int_pos 1)" "$(nat 2)")
two_fourths=$(rat_make "$(int_pos 2)" "$(nat 4)")

rat_show "$one_half"      # 1/2
rat_show "$two_fourths"   # 2/4

rat_eq "$one_half" "$two_fourths" && echo "1/2 = 2/4  ✓"
```

```bash
neg_three_fourths=$(rat_make "$(int_neg 3)" "$(nat 4)")
rat_show "$neg_three_fourths"   # -3/4
```

### Ordered pairs of rationals

```bash
# The rational interval (1/2, 2/3) as an ordered pair
lower=$(rat_make "$(int_pos 1)" "$(nat 2)")
upper=$(rat_make "$(int_pos 2)" "$(nat 3)")
interval=$(opair "$lower" "$upper")

echo "lower = $(rat_show "$(fst "$interval")")"   # 1/2
echo "upper = $(rat_show "$(snd "$interval")")"   # 2/3
```

### Rationals as a relation

A partial function `f : ℕ → ℚ` can be constructed as a set of ordered pairs:

```bash
# f = { (0, 1/2), (1, 1/3), (2, 2/3) }
p0=$(opair "$(nat 0)" "$lower")
p1=$(opair "$(nat 1)" "$(rat_make "$(int_pos 1)" "$(nat 3)")")
p2=$(opair "$(nat 2)" "$upper")
fam=$(pair "$p0" "$p1")
fam=$(pair "$fam" "$p2")   # three-element family

echo "domain: $(dom "$fam")"    # {∅,{∅},{∅,{∅}}} = {0,1,2}
is_function "$fam" "$(nat 3)" "$(power "$(nat 1)")" || true
```

---

## Part IV — The Representation Horizon

Before we reach irrational numbers, a pattern is already clear:

| Object | Represented as | Structural name size |
|--------|---------------|---------------------|
| nat 3  | 3-element ordinal | 15 chars |
| int +3 | opair(ordinal_3, ∅) | 39 chars |
| rat 1/2 | opair(int_1, ordinal_2) | 45 chars |
| int +6 | — | **263 chars → FAIL** |
| nat 7  | 7-element ordinal | **> 200 chars → FAIL** |

Each wrapping layer (int wraps two nats, rat wraps int + nat) multiplies the name length. By the time we reach the rationals we would need to *approximate* √2, the integers involved are already beyond the safe zone.

This is not a bug in the implementation — it is the **honest cost of structural naming**. Every character in a filename is a piece of the actual set-theoretic object. There are no abbreviations. The machine cannot lie about the size of what it is holding.

---

## Part V — Irrational Numbers: The Object-Level Conflict

### What √2 is in ZFC

Irrational numbers are defined via **Dedekind cuts**. The real number √2 is *identified with* the following set of rationals:

```
L(√2) = { q ∈ ℚ  |  q ≤ 0  or  q² < 2 }
```

This set is the object. Not a description of it, not an approximation — the cut *is* √2 in ZFC. Two cuts that contain the same rationals are the same real number (extensionality).

### Why our universe cannot contain it

`L(√2)` has **infinitely many elements** (every rational below √2). In our universe:

- Sets are files
- Files are finite
- Therefore every set in our universe is finite

Our universe is exactly **Vω**, the hereditarily finite sets — the model of ZFC you get if you drop the Axiom of Infinity. In Vω:

- Every natural number exists ✓
- Every integer exists ✓ (within the size wall)
- Every rational number exists ✓ (within the size wall)
- **No irrational number exists** ✗

To witness this concretely: even the finite *approximation* to `L(√2)` — the rationals below √2 with denominator ≤ 3 — would be a set containing elements like `rat_make (int_pos 4) (nat 3)` (= 4/3, since (4/3)² = 16/9 < 2). Each element is itself a large set. Collect enough of them and the set's structural name explodes before you've even come close to the infinite cut.

```bash
# Build a small approximation: non-negative rationals p/q ≤ 2 with q ≤ 2 and (p/q)² < 2
# Candidates: 0/1, 1/2, 1/1  ( 0² = 0 < 2, (1/2)² = 0.25 < 2, 1² = 1 < 2 )

r_0=$(rat_make "$(int_zero)" "$(nat 1)")      # 0/1
r_half=$(rat_make "$(int_pos 1)" "$(nat 2)")  # 1/2
r_1=$(rat_make "$(int_pos 1)" "$(nat 1)")     # 1/1

approx=$(binary_union "$(pair "$r_0" "$r_half")" "$(singleton "$r_1")")

echo "Finite approximation to L(√2): $(cardinality "$approx") elements"
```

Three elements in the approximation. The full cut contains ℵ₀.

### The proof it doesn't exist

√2 is irrational — proved by contradiction in ZFC. Any finite set of rationals has a least upper bound that is rational. Therefore no finite set of rationals *is* √2. The Dedekind cut exists in ZFC because the Axiom of Infinity guarantees the existence of infinite sets. Remove Infinity, and the reals disappear.

Our bash universe is a model of **ZFC − Infinity**. In it, the sentence "√2 exists" is **false**. This is not a limitation of our tools — it is a theorem.

### What ω itself looks like

`build_omega n` constructs the *first n* Von Neumann ordinals and names the resulting finite set `ω_n`. But true ω — the set of *all* natural numbers — is infinite. We can only approach it:

```bash
omega=$(build_omega 5)   # ω_5 = {0, 1, 2, 3, 4} — a 5-element set
echo "$(cardinality "$omega") elements"  # 5, not ∞
```

Even the Axiom of Infinity is only partially realised here: we have the *witness* (each finite ordinal exists) but not the *object* (the set of all of them).

### Machine will get stuck

Some questions about sets cannot be decided by any algorithm. The canonical example:

```bash
halts my_program my_input
# ERROR: Machine will get stuck! (Halting Problem — undecidable)
```

The Halting Problem is not an oversight in our implementation. It reflects a theorem in the metatheory: no computable function can decide, for arbitrary input, whether a given Turing machine halts. Our universe is a computable model, so this limitation is inherited.

---

## Quick Reference

```
source zfc.sh       — load all axioms and derived ops
source numbers.sh   — load nat, int, rat helpers
source scratch.sh   — interactive helpers: lsu, ord N, sp SET
```

### Core operations

| Function | What it does |
|----------|-------------|
| `empty_set` | create ∅ |
| `singleton A` | {A} |
| `pair A B` | {A, B} |
| `union F` | ⋃F |
| `binary_union A B` | A ∪ B |
| `power A` | 𝒫(A) — warning: 2^n sets |
| `successor A` | A ∪ {A} |
| `sep A pattern` | {x ∈ A : x matches grep pattern} |
| `sep_fn A func` | {x ∈ A : func x = true} |
| `replace A func` | {func(x) : x ∈ A} |
| `intersection A B` | A ∩ B |
| `difference A B` | A \ B |
| `eq A B` | A = B (extensionality) |
| `member x A` | x ∈ A |
| `subset A B` | A ⊆ B |
| `cardinality A` | \|A\| |
| `choose A` | one element from A |
| `choice_fn F` | a choice function on family F |
| `is_regular A` | check A ∉ A |

### Ordered pairs and relations

| Function | What it does |
|----------|-------------|
| `opair A B` | (A, B) = {{A},{A,B}} |
| `fst P` | first component |
| `snd P` | second component |
| `cartesian A B` | A × B |
| `dom R` | domain of relation |
| `ran R` | range of relation |
| `rel_apply R a` | {b : (a,b) ∈ R} |
| `is_function R A B` | R : A → B total single-valued |

### Numbers (requires `numbers.sh`)

| Function | What it does |
|----------|-------------|
| `nat n` | Von Neumann ordinal n |
| `nat_add A B` | ordinal addition |
| `nat_mul A B` | ordinal multiplication |
| `int_pos n` | integer +n = opair(nat n, ∅) |
| `int_neg n` | integer −n = opair(∅, nat n) |
| `int_zero` | 0 as integer |
| `int_add I J` | integer addition |
| `int_sub I J` | integer subtraction |
| `int_mul I J` | integer multiplication |
| `int_negate I` | additive inverse |
| `int_eq I J` | integer equality |
| `int_show I` | print value (bash integer) |
| `rat_make I N` | rational I/N |
| `rat_eq P Q` | rational equality |
| `rat_show R` | print as "p/q" |

### Errors

| Error | Meaning |
|-------|---------|
| `set too large to handle` | structural name > 200 chars; use smaller sets |
| `set 'X' not in universe` | X has not been constructed yet |
| `cannot choose from empty set` | choice from ∅ is undefined |
| `Machine will get stuck!` | halting problem — undecidable |

### Size limits (safe zones)

- **Ordinals**: 0 – 6 (ordinal 7 exceeds the name-length guard)
- **Integers**: ±1 – ±5
- **Power sets**: `power` is safe for sets with ≤ 5 elements
- **Rationals**: numerators ≤ ±4, denominators ≤ 4
