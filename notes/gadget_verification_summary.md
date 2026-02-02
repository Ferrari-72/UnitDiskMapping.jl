# Gadget Verification Summary

## Overview

This document summarizes the verification of gadgets from the original paper using the test suite in `test/gadgets.jl`. The verification process checks that each gadget satisfies the mathematical condition from Theorem 3.7, ensuring that gadget replacement preserves the maximum independent set (MIS) problem structure.

## Test Structure: First Test Set in `test/gadgets.jl`

The first test set (`@testset "gadgets"`) verifies all gadgets in both `crossing_ruleset` and `simplifier_ruleset`. Here's a line-by-line explanation:

### Line-by-Line Analysis

**Line 7**: `for s in [UnitDiskMapping.crossing_ruleset..., UnitDiskMapping.simplifier_ruleset...]`
- Iterates through all gadgets in both rulesets
- `crossing_ruleset` contains 13 crossing gadgets (Cross, Turn, WTurn, Branch, etc.)
- `simplifier_ruleset` contains simplification gadgets (currently DanglingLeg)

**Line 8**: `println("Testing gadget:\n$s")`
- Prints the gadget being tested for debugging

**Line 9**: `locs1, g1, pins1 = source_graph(s)`
- Extracts the **source pattern** (original graph structure before replacement)
- Returns:
  - `locs1`: Vertex positions (for visualization)
  - `g1`: Graph structure of pattern P
  - `pins1`: Indices of boundary vertices (∂P) - the vertices that connect to the rest of the graph

**Line 10**: `locs2, g2, pins2 = mapped_graph(s)`
- Extracts the **mapped gadget** (replacement pattern R')
- Returns the same structure for the replacement gadget

**Line 11**: `@assert length(locs1) == nv(g1)`
- Asserts that the number of locations matches the number of vertices in the source graph
- This is a sanity check

**Line 12**: `m1 = mis_compactify!(solve(GenericTensorNetwork(IndependentSet(g1), openvertices=pins1), SizeMax()))`
- Computes the reduced α-tensor for the source pattern P
- We treat this as a black box: it gives us `α̃(P)` - the reduced α-tensor values for all boundary configurations
- Result: `m1` contains the reduced α-tensor `α̃(P)`

**Line 13**: `m2 = mis_compactify!(solve(GenericTensorNetwork(IndependentSet(g2), openvertices=pins2), SizeMax()))`
- Computes the reduced α-tensor for the mapped gadget R'
- Same process, but for the replacement gadget
- Result: `m2` contains the reduced α-tensor `α̃(R')`

**Line 14**: `@test nv(g1) == length(locs1) && nv(g2) == length(locs2)`
- Verifies that vertex counts match location counts for both graphs
- This ensures data consistency

**Line 15**: `sig, diff = UnitDiskMapping.is_diff_by_const(content.(m1), content.(m2))`
- Checks if the two reduced α-tensors differ by a constant
- The function `is_diff_by_const` (in `src/utils.jl`) implements:
  ```julia
  function is_diff_by_const(t1, t2)
      x = NaN
      for (a, b) in zip(t1, t2)
          if isinf(a) && isinf(b)  # Both dominated: skip
              continue
          end
          if isinf(a) || isinf(b)  # One dominated, one not: invalid!
              return false, 0
          end
          if isnan(x)
              x = (a - b)  # First relevant config: set constant
          elseif x != a - b  # Subsequent configs: check constancy
              return false, 0
          end
      end
      return true, x
  end
  ```
- Returns:
  - `sig`: Boolean indicating if constant difference exists
  - `diff`: The constant c, or 0 if no constant exists
- This implements Theorem 3.7: `α̃(R')_s = α̃(P)_s + c` for all relevant configurations s

**Line 16**: `@test diff == -mis_overhead(s)`
- Verifies that the computed constant difference matches the pre-computed `mis_overhead`
- Note: The difference is negated because `mis_overhead` represents the overhead added by the gadget
- Example: If `mis_overhead = -1`, then `diff = 1`, meaning `α̃(R') = α̃(P) + 1`

**Line 17**: `@test sig`
- Final verification that the constant difference condition is satisfied
- If `sig == false`, the gadget is invalid

## Mathematical Foundation

### Theorem 3.7 Condition

For a gadget replacement P → R' to be valid, the reduced α-tensors must satisfy:

```
α̃(R')_s = α̃(P)_s + c
```

for all relevant boundary configurations s, where c is a constant (independent of s).

### Why This Works

1. **Additive Decomposition**: The α-tensor decomposes additively: `α(G) = α(R) + α(G\R)`
2. **Independence**: Given a boundary configuration, the internal and external subproblems are independent
3. **Constant Overhead**: If the difference is constant, we can track total overhead: `α(G_mapped) = α(G_original) + c_total`
4. **Back-mapping**: This makes it possible to solve on the mapped graph and then correct for the known overhead

### Dominance Filtering

The `mis_compactify!` function filters dominated configurations:
- A configuration t is dominated if there exists s ≺ t (fewer 1s) with `α(R)_s ≥ α(R)_t`
- Dominated configurations can never be optimal in the global MIS
- Both sides being -∞ (dominated) is acceptable and ignored in the comparison

## Gadgets Verified

### Crossing Gadgets (`crossing_ruleset`)

1. **Cross{false}**: Large crossing (4×5 pattern), MIS overhead = -1
2. **Cross{true}**: Connected crossing (3×3 pattern), MIS overhead = -1
3. **Turn**: 90° turn, MIS overhead = -1
4. **WTurn**: Wide turn, MIS overhead = -1
5. **Branch**: T-junction with branch, MIS overhead = -1
6. **BranchFix**: T-junction simplification, MIS overhead = -1
7. **TCon**: T-shape with connected vertices, MIS overhead = 0
8. **TrivialTurn**: Minimal turn (2×2), MIS overhead = 0
9. **BranchFixB**: Alternate branch fix, MIS overhead = -1
10. **EndTurn**: Terminal turn, MIS overhead = -1
11. **RotatedGadget(TCon(), 1)**: Rotated TCon
12. **ReflectedGadget(Cross{true}(), "y")**: Reflected connected cross
13. **ReflectedGadget(TrivialTurn(), "y")**: Reflected trivial turn
14. **ReflectedGadget(RotatedGadget(TCon(), 1), "y")**: Reflected rotated TCon

### Simplification Gadgets (`simplifier_ruleset`)

1. **DanglingLeg**: Removes dangling paths, MIS overhead = -1

## Key Implementation Details

### `mis_compactify!` Function

This function (from GenericTensorNetworks.jl) performs two operations:
1. **Boundary subtraction**: `α - Σ i_j` where i_j are boundary vertex states
2. **Dominance filtering**: Sets dominated configurations to -∞

### `mis_overhead` Function

Pre-computed overhead values stored in `src/extracting_results.jl`:
- Most gadgets have overhead = -1 (adds 1 vertex that must be excluded from MIS)
- Some gadgets (TrivialTurn, TCon) have overhead = 0 (no net change)

### `is_diff_by_const` Function

Located in `src/utils.jl`, this function:
- Compares corresponding entries in two tensors
- Skips entries where both are -∞ (dominated)
- Returns false if one is -∞ and the other is not (mismatch)
- Returns true if all relevant entries differ by the same constant

## Verification Results

All gadgets in both rulesets pass the verification:
- ✓ Constant difference condition satisfied
- ✓ Difference matches pre-computed `mis_overhead`
- ✓ All tests pass

This confirms that all gadgets satisfy Theorem 3.7 and can be safely used for graph rewriting while preserving MIS structure.

## Connection to Original Paper

The verification implements the mathematical framework from the paper:
- **α-tensor**: Represents MIS size for each boundary configuration
- **Reduced α-tensor**: After filtering dominated configurations
- **Theorem 3.7**: Provides the condition for valid gadget replacement
- **Constant difference**: Ensures overhead is trackable and back-mapping is possible

## Conclusion

The test suite successfully verifies that all gadgets in the repository satisfy the mathematical conditions required for valid MIS-preserving graph rewriting. The implementation correctly checks that:
1. Reduced α-tensors differ by a constant
2. The constant matches the pre-computed overhead
3. Dominated configurations are properly handled

This verification ensures the correctness of the unit disk mapping algorithm.


