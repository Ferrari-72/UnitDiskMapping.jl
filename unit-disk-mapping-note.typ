#import "@preview/cetz:0.4.1": canvas, draw, tree, vector
#import "@preview/grape-suite:3.1.0": exercise
#import "@preview/ctheorems:1.1.3": thmbox, thmrules
#import exercise: project, task, subtask

// 定义定理环境
#let theorem = thmbox("theorem", "Theorem", fill: rgb("#eeffee"))
#let definition = thmbox("definition", "Definition", fill: rgb("#fff4e6"))
#let proof = thmbox("proof", "Proof", fill: rgb("#f5f5f5"), stroke: none).with(numbering: none)

// 自定义警告框
#let warning(title: "", body) = block(
  fill: rgb("#fff3cd"),
  stroke: rgb("#ffc107"),
  inset: 1em,
  width: 100%,
  radius: 4pt,
)[
  #text(weight: "bold")[⚠ #title]
  #v(0.5em)
  #body
]

#show: project.with(
  title: [Preparing for further research],
  show-outline: true,
  show-solutions: false,
  author: "Notes by Student",
  task-type: "Research Notes",
)

#show: thmrules

#show raw.where(lang:"julia"): it=>{
  par(justify:false,block(fill:rgb("#f0f0ff"),inset:1.5em,width:99%,text(it)))
}

// 论文引用
#block(
  fill: rgb("#f0f8ff"),
  stroke: rgb("#4682b4"),
  inset: 1em,
  width: 100%,
  radius: 4pt,
)[
  *Paper Reference* 论文引用:
  
  Jin-Guo Liu, Jonathan Wurtz, Minh-Thi Nguyen, Mikhail D. Lukin, Hannes Pichler, and Sheng-Tao Wang,
  "Computer-assisted gadget design and problem reduction of unweighted maximum independent set" (2023).
  
  *Main contributions*:
  - Unweighted MIS reduction to King's subgraph
  - Computer-assisted gadget search (Algorithm C.1, Appendix C)
  - BATOIDEA and other gadgets (Section 3, Figure 6)
  - Optimal size bound: $O(|V| times "pw"(G))$ (Abstract)
]

#pagebreak()

= Problem Statement

The core challenge addressed in the paper is:

#block(
  fill: rgb("#fff4e6"),
  inset: 1em,
  width: 100%,
)[
*Neutral-atom quantum computers can only solve Maximum Independent Set (MIS) problems on unit disk graphs (specifically, King's subgraphs), but real-world problems have arbitrary graph structures.*

We need a way to *reduce* arbitrary unweighted MIS problems to unit disk MIS problems while maintaining equivalence.
]

== The Mapping Strategy

The solution follows this pipeline:

+ *Path Decomposition*: Arrange vertices in optimal order to minimize grid height
+ *Create Copy Lines*: Each vertex becomes a T-shaped structure on the grid
+ *Apply Gadgets*: Replace crossings and complex patterns with unit-disk-embeddable gadgets
+ *Solve on King's Subgraph*: Use quantum computer to solve the mapped graph
+ *Map Solution Back*: Transform the solution back to the original graph

The key insight is that we can *translate* any graph into a King's subgraph, solve it there, and then *translate back* the solution.

In order for the effect of replacing a gadget on the final solution (the MIS size) to be predictable and reversible, we require that the reduced α-tensor of the gadget differ from that of the pattern being replaced by the same constant for all (relevant) boundary configurations. In other words, there should exist a constant $c$ such that for every boundary configuration:

$tilde(alpha)(R') = tilde(alpha)(P) + c.$

= The α-Tensor Framework

== What is an α-Tensor?

An *α-tensor* is a lookup table that encodes MIS information for an *open graph* (a graph with designated boundary vertices).

#definition("α-Tensor Definition")[
For an open graph $R = (V, E, partial R)$ with $|partial R| = k$ boundary vertices, the α-tensor is:

$alpha(R)[i_1, i_2, ..., i_k] = max { |S| : S "is an independent set of" R "subject to the boundary constraints" }$

Boundary constraints (for $j=1, ..., k$):
- If $i_j = 1$, the boundary vertex $(partial R)_j$ *must be in* $S$.
- If $i_j = 0$, the boundary vertex $(partial R)_j$ *must NOT be in* $S$.

In words: Given a fixed configuration on the boundary, what's the maximum number of vertices we can add to form an independent set?
]

#warning(title: "Critical Understanding: Boundary Constraints are DETERMINISTIC")[
The boundary configuration is a **complete, deterministic constraint**, NOT optional:

- $i_j = 0$ means "vertex $j$ is **forced to be excluded**" (禁止选入) — must NOT be in $S$
- $i_j = 1$ means "vertex $j$ is **forced to be included**" (强制选入) — must be in $S$

⚠️ **Common Misconception**: 
- ❌ WRONG: "$i_j = 0$ means the vertex *can* be selected or not" (optional)
- ✅ CORRECT: "$i_j = 0$ means the vertex *must NOT* be selected" (mandatory exclusion)

There is NO "maybe" or "can choose either way" option. Each boundary configuration represents one specific, fully-determined constraint scenario that the gadget must handle.

The α-tensor is a **lookup table** that enumerates *all possible* fully-determined boundary scenarios and computes the optimal internal solution for each. It's NOT a representation of "choices to be made."
]

== Example: Simple Gadget

Consider a gadget with 2 boundary vertices and 1 internal vertex:

#figure(
  canvas({
    import draw: *
    // Boundary vertices
    circle((0, 0), radius: 0.15, fill: black, name: "b1")
    circle((3, 0), radius: 0.15, fill: black, name: "b2")
    // Internal vertex
    circle((1.5, -1), radius: 0.1, fill: gray, name: "i1")
    // Edges
    line("b1", "i1")
    line("i1", "b2")
    // Labels
    content((0, 0.5), [Boundary 1])
    content((3, 0.5), [Boundary 2])
    content((1.5, -1.5), [Internal])
  }),
  caption: [A simple gadget with 2 boundary and 1 internal vertex]
)

The α-tensor for this gadget:

#align(center, table(
  columns: (auto, auto, auto, auto),
  table.header(
    table.cell(fill: green.lighten(60%))[*Boundary 1*],
    table.cell(fill: green.lighten(60%))[*Boundary 2*],
    table.cell(fill: green.lighten(60%))[*α[i₁, i₂]*],
    table.cell(fill: green.lighten(60%))[*Explanation*],
  ),
  [0], [0], [1], [Both forced OUT → internal can be IN (total: 1)],
  [0], [1], [1], [b1 OUT, b2 IN → internal blocked (total: 1)],
  [1], [0], [1], [b1 IN, b2 OUT → internal blocked (total: 1)],
  [1], [1], [2], [Both forced IN → internal blocked (total: 2)],
))

Note the language:
- "0" = "forced OUT" (must NOT be in $S$)
- "1" = "forced IN" (must be in $S$)
- The internal vertex is connected to both boundaries, so it can only be selected when both boundaries are forced OUT.

== Subproblem Independence and Additive Decomposition

Before diving into the reduced α-tensor, we need to understand *why* the MIS problem has this special structure.

#theorem("MIS Additive Decomposition")[
The MIS problem has a crucial **locality property**: when a graph is decomposed into subgraphs, once a boundary configuration $s_(partial R)$ is fixed, the global MIS objective decomposes as:

$ max_(s_(partial R)) ( alpha(R)_(s_(partial R)) + alpha(G without R)_(s_(partial R)) ) $

where:
- $alpha(R)_(s_(partial R))$: maximum IS size *inside* $R$ given boundary configuration $s_(partial R)$
- $alpha(G without R)_(s_(partial R))$: maximum IS size *outside* $R$ given the same boundary configuration
]

#block(
  fill: rgb("#fff0f0"),
  inset: 1em,
)[
*Key Property*: The two subproblems are **independent** given the boundary configuration!

- Inside $R$: we only need to maximize vertices compatible with $s_(partial R)$
- Outside $R$: we only care which boundary vertices are selected; internal choices in $R$ don't matter

This additive structure is *fundamental* to the dominance argument and the entire gadget replacement framework.
]

#warning(title: "Not All Problems Have This Property")[
The additive decomposition is special to problems like MIS where:
1. Constraints are *local* (only between adjacent vertices)
2. The objective is *additive* (sum of individual vertices)

*Counter-example*: In 3-SAT, clauses can span the entire graph, so subproblems cannot be cleanly separated by boundary configurations alone.
]

== The Reduced α-Tensor (重点)

#warning(title: "Key Concept: Reduced α-Tensor Definition")[
The term "reduced α-tensor" $tilde(alpha)(R)$ refers to **filtering out dominated (irrelevant) boundary configurations**:

$ tilde(alpha)(R)_(s_(partial R)) = cases(
  alpha(R)_(s_(partial R)) & "if" s_(partial R) "is relevant",
  -infinity & "if" s_(partial R) "is dominated or infeasible"
) $

A configuration $t$ is *dominated* if there exists a less restrictive configuration $s prec t$ (fewer 1s) such that:

$alpha(R)_s gt.eq alpha(R)_t$

**Why filter?** Dominated configurations can never be optimal in the global MIS. If a configuration with fewer constraints (fewer forced selections on boundary) achieves equal or better internal MIS size, then the more restrictive configuration is irrelevant.

**Source**: The paper applies this dominance filtering in Algorithm C.1 (Appendix C) through the `compute_reduced_alpha_tensor` function. This is the optimization that makes gadget verification tractable.

**In this project (UnitDiskMapping.jl)**: 
1. `solve(GenericTensorNetwork(...), SizeMax())` computes $alpha(R)$ for all configurations
2. `mis_compactify!(...)` filters dominated configurations
3. `is_diff_by_const(...)` verifies the gadget replacement condition using filtered tensors
]

=== Why Reduce?

When comparing two gadgets $A$ and $B$ for replacement:

#block(
  fill: rgb("#e6f3ff"),
  inset: 1em,
)[
*The boundary vertices are the same* (they must match for replacement to work).

We only care about the *difference in internal structure*.

By filtering out dominated configurations, we only compare the relevant scenarios where each gadget could actually be optimal.

#block(
  fill: rgb("#e6f7ff"),
  inset: 1em,
  width: 100%,
)[
*Why does this matter? The complete picture:*

*Stage 1: Gadget Design & Verification* (offline, done once)
- Filter dominated configurations → reduce verification work
- Check constant difference condition only for relevant configs

*Stage 2: Graph Mapping* (prepare problem for quantum computer)
- Replace patterns with gadgets
- Track total overhead $c_"total"$

*Stage 3: Solving on Quantum Computer* ⭐ **This is where it matters most!**

When the MIS solver (quantum computer) runs on the mapped graph, it performs:

$ max_(s_(partial R)) ( alpha(R)_(s_(partial R)) + alpha(G without R)_(s_(partial R)) ) $

The solver **enumerates boundary configurations** and picks the one that maximizes the total score. 

*Key insight*: Dominated configurations will **never** be selected in this optimization—there's always a better alternative with:
- Fewer constraints (fewer forced boundary selections)
- Equal or better internal MIS size

Therefore:
- ✅ Reduced α-tensor eliminates configurations that won't be selected anyway
- ✅ This reduces both verification cost (Stage 1) and potentially solver complexity (Stage 3)
- ✅ Only relevant configurations participate in the actual global optimization

*Stage 4: Solution Recovery*
$ "MIS"(G_"original") = "MIS"(G_"mapped") - c_"total" $

The solution found by the quantum computer will have chosen one of the **relevant** boundary configurations for each gadget—exactly the ones we verified in Stage 1!
]

#block(
  fill: rgb("#fff4e6"),
  inset: 1em,
  width: 100%,
)[
*Concrete Example: Why Reduce Saves Computation*

Suppose a gadget has 3 boundary vertices → $2^3 = 8$ possible configurations.

*Without filtering*:
```
Quantum solver evaluates all 8 configs:
  (0,0,0): α(R) + α(G\R) = 5 + 100 = 105 ← picked!
  (0,0,1): α(R) + α(G\R) = 3 + 98  = 101
  (0,1,0): α(R) + α(G\R) = 3 + 98  = 101
  (0,1,1): α(R) + α(G\R) = 2 + 96  = 98
  (1,0,0): α(R) + α(G\R) = 4 + 99  = 103
  (1,0,1): α(R) + α(G\R) = 2 + 97  = 99
  (1,1,0): α(R) + α(G\R) = 2 + 97  = 99
  (1,1,1): α(R) + α(G\R) = 7 + 85  = 92
```
8 evaluations needed.

*With filtering* (after dominance analysis):
```
Relevant configs: {(0,0,0), (1,1,1)} only!
  (0,0,0): 5 + 100 = 105 ← picked!
  (1,1,1): 7 + 85  = 92

Other configs marked as -∞ (won't be considered).
```
Only 2 evaluations needed! ⚡ **4× faster**

*Why this works*:
- Config (0,0,1) is dominated by (0,0,0) because:
  - (0,0,0) has fewer constraints → α(G\R)_(0,0,0) ≥ α(G\R)_(0,0,1)
  - (0,0,0) has better internal score → α(R)_(0,0,0) = 5 > 3 = α(R)_(0,0,1)
  - Therefore (0,0,1) will never be optimal, no matter what the external graph is!
- Same logic eliminates 5 other dominated configs
- Quantum solver only needs to consider the 2 truly competitive configurations
]
]

#warning(title: "Common Confusion: Does Filtering Change the Interface?")[
*Question*: If we filter out configurations with more 1s (more constraints), doesn't that change the boundary interface? How can we still compare gadgets?

*Answer*: **NO! The boundary structure NEVER changes.**

*What stays fixed*:
- Number of boundary vertices: $k$ (always the same)
- Position of boundary vertices (topological structure)
- The set of all possible configurations: ${0,1}^k$ (all $2^k$ configurations)

*What changes*:
- The **value** $tilde(alpha)(R)_s$ for each configuration $s$
- Some configurations get marked as $-infinity$ (dominated/irrelevant)

*Example*: Gadget with 2 boundary vertices

Both gadgets $A$ and $B$ have **the same 4 configurations**:

#align(center, table(
  columns: (auto, auto, auto, auto),
  table.header(
    [*Config*], [*$tilde(alpha)(A)$*], [*$tilde(alpha)(B)$*], [*Difference*]
  ),
  [(0,0)], [1], [3], [+2],
  [(0,1)], [$-infinity$], [$-infinity$], [—],
  [(1,0)], [$-infinity$], [$-infinity$], [—],
  [(1,1)], [2], [4], [+2],
))

✅ **Valid replacement**: For all *relevant* configs (non-$-infinity$), difference = +2 (constant)

The boundary interface is **identical**: both have 2 boundary vertices at the same positions. We just ignore the dominated configurations (marked as $-infinity$) when checking the constant difference condition.

*Critical requirement*: For each configuration $s$, either:
- Both $tilde(alpha)(A)_s = -infinity$ and $tilde(alpha)(B)_s = -infinity$ (both dominated), OR
- Both $tilde(alpha)(A)_s eq.not -infinity$ and $tilde(alpha)(B)_s eq.not -infinity$ (both relevant)

If $tilde(alpha)(A)_s = -infinity$ but $tilde(alpha)(B)_s eq.not -infinity$ (or vice versa), then **A and B cannot be interchanged** because they have different sets of relevant configurations.
]

=== Boundary Configurations as Interface

#block(
  fill: rgb("#e6ffe6"),
  inset: 1em,
)[
*Key Insight*: Boundary configurations serve as the **interface** between a local subproblem and the global MIS problem.

When decomposing a graph into subgraphs, the *only* information exchanged between a subgraph $R$ and the rest of the graph $G without R$ is the selection status of boundary vertices. This is due to the MIS problem's locality property:

$ max_(s_(partial R)) ( alpha(R)_(s_(partial R)) + alpha(G without R)_(s_(partial R)) ) $

The global MIS objective decomposes *additively* into two independent subproblems, coupled only through the boundary configuration $s_(partial R)$.
]

=== Why "Fewer 1s = Less Restrictive" (重要！)

This is a crucial concept that is often misunderstood. Let's clarify with precision:

#block(
  fill: rgb("#fff9e6"),
  inset: 1em,
)[
*Question*: Why does having fewer 1s in a boundary configuration make it "less restrictive" for the outside graph?

*Answer*: Because of the independent set constraint!

Consider a boundary vertex $b$ that connects to external vertices $x$ and $y$:

```
External graph:  x --- b --- y
                    (boundary)
```

*Case 1: Configuration with $b = 1$ (forced to select)*
- Boundary vertex $b$ **must be** in the independent set
- By independence constraint: $x$ and $y$ **cannot** be selected (blocked)
- External graph loses 2 potential selections
- Result: **More restrictive** for external graph

*Case 2: Configuration with $b = 0$ (forced NOT to select)*
- Boundary vertex $b$ **must NOT be** in the independent set
- Vertices $x$ and $y$ are now **free to be selected** (if no other constraints exist)
- External graph gains 2 potential selections
- Result: **Less restrictive** for external graph

*Conclusion*: $b = 0$ imposes **weaker constraints** on the external graph than $b = 1$.

More generally: A configuration with fewer 1s forces fewer boundary vertices into the independent set, leaving more freedom for external vertices adjacent to the boundary.

*Mathematical Formulation*: For any two configurations $s prec t$ (meaning $s_i lt.eq t_i$ for all $i$), we have:

$alpha(G without R)_s gt.eq alpha(G without R)_t$

because $s$ blocks fewer external vertices than $t$.
]

=== Irrelevant Boundary Configurations

Not every boundary configuration is equally important. The paper uses a notion of *irrelevant* boundary configurations based on a dominance argument in the computer-assisted search (Algorithm C.1).

#definition("Partial Order on Boundary Configurations")[
Given two boundary configurations $s, t in {0,1}^(|partial R|)$, we say $s$ is *less restrictive* than $t$, written $s prec t$, if:

$s_i lt.eq t_i quad "for all" i in {1, ..., |partial R|}$

This means $s$ has fewer (or equal) 1s than $t$.
]

#definition("Irrelevant (Dominated) Configuration")[
A boundary configuration $t$ is called *irrelevant* if:

1. $alpha(R)_t = -infinity$ (the configuration is infeasible), or
2. There exists a less restrictive configuration $s prec t$ such that $alpha(R)_s gt.eq alpha(R)_t$ (dominated).

In case 2, $t$ is *dominated* by $s$ and can be safely ignored.
]

#block(
  fill: rgb("#f0f0ff"),
  inset: 1em,
)[
*Complete Dominance Argument* (from `reduced_alpha_tensor.typ`):

Suppose there exist two boundary configurations $s$ and $t$ such that $s prec t$ and $alpha(R)_s gt.eq alpha(R)_t$.

*Step 1: External compatibility*

Because $s$ imposes weaker constraints on the outside graph (fewer boundary vertices forced to 1), it follows for any external subgraph that:

$alpha(G without R)_s gt.eq alpha(G without R)_t$

This is because $s$ blocks fewer external vertices adjacent to the boundary.

*Step 2: Global optimality*

Combining the two inequalities:

$alpha(R)_s + alpha(G without R)_s gt.eq alpha(R)_t + alpha(G without R)_t$

*Conclusion*: Configuration $t$ can **never be optimal** in the global MIS optimization:

$ max_(s_(partial R)) ( alpha(R)_(s_(partial R)) + alpha(G without R)_(s_(partial R)) ) $

It is strictly dominated by $s$ in terms of both:
- *Internal payoff*: $alpha(R)_s gt.eq alpha(R)_t$
- *External compatibility*: $alpha(G without R)_s gt.eq alpha(G without R)_t$

*Crucial Insight*: This dominance argument **relies on the additive and independent structure** of the MIS subproblems. Without such independence, the comparison would no longer be valid.

Such dominated configurations can be safely discarded without affecting the maximum independent set size.
]

#block(
  fill: rgb("#f5f5f5"),
  inset: 1em,
  width: 100%,
)[
*Important distinction*:

There are TWO types of "irrelevant" configurations:

1. *Infeasible configurations*: No valid independent set completion exists at all (e.g., two adjacent boundary vertices both set to 1). These have $alpha(R) = -infinity$.

2. *Dominated configurations*: Valid independent set exists, but dominated by a less restrictive configuration (as explained above). These are set to $-infinity$ in the reduced α-tensor.

In tropical/max-plus language, both types are represented as $-infinity$. In this project, infeasible entries often appear as an empty list `[]` in `source_entry_to_configs(...)`.
]

In this project, the dominance-based pruning is implemented via a *compactification* map `mapped_entry_to_compact(::Pattern)` which merges multiple boundary encodings into a smaller set of representatives.

#warning(title: "Connection to Paper's Algorithm C.1")[
The gadget replacement condition (referenced in Algorithm C.1) requires:

$tilde(alpha)(R') = tilde(alpha)(P) + c$

for a *constant* $c$, where $tilde(alpha)$ is the α-tensor after filtering dominated configurations (setting them to $-infinity$).

The paper implements this verification in Algorithm C.1 (Appendix C) using `is_diff_by_constant`. This ensures the gadget replacement preserves MIS structure for all *relevant* (non-dominated) boundary configurations.
]

=== Example: Computing Reduced α-Tensor (Filtering Dominated Configurations)

For the simple gadget above, let's see how the dominance filtering works:

*Step 1: Original α-tensor*

#align(center, table(
  columns: (auto, auto, auto, auto),
  table.header(
    table.cell(fill: green.lighten(60%))[*i₁*],
    table.cell(fill: green.lighten(60%))[*i₂*],
    table.cell(fill: green.lighten(60%))[*α[i₁,i₂]*],
    table.cell(fill: green.lighten(60%))[*Explanation*],
  ),
  [0], [0], [1], [Both OUT → internal IN (total: 1)],
  [0], [1], [1], [b1 OUT, b2 IN → internal blocked (total: 1)],
  [1], [0], [1], [b1 IN, b2 OUT → internal blocked (total: 1)],
  [1], [1], [2], [Both IN → internal blocked (total: 2)],
))

*Step 2: Check for dominance*

We check: is there a less restrictive configuration $s prec t$ with $alpha(R)_s gt.eq alpha(R)_t$?

- $(0,0) prec (0,1)$: Configuration (0,0) has fewer 1s. Does $alpha_(0,0) = 1 gt.eq 1 = alpha_(0,1)$? **YES!** → (0,1) is dominated
- $(0,0) prec (1,0)$: Configuration (0,0) has fewer 1s. Does $alpha_(0,0) = 1 gt.eq 1 = alpha_(1,0)$? **YES!** → (1,0) is dominated  
- $(0,0) prec (1,1)$: Configuration (0,0) has fewer 1s. Does $alpha_(0,0) = 1 gt.eq 2 = alpha_(1,1)$? **NO!** → (1,1) is NOT dominated
- $(0,1) prec (1,1)$: Does $alpha_(0,1) = 1 gt.eq 2 = alpha_(1,1)$? **NO!**
- $(1,0) prec (1,1)$: Does $alpha_(1,0) = 1 gt.eq 2 = alpha_(1,1)$? **NO!**

*Step 3: Final reduced α-tensor (after filtering)*

#align(center, table(
  columns: (auto, auto, auto, auto),
  table.header(
    table.cell(fill: red.lighten(60%))[*i₁*],
    table.cell(fill: red.lighten(60%))[*i₂*],
    table.cell(fill: red.lighten(60%))[*α̃[i₁,i₂]*],
    table.cell(fill: red.lighten(60%))[*Status*],
  ),
  [0], [0], [*1*], [Relevant (not dominated)],
  [0], [1], [$-infinity$], [Dominated by (0,0)],
  [1], [0], [$-infinity$], [Dominated by (0,0)],
  [1], [1], [*2*], [Relevant (not dominated)],
))

Only *two configurations* remain relevant: (0,0) and (1,1). The others are filtered out because they impose more boundary constraints but achieve no better internal MIS size.

=== The Replacement Condition

#theorem("Gadget Replacement Theorem")[
Two open graphs $P$ and $R'$ can be interchanged if:

$tilde(alpha)(P) = tilde(alpha)(R') + c$

where $c$ is a *constant* (same for all boundary configurations).

This guarantees that replacing $P$ with $R'$ changes the MIS size by exactly $c$, independent of the rest of the graph.
]

#proof("Why Constant Difference?")[
If the difference is *not* constant (varies with boundary configuration), then the MIS change depends on how the gadget connects to the rest of the graph. This makes it impossible to simply "correct" the answer.

With constant difference $c$, we can track the overhead and recover the original solution:

$alpha(G_"mapped") = alpha(G_"original") + c_"total"$
]

#block(
  fill: rgb("#ffe6e6"),
  inset: 1em,
)[
*Important constraint*: The constant difference condition requires that **both gadgets have the same set of relevant configurations**.

*Example of invalid replacement*:

Consider two gadgets with 2 boundary vertices:

#align(center, table(
  columns: (auto, auto, auto, auto),
  table.header(
    [*Config*], [*Gadget A*], [*Gadget B*], [*Valid?*]
  ),
  [(0,0)], [5], [8], [✓ Both relevant],
  [(0,1)], [$-infinity$], [6], [❌ A dominated, B relevant],
  [(1,0)], [$-infinity$], [$-infinity$], [✓ Both dominated],
  [(1,1)], [7], [10], [✓ Both relevant],
))

**Problem with config (0,1)**:
- In gadget A: this configuration is dominated (irrelevant)
- In gadget B: this configuration is relevant (can contribute 6 to MIS)

If the external graph happens to make (0,1) optimal, then:
- Using gadget B: contributes 6
- Using gadget A: $-infinity$ (invalid/infeasible)

*Conclusion*: ❌ **Cannot replace A with B** because they have different sets of relevant configurations.

*Valid replacement requires*: For every configuration $s$,
$ (tilde(alpha)(A)_s = -infinity) arrow.l.r.double (tilde(alpha)(B)_s = -infinity) $
]

= The Complete Mapping Process

== Step 1: Path Decomposition

Find an optimal vertex ordering that minimizes *pathwidth*:

$"pw"(G) = max_i "sep"(i)$

where $"sep"(i)$ is the number of "active" connections to unrevealed vertices.

#block(
  fill: rgb("#f0fff0"),
  inset: 1em,
)[
*Why it matters*: Grid height = pathwidth + 1. Smaller pathwidth → smaller mapped graph.
]

== Step 2: Create Copy Lines

Each vertex in the original graph becomes a *T-shaped copy line* on the grid:

#figure(
  canvas({
    import draw: *
    // T-shape structure
    line((0, 0), (0, -2), stroke: 2pt)  // Vertical
    line((0, -1), (2, -1), stroke: 2pt)  // Horizontal
    // Labels
    content((0.2, 0.3), [vslot])
    content((0.2, -2.3), [vstart])
    content((2.2, -1.3), [hslot])
    content((0.2, -0.7), [vstop])
    content((2.2, -0.7), [hstop])
  }),
  caption: [T-shaped copy line structure]
)

The T-shape allows:
- *Vertical part*: Connect to vertices above/below
- *Horizontal part*: Allow edges to cross

== Step 3: Apply Gadgets

When edges cross or patterns appear that can't be directly embedded:

+ Scan the grid for patterns (crossings, turns, branches)
+ Match patterns against the gadget ruleset
+ Replace with appropriate gadget (BATOIDEA, Turn, Branch, etc.)
+ Record the transformation in `mapping_history`

The key is that each replacement preserves MIS equivalence (via α-tensor matching).

== Step 4: Solve and Map Back

+ Solve MIS on the mapped King's subgraph (quantum computer)
+ Reverse apply each gadget transformation (in reverse order)
+ Extract solution from copy lines
+ Correct for total overhead: $alpha(G) = alpha(G') - "overhead"$

= Complexity Analysis

== Size Complexity

#theorem("Size Bound (Abstract & Main Result)")[
The mapped graph size is:

$|V_"mapped"| = O(|V| times "pw"(G))$

This is *optimal* up to a constant factor under the Exponential Time Hypothesis (ETH).

*Quote from Abstract*:
> "The transformed graph has a size $O(|V| times "pw"(G))$, where $"pw"(G)$ is the pathwidth of $G$. This reduction scheme is optimal up to a constant factor, assuming the exponential time hypothesis is true."
]

#proof("Why This Bound?")[
- Each vertex becomes a copy line of length $O("pw"(G))$ (Section 4)
- $|V|$ vertices total
- Gadget replacements add constant factors (bounded by gadget sizes ≤11)

If we could do better than $O(|V| times "pw"(G))$, we could solve general MIS faster than ETH allows, which is a contradiction.
]

== Time Complexity

+ *Mapping*: Polynomial time (path decomposition, gadget application)
+ *Solving*: Exponential in mapped size, but pathwidth is usually small
+ *Back-mapping*: Polynomial time (reverse gadget applications)

= Key Insights

== Why Reduced α-Tensor Matters

#block(
  fill: rgb("#fff4e6"),
  inset: 1em,
  width: 100%,
)[
1. *Simplifies gadget verification*: By filtering dominated configurations, we only need to check a small subset of relevant boundary scenarios.

2. *Enables constant overhead tracking*: If $tilde(alpha)(B) = tilde(alpha)(A) + c$ (constant for all relevant configs), then replacing $A$ with $B$ always changes MIS by exactly $c$.

3. *Makes back-mapping possible*: We can track the total overhead and correct the final answer.

4. *Not all gadgets satisfy this*: This is a *filtering condition*. The paper uses computer search to find gadgets that satisfy it.
]

== The Computer Search (Algorithm C.1)

The paper performs exhaustive search for valid replacement gadgets (Appendix C, Algorithm C.1):

+ Enumerate all non-isomorphic graphs up to size 11
+ For each graph, try all boundary vertex choices
+ Compute reduced α-tensor using `compute_reduced_alpha_tensor`
+ Check if it differs from target pattern by a constant using `is_diff_by_constant`
+ Check if graph can be embedded in unit disk graph using loss function (Eq. C.1)
+ If both conditions met: valid gadget found!

*Search Infrastructure* (Appendix C):
- Used 72-core AWS EC2 machine
- Searched 1,018,997,864 non-isomorphic graphs at size |V|=11
- Completed in less than one day

*Result* (Figure 6): Found 4 valid gadgets for CROSS pattern, including BATOIDEA (top-right), which is the only one embeddable on square grid.

= Summary

The paper's contribution:

#block(
  fill: rgb("#e6f3ff"),
  inset: 1em,
  width: 100%,
)[
*First polynomial-time reduction from unweighted MIS on arbitrary graphs to unweighted MIS on King's subgraphs, with optimal size bound $O(|V| times "pw"(G))$.*

The key technical tool is the *reduced α-tensor*, which enables:
- Verifying gadget equivalence
- Tracking MIS overhead
- Enabling solution back-mapping
]

#pagebreak()

= Appendix: Common Questions

== Q: Why not use weighted reduction?

Weighted reduction (previous work) requires fine-tuned control of individual atom interactions. Unweighted reduction is simpler for hardware implementation.

== Q: Why must the difference be constant?

If the difference varies with boundary configuration, the MIS change depends on how the gadget connects to the rest of the graph, making it impossible to simply correct the answer.

== Q: How is the reduced α-tensor computed?

Using tropical tensor networks (max-plus semiring), which naturally compute maximum values needed for MIS.

*Implementation* (Algorithm C.1, Appendix C):
- Function: `compute_reduced_alpha_tensor(R', ∂R')`
- Uses generic tensor network methods [16,15]
- First computes α(R) for all boundary configurations
- Then filters out dominated configurations (irrelevant boundary scenarios)

== Q: What if no valid gadget is found?

The search space is finite (graphs up to size 11). If no gadget is found, one could:
- Search larger graphs (computationally expensive)
- Use approximate gadgets (with non-constant overhead, requiring more complex back-mapping)
- Consider different target graph classes

== Q: Are boundary configurations "optional" constraints?

*No! This is a common misunderstanding.*

#block(
  fill: rgb("#ffe6e6"),
  inset: 1em,
)[
❌ *Wrong*: "0 means the vertex *can* be selected or not"

✅ *Correct*: "0 means the vertex *must NOT* be selected"

❌ *Wrong*: "Boundary configurations represent possible choices"

✅ *Correct*: "Boundary configurations represent fixed constraint scenarios"
]

The α-tensor enumerates *all possible* fully-determined boundary scenarios and computes the optimal internal solution for each. It's a lookup table indexed by deterministic constraints, not a representation of "choices to be made."

== Q: Why does "fewer 1s = less restrictive" for the external graph?

Because of the independent set rule:

*If boundary vertex = 1 (forced IN)*:
- All external vertices adjacent to this boundary are **blocked** (cannot be selected)
- This *reduces* the solution space for the external graph

*If boundary vertex = 0 (forced OUT)*:
- External vertices adjacent to this boundary are **free** (can potentially be selected)
- This *expands* the solution space for the external graph

Therefore, a configuration with fewer 1s imposes fewer blocking constraints on external vertices, making it "less restrictive" or "more compatible" with the outside world.

#pagebreak()

= Summary: Key Insights from reduced_alpha_tensor.typ

== 1. Boundary Configurations as Interfaces

The Maximum Independent Set (MIS) problem has a **locality property**: when decomposing a graph into subgraphs, the *only* information that must be exchanged between a subgraph $R$ and the rest of the graph $G without R$ is the selection status of the boundary vertices.

This is formalized by the additive decomposition:

$ max_(s_(partial R)) ( alpha(R)_(s_(partial R)) + alpha(G without R)_(s_(partial R)) ) $

#block(
  fill: rgb("#e6f7ff"),
  inset: 1em,
)[
*Key Property*: Given a fixed boundary configuration, the internal and external subproblems are **independent**. This independence is what makes the dominance argument work.
]

== 2. The Reduced α-Tensor: Filtering Dominated Configurations

#block(
  fill: rgb("#fff4e6"),
  inset: 1em,
)[
The "reduced α-tensor" $tilde(alpha)(R)$ is the α-tensor **after filtering out dominated configurations**:

$ tilde(alpha)(R)_(s) = cases(
  alpha(R)_(s) & "if" s "is relevant (not dominated)",
  -infinity & "if" s "is dominated or infeasible"
) $

A configuration $t$ is dominated if there exists $s prec t$ (fewer 1s) with $alpha(R)_s gt.eq alpha(R)_t$.

**Why?** Dominated configurations can never be optimal in the global MIS, so we filter them out to simplify gadget verification.

**Implementation**: The `mis_compactify!` function applies this filtering.
]

== 3. The Dominance Argument (Critical!)

For configurations $s prec t$ (meaning $s_i lt.eq t_i$ for all $i$):

*If* $alpha(R)_s gt.eq alpha(R)_t$, *then* $t$ is irrelevant because:

1. $alpha(G without R)_s gt.eq alpha(G without R)_t$ (external compatibility)
2. Therefore: $alpha(R)_s + alpha(G without R)_s gt.eq alpha(R)_t + alpha(G without R)_t$
3. Conclusion: $t$ can never be optimal

#warning(title: "Why This Works")[
The dominance argument **crucially relies** on:
1. **Additive decomposition**: $alpha(R) + alpha(G without R)$
2. **Independence**: Given boundary config, inside and outside are independent

Without these properties (e.g., in 3-SAT with global clauses), this argument fails!
]

== 4. Why Constant Difference Matters

For gadget replacement $P arrow.r R'$ to be valid, we need:

$tilde(alpha)(R') = tilde(alpha)(P) + c$

where $c$ is **constant** for all relevant boundary configurations.

#block(
  fill: rgb("#ffe6f0"),
  inset: 1em,
)[
*Why constant?*

- If $c$ varies with boundary configuration, the MIS change depends on how the gadget connects to the rest of the graph
- With constant $c$, we can track total overhead: $alpha(G_"mapped") = alpha(G_"original") + c_"total"$
- This makes back-mapping possible: solve on mapped graph, then correct for the known overhead
]

== 5. Implementation in Code

In the UnitDiskMapping.jl project:

1. *α-tensor computation*: Uses tropical tensor networks (max-plus semiring)
2. *Dominance filtering*: Implemented via `mis_compactify!` and `mapped_entry_to_compact(::Pattern)`
3. *Gadget verification*: Checks constant difference between $tilde(alpha)(P)$ and $tilde(alpha)(R')$

== 6. Connection to Other Problems

*Does this work for other problems?*

✅ **Weighted MIS**: YES - same locality and additivity properties hold

❌ **3-SAT**: NO - clauses can span entire graph, no clean boundary decomposition

✅ **Other local constraint satisfaction**: Possibly - requires locality and additivity

The key is whether the problem has **local constraints** and an **additive objective**.
