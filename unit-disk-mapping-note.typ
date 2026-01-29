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
  title: [Preparing for further research is better],
  show-outline: true,
  show-solutions: false,
  author: "Notes by Student",
  task-type: "Research Notes",
)

#show: thmrules

#show raw.where(lang:"julia"): it=>{
  par(justify:false,block(fill:rgb("#f0f0ff"),inset:1.5em,width:99%,text(it)))
}

#pagebreak()

= Problem Statement

The core challenge addressed in this paper is:

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

= The α-Tensor Framework

== What is an α-Tensor?

An *α-tensor* is a lookup table that encodes MIS information for an *open graph* (a graph with designated boundary vertices).

#definition("α-Tensor Definition")[
For an open graph $R = (V, E, partial R)$ with $|partial R| = k$ boundary vertices, the α-tensor is:

$alpha(R)[i_1, i_2, ..., i_k] = max { |S| : S "is an independent set of" R "where" s_(partial R_j) = i_j "for" j=1,...,k }$

In words: Given a fixed configuration on the boundary, what's the maximum number of vertices we can add to form an independent set?
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
  [0], [0], [1], [Neither selected → internal can be selected],
  [0], [1], [1], [Only b2 selected → internal blocked],
  [1], [0], [1], [Only b1 selected → internal blocked],
  [1], [1], [2], [Both selected → internal blocked, total = 2],
))

== The Reduced α-Tensor (重点)

#warning(title: "Key Concept: Reduced α-Tensor")[
The *reduced α-tensor* removes the boundary contribution:

$tilde(alpha)(R)[i_1, ..., i_k] = alpha(R)[i_1, ..., i_k] - sum_j i_j$

This isolates the gadget's *internal* contribution, excluding the boundary vertices themselves.
]

=== Why Reduce?

When comparing two gadgets $A$ and $B$ for replacement:

#block(
  fill: rgb("#e6f3ff"),
  inset: 1em,
)[
*The boundary vertices are the same* (they must match for replacement to work).

We only care about the *difference in internal structure*.

By subtracting the boundary contribution, we can directly compare the internal overhead.
]

=== Example: Reduced α-Tensor

For the simple gadget above:

#align(center, table(
  columns: (auto, auto, auto, auto, auto),
  table.header(
    table.cell(fill: green.lighten(60%))[*i₁*],
    table.cell(fill: green.lighten(60%))[*i₂*],
    table.cell(fill: green.lighten(60%))[*α[i₁,i₂]*],
    table.cell(fill: green.lighten(60%))[*i₁ + i₂*],
    table.cell(fill: green.lighten(60%))[*α̃ = α - (i₁+i₂)*],
  ),
  [0], [0], [1], [0], [*1*],
  [0], [1], [1], [1], [*0*],
  [1], [0], [1], [1], [*0*],
  [1], [1], [2], [2], [*0*],
))

The reduced α-tensor shows:
- When boundaries are empty (0,0): internal contributes 1
- When any boundary is selected: internal contributes 0 (blocked)

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

$alpha(G_"mapped") = alpha(G_"original") + "total overhead"$
]

= The Complete Mapping Process

== Step 1: Path Decomposition

Find an optimal vertex ordering that minimizes *pathwidth*:

$"pathwidth" = max_i "sep"(i)$

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

#theorem("Size Bound")[
The mapped graph size is:

$|V_"mapped"| = O(|V| times "pw"(G))$

This is *optimal* under the Exponential Time Hypothesis (ETH).
]

#proof("Why This Bound?")[
- Each vertex becomes a copy line of length $O("pw"(G))$
- $|V|$ vertices total
- Gadget replacements add constant factors

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
1. *Isolates internal contribution*: When comparing gadgets, boundaries are the same, so we only care about internal differences.

2. *Enables constant overhead tracking*: If $tilde(alpha)(B) = tilde(alpha)(A) + c$ (constant), then replacing $A$ with $B$ always changes MIS by exactly $c$.

3. *Makes back-mapping possible*: We can track the total overhead and correct the final answer.

4. *Not all gadgets satisfy this*: This is a *filtering condition*. The paper uses computer search to find gadgets that satisfy it.
]

== The Computer Search

The paper searches for valid replacement gadgets:

+ Enumerate all non-isomorphic graphs up to size 11
+ For each graph, try all boundary vertex choices
+ Compute reduced α-tensor
+ Check if it differs from target pattern by a constant
+ Check if graph can be embedded in unit disk graph
+ If both conditions met: valid gadget found!

Result: Found 4 valid gadgets for CROSS pattern, including BATOIDEA (embeddable on square grid).

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

== Q: What if no valid gadget is found?

The search space is finite (graphs up to size 11). If no gadget is found, one could:
- Search larger graphs (computationally expensive)
- Use approximate gadgets (with non-constant overhead, requiring more complex back-mapping)
- Consider different target graph classes
