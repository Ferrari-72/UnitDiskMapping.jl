# Understanding the Gadget Verification Test

## Purpose

This document helps you understand the first test set in `test/gadgets.jl`. The test verifies that each gadget can safely replace a pattern while preserving the Maximum Independent Set (MIS) problem structure.

## The Big Picture

**What are we testing?**
- We have a **source pattern** P (the original graph structure)
- We have a **mapped gadget** R' (the replacement that should work on unit disk graphs)
- We want to verify: Can R' replace P without breaking the MIS problem?

**How do we verify?**
- Compare the reduced α-tensors of P and R'
- Check if they differ by a constant (Theorem 3.7)
- If yes → gadget is valid ✓

## Line-by-Line Understanding

### Line 7: Loop through all gadgets
```julia
for s in [UnitDiskMapping.crossing_ruleset..., UnitDiskMapping.simplifier_ruleset...]
```
**What it does:** Iterates through every gadget that needs to be verified.

**Why:** We need to check each gadget individually to ensure they all work correctly.

---

### Line 8: Print for debugging
```julia
println("Testing gadget:\n$s")
```
**What it does:** Prints which gadget is being tested.

**Why:** Helps you see progress when running tests.

---

### Line 9: Get the source pattern
```julia
locs1, g1, pins1 = source_graph(s)
```
**What it does:** Extracts the **original pattern** before replacement.

**Returns:**
- `locs1`: Where vertices are located (for visualization)
- `g1`: The actual graph structure (vertices and edges)
- `pins1`: Which vertices are on the boundary (connect to the rest of the graph)

**Think of it as:** "This is what we want to replace"

---

### Line 10: Get the replacement gadget
```julia
locs2, g2, pins2 = mapped_graph(s)
```
**What it does:** Extracts the **replacement gadget** that will replace the pattern.

**Returns:** Same structure as Line 9, but for the replacement gadget.

**Think of it as:** "This is what we want to replace it with"

---

### Line 11: Sanity check
```julia
@assert length(locs1) == nv(g1)
```
**What it does:** Makes sure the data is consistent (number of locations = number of vertices).

**Why:** Catches bugs early if something is wrong with the data.

---

### Line 12: Compute reduced α-tensor for source pattern
```julia
m1 = mis_compactify!(solve(GenericTensorNetwork(IndependentSet(g1), openvertices=pins1), SizeMax()))
```
**What it does:** Computes the reduced α-tensor for pattern P.

**Key point:** We treat this as a **black box**. You don't need to understand how it computes the α-tensor internally. Just know that:
- It takes the graph `g1` and boundary vertices `pins1`
- It returns `m1`, which contains `α̃(P)` - the reduced α-tensor values

**What is α̃(P)?**
- A lookup table: for each boundary configuration, what's the maximum MIS size inside P?
- "Reduced" means dominated configurations are filtered out (set to -∞)

---

### Line 13: Compute reduced α-tensor for replacement gadget
```julia
m2 = mis_compactify!(solve(GenericTensorNetwork(IndependentSet(g2), openvertices=pins2), SizeMax()))
```
**What it does:** Same as Line 12, but for the replacement gadget R'.

**Result:** `m2` contains `α̃(R')` - the reduced α-tensor for the replacement.

---

### Line 14: Verify data consistency
```julia
@test nv(g1) == length(locs1) && nv(g2) == length(locs2)
```
**What it does:** Double-checks that vertex counts match location counts.

**Why:** Ensures the data structure is correct before we do the actual verification.

---

### Line 15: Check if tensors differ by a constant
```julia
sig, diff = UnitDiskMapping.is_diff_by_const(content.(m1), content.(m2))
```
**What it does:** This is the **core verification step**!

**What it checks:** Do `α̃(P)` and `α̃(R')` differ by the same constant for all relevant configurations?

**Returns:**
- `sig`: `true` if they differ by a constant, `false` otherwise
- `diff`: The constant value `c` (if `sig == true`)

**The condition (Theorem 3.7):**
```
α̃(R')_s = α̃(P)_s + c   (for all relevant configurations s)
```

**Why this matters:**
- If the difference is constant, we can track the overhead
- This makes back-mapping possible (solving on mapped graph, then correcting)

**How it works (simplified):**
1. Compare corresponding entries in `m1` and `m2`
2. Skip entries where both are -∞ (dominated configurations)
3. Check if all relevant entries have the same difference
4. If yes → `sig = true`, `diff = c`
5. If no → `sig = false`, `diff = 0`

---

### Line 16: Verify against pre-computed overhead
```julia
@test diff == -mis_overhead(s)
```
**What it does:** Checks that the computed constant matches the expected overhead.

**Why the negative sign?**
- `mis_overhead(s)` represents the overhead **added** by the gadget
- `diff` is the difference in α-tensor values
- They have opposite signs because of how the equation is written

**Example:**
- If `mis_overhead = -1`, the gadget adds 1 vertex that must be excluded
- Then `diff = 1`, meaning `α̃(R') = α̃(P) + 1`

---

### Line 17: Final check
```julia
@test sig
```
**What it does:** Verifies that the constant difference condition is satisfied.

**Why:** This is the final gate - if `sig == false`, the gadget is invalid and the test fails.

---

## The Complete Flow

```
For each gadget:
  1. Get source pattern P and replacement R'
  2. Compute α̃(P) and α̃(R')
  3. Check: Do they differ by a constant?
  4. Check: Does the constant match the expected overhead?
  5. If both pass → gadget is valid ✓
```

## Key Concepts to Understand

### 1. Reduced α-Tensor
- **What:** A lookup table for MIS sizes under different boundary configurations
- **Why "reduced":** Dominated configurations are filtered out (set to -∞)
- **Why it matters:** Only relevant configurations need to be checked

### 2. Constant Difference
- **What:** `α̃(R')_s = α̃(P)_s + c` for all relevant `s`
- **Why constant:** If it varies, we can't track overhead and back-mapping fails
- **Why it works:** Makes the overhead predictable and reversible

### 3. Theorem 3.7
- **What:** The necessary and sufficient condition for gadget replacement
- **Why necessary:** If gadgets are interchangeable, this condition must hold
- **Why sufficient:** If this condition holds, gadgets are interchangeable

## What You Should Understand

✅ **You should understand:**
- What each line does (the purpose)
- Why we're checking constant difference
- What the test is verifying
- The overall flow of the verification

❌ **You don't need to understand (yet):**
- How `solve()` computes the α-tensor internally
- How `mis_compactify!` filters dominated configurations
- The details of tensor network contraction

**Think of it like driving a car:** You need to know how to use it (steering, brakes, gas), but you don't need to know how the engine works internally.

## Summary

The test verifies that each gadget satisfies Theorem 3.7 by:
1. Computing reduced α-tensors for both patterns
2. Checking if they differ by a constant
3. Verifying the constant matches expected overhead

If all tests pass, all gadgets are valid and can be safely used for graph rewriting.

