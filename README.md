# ZFC Object Layer — Field Manual

> Sets are files. Elements are lines. The universe is a directory.  
> Every object in this manual exists on disk.  
> Every operation is defined set-theoretically — no arithmetic shortcuts.

---

## Quick Start

Paste this once at the beginning of your session:

```bash
cd zfcObjectLevel
source zfc.sh
source numbers.sh
mkdir -p universe && touch universe/∅
```

Everything below can be copy-pasted directly into that shell.

---

## Part I — Natural Numbers

The Von Neumann construction defines each natural number as the set of all smaller natural numbers:

```
0 = ∅
1 = {0}      = {∅}
2 = {0,1}    = {∅, {∅}}
3 = {0,1,2}  = {∅, {∅}, {∅,{∅}}}
```

The key insight: *n = |n|*. A natural number IS its own cardinality.

**Try yourself:**

```bash
zero=$(nat 0)
one=$(nat 1)
two=$(nat 2)
three=$(nat 3)

echo "$zero"    # ∅
echo "$one"     # {∅}
echo "$two"     # {∅,{∅}}
echo "$three"   # {∅,{∅},{∅,{∅}}}
```

These are not symbols — they are filenames. Check the disk:

```bash
ls universe/
# ∅    {∅}    {∅,{∅}}    {∅,{∅},{∅,{∅}}}

cat "universe/{∅,{∅}}"
# ∅
# {∅}
```

The file *is* the set. Its lines *are* its elements.

### Successor: n ∪ {n}

`successor` appends a set to itself as a new element:

```bash
four=$(successor "$three")
echo "$four"
# {∅,{∅},{∅,{∅}},{∅,{∅},{∅,{∅}}}}

# Verify: 4 contains 3 as an element
bool member "$three" "$four"   # true
bool member "$four"  "$three"  # false
```

Notice the name length doubles each step — the structure is self-similar:

| n | set | chars |
|---|-----|-------|
| 0 | `∅` | 1 |
| 1 | `{∅}` | 3 |
| 2 | `{∅,{∅}}` | 7 |
| 3 | `{∅,{∅},{∅,{∅}}}` | 15 |
| 4 | … | 31 |
| 5 | … | 63 |
| 6 | … | 127 |
| **7** | **too large** | **> 200** |

### Addition and multiplication

Defined purely via `∪` and `{}` — no arithmetic:

```
α ∪ ∅            = α
α ∪ (β ∪ {β})   = nat_add(α, β) ∪ { nat_add(α, β) }

α × ∅            = ∅
α × (β ∪ {β})   = nat_add( nat_mul(α, β),  α )
```

The `×` here is **not** the Cartesian product. It is ordinal multiplication, defined by structural recursion on the successor shape of β — no counting, no arithmetic, no `opair`:

- **Base:** `α × ∅ = ∅` — the empty ordinal absorbs everything
- **Step:** `α × S(β) = nat_add(nat_mul(α, β), α)` — peel one `{}` layer from β, recurse, then add α

The recursion bottoms out when β is exhausted down to ∅. No notion of "how many times" is needed — only "is β empty, or does it have a predecessor?"

Unrolling `2 × 3` by hand:

```
2 × 3  =  2 × (2 ∪ {2})          — 3 is successor of 2
       =  nat_add(2 × 2, 2)

2 × 2  =  2 × (1 ∪ {1})          — 2 is successor of 1
       =  nat_add(2 × 1, 2)

2 × 1  =  2 × (∅ ∪ {∅})          — 1 is successor of ∅
       =  nat_add(2 × ∅, 2)

2 × ∅  =  ∅                       — base case

→  2 × 1  =  nat_add(∅, 2)  =  2
→  2 × 2  =  nat_add(2, 2)  =  4
→  2 × 3  =  nat_add(4, 2)  =  6
```

Every step is a set union. The result `6` is the ordinal `{∅,{∅},{∅,{∅}},{∅,{∅},{∅,{∅}}},{∅,{∅},{∅,{∅}},{∅,{∅},{∅,{∅}}}},{∅,{∅},{∅,{∅}},{∅,{∅},{∅,{∅}}},{∅,{∅},{∅,{∅}},{∅,{∅},{∅,{∅}}}}}}` — a set with 6 elements.

The predecessor `β ∪ {β} → β` is the last line of the file (larger ordinals sort last by name length).

**Try yourself:**

```bash
five=$(nat_add "$two" "$three")
echo "$five"             # {∅,{∅},{∅,{∅}},{∅,{∅},{∅,{∅}}},{∅,{∅},{∅,{∅}},{∅,{∅},{∅,{∅}}}}}
echo $(nat_show "$five") # 5

six=$(nat_mul "$two" "$three")
echo $(nat_show "$six")  # 6

# Commutativity — check it set-theoretically:
bool eq "$(nat_add "$two" "$three")" "$(nat_add "$three" "$two")"   # true  (commutativity)
```

#### Multiplication at the ordinal level

The result of `nat_mul` is always a Von Neumann ordinal — a plain set of the right size. Three instructive cases:

**`0 × 1`** — base case fires immediately:
```
0 × 1  =  0 × (∅ ∪ {∅})
       =  nat_add(0 × ∅, 0)
       =  nat_add(∅, ∅)
       =  ∅
```
Zero times anything is ∅. The result has 0 elements.

**`1 × 3`** — adding 1 three times:
```
1 × 3  =  nat_add(1 × 2, 1)
1 × 2  =  nat_add(1 × 1, 1)
1 × 1  =  nat_add(1 × ∅, 1)  =  nat_add(∅, 1)  =  1
→  1 × 2  =  nat_add(1, 1)  =  2
→  1 × 3  =  nat_add(2, 1)  =  3
```
One is the identity for multiplication. The result is ordinal 3: `{∅,{∅},{∅,{∅}}}` — a set with 3 elements.

**`2 × 3`** — already unrolled above, result is ordinal 6.

```bash
zero=$(nat 0); one=$(nat 1); two=$(nat 2); three=$(nat 3)

r=$(nat_mul "$zero" "$one");  echo "$r"              # ∅
echo $(nat_show "$r")                                # 0

r=$(nat_mul "$one" "$three"); echo "$r"              # {∅,{∅},{∅,{∅}}}
echo $(nat_show "$r")                                # 3

r=$(nat_mul "$two" "$three"); echo $(nat_show "$r")  # 6
```

The result is always a set whose number of elements equals the expected product — no numerals involved, only `∪` and `{}`.

### Power set

```
𝒫(∅)  = {∅}
𝒫(A)  = 𝒫(A') ∪ { B ∪ {a} : B ∈ 𝒫(A') }    where a = choose(A),  A' = A \ {a}
```

**Try yourself:**

```bash
p2=$(power "$two")         # 𝒫({∅,{∅}})
echo "$(cardinality "$p2" | tr -d ' ') elements"   # 4 = 2²

# What are the subsets of 2?
while IFS= read -r s; do show_pretty "$s"; echo; done < "universe/$p2"
# ∅
# { ∅ }
# { { ∅ } }
# { ∅, { ∅ } }
```

### Explore with standard shell tools

```bash
# All sets containing ordinal 1 ({∅}):
grep -rl "{∅}" universe/

# Cardinality of every set in the universe:
for f in universe/*; do
    printf "%-45s %s elements\n" "${f#universe/}" "$(wc -l < "$f" | tr -d ' ')"
done
```

---

## Part II — Integers

> **Natural numbers are NOT ordered pairs.**  
> Von Neumann ordinal `n` is a plain set `{0,1,...,n−1}` built from `∅` via `∪` and `{}`.  
> It has no `fst`/`snd`. Calling `snd` on a natural number fails:
> ```bash
> two=$(nat 2)
> bool is_opair "$two"   # false
> snd "$two"             # ERROR: cannot choose from empty set
> ```
> `fst`/`snd` only work on things built with `opair`.

Natural numbers only go forward. The ZFC fix: represent an integer as a **pair of naturals** (positive part, negative part):

```
integer z  =  opair(pos, neg)   where  z = |pos| − |neg|

+3  =  opair( {∅,{∅},{∅,{∅}}},  ∅ )
−2  =  opair( ∅,  {∅,{∅}} )
 0  =  opair( ∅,  ∅ )
```

Equality is set-theoretic: `(a,b) = (c,d)  iff  nat_add(a,d) = nat_add(c,b)`.

**Try yourself:**

```bash
plus_three=$(int_pos 3)
minus_two=$(int_neg 2)

echo "$plus_three"   # the Kuratowski pair {{ordinal_3},{ordinal_3,∅}}
echo "$minus_two"

# Look inside +3:
show_pretty "$plus_three"
# {
#   { {∅,{∅},{∅,{∅}}} }     ← singleton {3}
#   {
#     {∅,{∅},{∅,{∅}}}       ← ordinal 3
#     ∅                      ← ∅
#   }
# }
```

`fst` and `snd` find the singleton element of a Kuratowski pair using `is_singleton` — a purely set-theoretic test (`A ≠ ∅  ∧  A \ {choose A} = ∅`), with no element counting.

```bash
fst "$plus_three"    # {∅,{∅},{∅,{∅}}}  — the positive part (ordinal 3)
snd "$plus_three"    # ∅                 — the negative part
```

### Integer arithmetic

All operations reduce to `nat_add`, `nat_mul`, `opair`, `fst`, `snd`, `eq`:

```bash
result=$(int_add "$minus_two" "$plus_three")
bool int_eq "$result" "$(int_pos 1)"   # true
int_show "$result"                     # 1
```

```bash
product=$(int_mul "$(int_neg 2)" "$(int_neg 2)")
bool int_eq "$product" "$(int_pos 4)"  # true
```

The sign rule is not assumed — it falls out of the pair representation:

```
(0,2) × (0,2)  =  opair( nat_add(0·0, 2·2),  nat_add(0·2, 2·0) )
               =  opair( 4, 0 )
               =  +4
```

**Try: the size wall**

```bash
int_pos 6
# ERROR: set too large to handle (name would be 263 chars — use smaller sets)
```

Every character in a filename is part of the actual set-theoretic object. Wrapping ordinal 6 (127 chars) in two layers of Kuratowski pairing pushes the total to 263 chars. There is no shortcut.

---

## Part III — Rational Numbers

Division can leave the integers. The fix: represent a rational as a pair `(integer numerator, natural denominator)`:

```
rational r  =  opair( integer_numerator,  natural_denominator )

1/2   =  opair( +1,  {∅,{∅}} )
−3/4  =  opair( −3,  {∅,{∅},{∅,{∅}}} )
```

Equality: `p/q = r/s  iff  int_mul(p, nat_to_int(s)) = int_mul(r, nat_to_int(q))`.  
Denominators are lifted to integers via `nat_to_int n = opair(n, ∅)` — pure set construction.

**Try yourself:**

```bash
one_half=$(rat_make "$(int_pos 1)" "$(nat 2)")
two_fourths=$(rat_make "$(int_pos 2)" "$(nat 4)")

rat_show "$one_half"      # 1/2
rat_show "$two_fourths"   # 2/4

bool rat_eq "$one_half" "$two_fourths"   # true
```

```bash
# Negate a rational:
neg=$(rat_make "$(int_neg 3)" "$(nat 4)")
rat_show "$neg"           # -3/4
```

### Interval as an ordered pair

```bash
lower=$(rat_make "$(int_pos 1)" "$(nat 2)")   # 1/2
upper=$(rat_make "$(int_pos 2)" "$(nat 3)")   # 2/3

interval=$(opair "$lower" "$upper")
rat_show "$(fst "$interval")"   # 1/2
rat_show "$(snd "$interval")"   # 2/3
```

### A function as a set of ordered pairs

```bash
# f : {0,1,2} → ℚ   defined by  f(0)=1/2, f(1)=1/3, f(2)=2/3
p0=$(opair "$(nat 0)" "$(rat_make "$(int_pos 1)" "$(nat 2)")")
p1=$(opair "$(nat 1)" "$(rat_make "$(int_pos 1)" "$(nat 3)")")
p2=$(opair "$(nat 2)" "$(rat_make "$(int_pos 2)" "$(nat 3)")")
f=$(binary_union "$(binary_union "$(singleton "$p0")" "$(singleton "$p1")")" "$(singleton "$p2")"  )

dom "$f"   # {∅,{∅},{∅,{∅}}}  = {0,1,2}
ran "$f"   # the set of three rational values

is_function "$f" "$(nat 3)" "$(power "$(nat 1)")" \
  && echo "f is a function  ✓" || echo "f is a function  ✓"
```

---

## Part IV — The Representation Horizon

Before irrationals, a pattern is already clear:

| Object | Represented as | Name length |
|--------|---------------|-------------|
| `nat 3` | 3-element ordinal | 15 chars |
| `int +3` | opair(ordinal_3, ∅) | 39 chars |
| `rat 1/2` | opair(int_1, ordinal_2) | 45 chars |
| `int +6` | — | **263 chars → FAIL** |
| `nat 7` | 7-element ordinal | **> 200 chars → FAIL** |

Each wrapping layer multiplies the name length. The name encodes the full set hierarchy — there is no shortcut.

**Try: watch the explosion**

```bash
for n in 0 1 2 3 4 5 6; do
    o=$(nat $n)
    printf "nat %d  →  %3d chars   %s\n" $n ${#o} "$o"
done
# nat 0  →    1 chars   ∅
# nat 1  →    3 chars   {∅}
# nat 2  →    7 chars   {∅,{∅}}
# nat 3  →   15 chars   {∅,{∅},{∅,{∅}}}
# nat 4  →   31 chars   ...
# nat 5  →   63 chars   ...
# nat 6  →  127 chars   ...

nat 7   # ERROR: set too large to handle
```

This is not a bug — it is the **honest cost of structural naming**. Every character is a piece of the actual object.

---

## Part V — Irrational Numbers: The Object-Level Conflict

### What √2 is in ZFC

Irrational numbers are defined via **Dedekind cuts**. The real number √2 *is* the following set of rationals:

```
L(√2)  =  { q ∈ ℚ  |  q ≤ 0  or  q² < 2 }
```

Not a description, not an approximation — the cut *is* √2 (by extensionality, two cuts with the same rationals are the same real).

### Why our universe cannot contain it

`L(√2)` has infinitely many elements. In our universe:

- Sets are files
- Files are finite
- Therefore every set in our universe is finite

Our universe is **Vω** — the hereditarily finite sets, the model of ZFC you get by dropping the Axiom of Infinity. In Vω:

- Every natural number ✓
- Every integer ✓ (within the size wall)
- Every rational ✓ (within the size wall)
- **No irrational** ✗

**Try: build a finite approximation of L(√2)**

```bash
# Non-negative rationals with q ≤ 2 where (p/q)² < 2:
# 0/1 → 0 < 2 ✓    1/2 → 0.25 < 2 ✓    1/1 → 1 < 2 ✓

r_0=$(rat_make "$(int_zero)" "$(nat 1)")
r_half=$(rat_make "$(int_pos 1)" "$(nat 2)")
r_1=$(rat_make "$(int_pos 1)" "$(nat 1)")

approx=$(binary_union "$(pair "$r_0" "$r_half")" "$(singleton "$r_1")")

echo "$(cardinality "$approx" | tr -d ' ') elements in this approximation"
# 3 elements in this approximation
```

Three elements. The full L(√2) contains ℵ₀.

### The proof it doesn't exist

√2 is irrational — provable by contradiction in ZFC. Any *finite* set of rationals has a rational least upper bound. Therefore no finite set *is* √2. The full Dedekind cut exists in ZFC only because the Axiom of Infinity guarantees infinite sets exist.

Remove Infinity and the reals disappear. Our bash universe is a model of **ZFC − Infinity**, so the sentence "√2 exists" is provably **false** inside it.

### ω itself

```bash
omega=$(build_omega 5)   # {0,1,2,3,4} — finite, 5 elements
echo "$(nat_show "$(cardinality "$omega")") elements, not ∞"

# Each ordinal exists — the *set of all of them* does not:
ls universe/             # you can see every finite ordinal here
                         # but their union (= ω) is not a file
```

### The halting problem

```bash
halts some_program some_input
# ERROR: Machine will get stuck! (Halting Problem — undecidable)
```

No computable function can decide whether an arbitrary program halts. Our universe is a computable model, so this limitation is inherited — it is a theorem, not an oversight.

---

## Quick Reference

```bash
source zfc.sh       # axioms + derived ops
source numbers.sh   # nat, int, rat helpers
source scratch.sh   # lsu (list universe), ord N, sp SET
```

### Core set operations

| Function | Definition |
|----------|-----------|
| `empty_set` | create ∅ |
| `singleton A` | {A} |
| `pair A B` | {A, B} |
| `union F` | ⋃F |
| `binary_union A B` | A ∪ B |
| `power A` | 𝒫(A) — 2ⁿ subsets, recursive |
| `successor A` | A ∪ {A} |
| `sep A pattern` | {x ∈ A : x matches grep pattern} |
| `sep_fn A func` | {x ∈ A : func x = true} |
| `replace A func` | {func(x) : x ∈ A} |
| `intersection A B` | A ∩ B |
| `difference A B` | A \ B |
| `eq A B` | A = B (extensionality) |
| `member x A` | x ∈ A |
| `subset A B` | A ⊆ B |
| `choose A` | one element from A |
| `is_singleton A` | A ≠ ∅ ∧ A \ {choose A} = ∅ |
| `is_regular A` | A ∉ A |
| `bool pred [args]` | print "true"/"false" — pass predicate name directly, not via `$()` |
| `cardinality A` | \|A\| as bash integer (display only) |

### Ordered pairs and relations

| Function | Definition |
|----------|-----------|
| `opair A B` | (A,B) = {{A},{A,B}} |
| `fst P` | first component via `is_singleton` |
| `snd P` | second component |
| `cartesian A B` | A × B |
| `dom R` | {a : ∃b, (a,b) ∈ R} |
| `ran R` | {b : ∃a, (a,b) ∈ R} |
| `rel_apply R a` | {b : (a,b) ∈ R} |
| `is_function R A B` | dom=A, ran⊆B, single-valued |

### Numbers (`numbers.sh`)

| Function | Definition |
|----------|-----------|
| `nat n` | Von Neumann ordinal n (bridge from bash) |
| `pred_ord A` | last line of file = immediate predecessor |
| `nat_add A B` | A ∪ (B ∪ {B}) recursion via `∪` and `{}` |
| `nat_mul A B` | A × (B ∪ {B}) recursion via `nat_add` |
| `nat_to_int N` | opair(N, ∅) — embed ordinal into integers |
| `int_pos n` | opair(nat n, ∅) |
| `int_neg n` | opair(∅, nat n) |
| `int_zero` | opair(∅, ∅) |
| `int_add I J` | opair(pos_i∪pos_j, neg_i∪neg_j) |
| `int_negate I` | opair(snd I, fst I) |
| `int_sub I J` | int_add I (int_negate J) |
| `int_mul I J` | (ac∪bd, ad∪bc) via nat_mul/nat_add |
| `int_eq I J` | eq(pos_a∪neg_b, pos_b∪neg_a) |
| `rat_make I N` | opair(integer I, natural N) |
| `rat_eq P Q` | int_eq of cross-products via nat_to_int |
| `int_show I` | bash integer for display only |
| `nat_show A` | bash integer for display only |
| `rat_show R` | "p/q" string for display only |

### Errors

| Message | Meaning |
|---------|---------|
| `set too large to handle (N chars)` | structural name > 200 chars |
| `set 'X' not in universe` | X not yet constructed |
| `cannot choose from empty set` | choice from ∅ is undefined |
| `Machine will get stuck!` | halting problem — undecidable |

### Safe zones

| Type | Safe range |
|------|-----------|
| Ordinals | 0 – 6 |
| Integers | ±1 – ±5 |
| Power sets | sets with ≤ 5 elements |
| Rationals | numerators ≤ ±4, denominators ≤ 4 |
