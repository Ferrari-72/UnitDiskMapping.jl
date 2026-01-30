= Unweighted Gadget Search

== 1. Why boundary configurations matter

The Maximum Independent Set (MIS) problem has a crucial locality property:
any induced subgraph of a graph defines a valid MIS subproblem.
As a result, when a graph is decomposed into subgraphs, the only information
that must be exchanged between a subgraph and the rest of the graph is the
selection status of the *boundary vertices*.

In other words, boundary configurations serve as the interface between a
local subproblem and the global MIS problem.
Understanding how the MIS inside a subgraph depends on its boundary
configuration is the key to constructing valid MIS-preserving rewrite rules.

> [Think] Do other problems have this property? What about the weighted MIS problem or the 3-SAT problem?

== 2. Subproblem independence and dominance

The intuition about boundary configurations can be made more explicit by spelling out the optimization structure of the MIS problem.

Once a boundary configuration $s_(diff R)$ is fixed, the MIS problem decomposes cleanly into two independent subproblems:

- Inside the subgraph $R$, one only needs to maximize the number of selected vertices that are compatible with $s_(diff R)$.
- Outside the subgraph, i.e., on $G without R$, the only relevant information is which boundary vertices are selected; the internal choices inside $R$ do not matter.

As a consequence, the global MIS objective can be written as

$ max_(s_(diff R)) ( alpha(R)_(s_(diff R)) + alpha(G without R)_(s_(diff R)) ) $

This additive decomposition is the foundation of all subsequent arguments.

Now suppose there exist two boundary configurations $s$ and $t$ such that $s prec t$ and $alpha(R)_s gt.eq alpha(R)_t$.

Because $s$ imposes weaker constraints on the outside graph, it follows for any external subgraph that

$ alpha(G without R)_s gt.eq alpha(G without R)_t $

Combining the two inequalities yields

$ alpha(R)_s + alpha(G without R)_s gt.eq alpha(R)_t + alpha(G without R)_t $

Therefore, the boundary configuration $t$ can never be optimal in the global MIS optimization. It is strictly dominated by $s$ in terms of both internal payoff and external compatibility.

Crucially, this dominance argument relies on the additive and independent structure of the MIS subproblems; without such independence, the comparison would no longer be valid.

The following content is largely consistent with the original paper.

== 3. What is an α-tensor?

Let $R$ be a subgraph and let $diff R$ denote its boundary vertices.
A boundary configuration is a binary vector
$s_(diff R) in {0,1}^(|diff R|)$, where $1$ indicates that a boundary vertex
is forced to belong to the independent set.

The *α-tensor* of $R$, denoted by $alpha(R)$, is defined as follows:

- Each tensor index corresponds to one fixed boundary configuration $s_(diff R)$.
- The tensor entry $alpha(R)_(s_(diff R))$ is the size of the *largest independent set
  inside $R$* that is consistent with the boundary configuration $s_(diff R)$.
- If the boundary configuration itself violates the independent set constraint
  (for example, two adjacent boundary vertices are both set to $1$),
  the corresponding entry is set to $-infinity$.

Informally, the α-tensor answers the question:

> If the outside graph fixes the boundary vertices according to $s_(diff R)$, what is the maximum number of vertices we can still select inside $R$?

== 4. Less restrictive boundary configurations

Given two boundary configurations $s, t in {0,1}^(|diff R|)$, we say that
$s$ is *less restrictive* than $t$, written $s prec t$, if
$s_i lt.eq t_i$ for all boundary vertices $i$.

A less restrictive configuration forces fewer boundary vertices to be
included in the independent set and is therefore compatible with at least
as many global solutions.


== 5. Irrelevant boundary configurations

A boundary configuration $t$ is called *irrelevant* if:

- $alpha(R)_t = -infinity$ (the configuration is infeasible), or
- There exists a less restrictive configuration $s prec t$ such that $alpha(R)_s gt.eq alpha(R)_t$ (dominated by the argument in Section 2).

Such configurations can be safely ignored.


== 6. What is the reduced $alpha$-tensor?

The *reduced $alpha$-tensor* of $R$, denoted by $tilde(alpha)(R)$, is obtained from $alpha(R)$ by:

- Keeping the same boundary configuration index set.
- Setting all entries corresponding to irrelevant boundary configurations
  to $-infinity$.

Formally,

$ tilde(alpha)(R)_(s_(diff R)) = cases(
  alpha(R)_(s_(diff R)) & "if" s_(diff R) "is relevant",
  -infinity & "otherwise"
) $

The reduced $alpha$-tensor acts as a *dominance filter*: it preserves the full boundary structure while discarding dominated configurations that can never appear in a global maximum independent set.

== 7. Tasks for this week

#rect[1. Why do we need to use the reduced $alpha$-tensor to verify the gadget?]
    - What's the difference between Lemma 3.3 and Theorem 3.7 (how to understand the "if and only if" in Theorem 3.7)? 
    - Can you analyze which conditions are overly strong and which are too weak, and explain the consequences of each?
    - Write a note to explain your understanding. Try to use more math language and less natural language.
#rect[2. Use a script to verify the gadget in the original paper.]
    - You can look at this test file in the repository: https://github.com/QuEraComputing/UnitDiskMapping.jl/blob/main/test/gadgets.jl
    - Try to understand every line of the first test set in this test file. You don't need to look at the details of how to compute the $alpha$-tensor; first, try to use it.
    - Summarize your results in the note.

____

