#import "@preview/cetz:0.4.1": canvas, draw
#import "@preview/ctheorems:1.1.3": thmbox, thmrules

#show: thmrules

#let theorem = thmbox("theorem", "Theorem", fill: rgb("#eeffee"))
#let lemma = thmbox("lemma", "Lemma", fill: rgb("#e6f3ff"))
#let definition = thmbox("definition", "Definition", fill: rgb("#fff4e6"))
#let proof = thmbox("proof", "Proof", fill: rgb("#f5f5f5"), stroke: none).with(numbering: none)

#set page(margin: 2cm)
#set text(size: 11pt)

= On the Necessity of Reduced α-Tensor for Gadget Verification

#block(
  fill: rgb("#f0f8ff"),
  inset: 1em,
)[
*Reference*: Liu et al. (2023), "Computer-assisted gadget design and problem reduction of unweighted maximum independent set"
]

== Problem Setup

Let $G = (V, E)$ be a graph and $P = (V_P, E_P, partial P)$ be an open subgraph with boundary $partial P subset V_P$. We seek a replacement graph $R' = (V_(R'), E_(R'), partial R')$ such that $partial P = partial R'$ and $P$ and $R'$ are *interchangeable* in any graph containing $P$.

#definition("Interchangeability")[
Two open graphs $P$ and $R'$ with $partial P = partial R'$ are *interchangeable* if for any graph $G$ containing $P$:

$alpha(G) = alpha(G[R' / P]) + c$

where $G[R' / P]$ denotes $G$ with $P$ replaced by $R'$, and $c in ZZ$ is a constant independent of $G$.
]

== The α-Tensor and Reduced α-Tensor

#definition("α-Tensor")[
For an open graph $R = (V_R, E_R, partial R)$ with $|partial R| = k$, the α-tensor $alpha(R): {0,1}^k arrow.r RR union {-infinity}$ is defined as:

$alpha(R)[s] = max { |S| : S "is an independent set of" R "subject to boundary constraints" }$

where $s in {0,1}^k$ encodes boundary constraints: $s_i = 1$ forces boundary vertex $i$ to be in $S$, $s_i = 0$ forces it out.
]

#definition("Dominance Relation")[
For boundary configurations $s, t in {0,1}^k$, we say $s prec t$ (read: $s$ is less restrictive than $t$) if $s_i lt.eq t_i$ for all $i in {1, ..., k}$.

Configuration $t$ is *dominated* by $s$ if $s prec t$ and $alpha(R)_s gt.eq alpha(R)_t$.
]

🔍 *Why $s_i = 1$ is a strong constraint and $s_i = 0$ is a weak constraint*:

Recall that an independent set is a vertex set where no two vertices are adjacent.

- *When $s_i = 1$* (forcing vertex $i$ to be in $S$): This directly triggers a chain reaction: all vertices adjacent to vertex $i$ must be excluded from $S$, otherwise the independent set property would be violated. This constraint not only restricts vertex $i$ itself but also limits all its neighbors, imposing stricter restrictions on the independent set formation.

- *When $s_i = 0$* (forcing vertex $i$ to be out of $S$): This only constrains vertex $i$ itself and does not impose any mandatory restrictions on its neighbors. The neighbors can freely choose whether to join $S$ (as long as other constraints are satisfied), making this a more relaxed constraint on the independent set.

This asymmetry explains why $s prec t$ when $s_i lt.eq t_i$: configurations with more $1$s (strong constraints) are more restrictive than those with more $0$s (weak constraints).

#definition("Reduced α-Tensor")[
The reduced α-tensor $tilde(alpha)(R): {0,1}^k arrow.r RR union {-infinity}$ is:

$tilde(alpha)(R)[s] = cases(
  alpha(R)[s] & "if" s "is relevant (not dominated)",
  -infinity & "if" s "is dominated or infeasible"
)$

where $s$ is *relevant* if there exists no $s' prec s$ with $alpha(R)_(s') gt.eq alpha(R)_s$.
]

== Two Verification Conditions

#lemma("Lemma 3.3 (Sufficient Condition)")[
If two open graphs $P$ and $R'$ with $partial P = partial R'$ satisfy:

$alpha(P)[s] = alpha(R')[s] + c quad "for all feasible" s in {0,1}^k "with" alpha(P)[s] != -infinity$

for *the same* constant $c in ZZ$ (independent of $s$), then $P$ and $R'$ are interchangeable in any graph $G$ containing $P$.
]

#theorem("Theorem 3.7 (Necessary and Sufficient Condition)")[
Two open graphs $P$ and $R'$ with $partial P = partial R'$ are interchangeable in *any* graph $G$ containing $P$ *if and only if*:

$tilde(alpha)(P)[s] = tilde(alpha)(R')[s] + c quad "for all" s in {0,1}^k$

for *the same* constant $c in ZZ$ (independent of $s$).
]

== Why Reduced α-Tensor is Necessary

=== 1. Logical Completeness: "If" versus "If and Only If"

The critical difference lies in logical strength:

- *Lemma 3.3*: $alpha(P) = alpha(R') + c$ (for feasible $s$) $arrow.r.double$ interchangeability
- *Theorem 3.7*: $tilde(alpha)(P) = tilde(alpha)(R') + c$ $arrow.l.r.double$ interchangeability

The "if and only if" ($arrow.l.r.double$) in Theorem 3.7 provides:
1. *Sufficiency* ($arrow.r.double$): If the condition holds, gadgets are interchangeable
2. *Necessity* ($arrow.l.double$): If gadgets are interchangeable, the condition must hold

This completeness is essential for gadget search: we can *characterize* all valid replacements, not just find some.

=== 2. Why Lemma 3.3 is Too Strong (False Negatives)

#proof("Lemma 3.3 Rejects Valid Gadgets")[
Consider configurations $s prec t$ where:
- $s$ is relevant: there exists no $s' prec s$ with $alpha(P)_(s') gt.eq alpha(P)_s$
- $t$ is dominated: $alpha(P)_s gt.eq alpha(P)_t$ and $s prec t$

By the dominance argument, for any graph $G$:

$alpha(P)_s + alpha(G without P)_s gt.eq alpha(P)_t + alpha(G without P)_t$

Therefore, $t$ is never optimal in global MIS, and $alpha(P)_t$ and $alpha(R')_t$ are irrelevant.

If:
- $alpha(P)_s = alpha(R')_s + c$ for all relevant $s$ with *the same* constant $c$ (satisfies Theorem 3.7)
- but $alpha(P)_t != alpha(R')_t + c$ for some dominated $t$ using *the same* $c$ (violates Lemma 3.3)

Then Lemma 3.3 incorrectly rejects a valid gadget.
]

*Concrete Example*: Let $P$ and $R'$ have boundary ${b_1, b_2}$:

#align(center, table(
  columns: (auto, auto, auto, auto),
  table.header([*Config*], [*$alpha(P)$*], [*$alpha(R')$*], [*Difference*]),
  [(0,0)], [2], [1], [+1],
  [(0,1)], [1], [1], [0],
  [(1,0)], [1], [1], [0],
  [(1,1)], [1], [1], [0],
))

Here $(0,1)$, $(1,0)$, $(1,1)$ are dominated by $(0,0)$. Lemma 3.3 rejects because differences are not *the same constant* across all configurations. Theorem 3.7 accepts because:

$tilde(alpha)(P)[(0,0)] = 2$, $tilde(alpha)(R')[(0,0)] = 1$ → difference = +1 (using the same constant $c = +1$) ✓

$tilde(alpha)(P)[t] = -infinity$, $tilde(alpha)(R')[t] = -infinity$ for dominated $t$ → both $-infinity$ (consistent with the same $c$) ✓

=== 3. Why Unreduced α-Tensor is Too Weak

Using $alpha(P)[s] = alpha(R')[s] + c$ for *all* $s$ (including infeasible) is ill-defined:

- Infeasible configs: $alpha(P)[s] = alpha(R')[s] = -infinity$
- The equation "$-infinity = -infinity + c$" has no well-defined constant $c in ZZ$

The reduced α-tensor handles this by explicitly setting infeasible and dominated configs to $-infinity$ before comparison.

=== 4. Formal Proof: Theorem 3.7 is Tight

#proof("Forward Direction ($arrow.r.double$)")[
If $tilde(alpha)(P) = tilde(alpha)(R') + c$ for *the same* constant $c$ (independent of $s$), then for any $G$:

$alpha(G) &= max_(s in {0,1}^k) (alpha(P)_s + alpha(G without P)_s) \
  &= max_(s "relevant") (alpha(P)_s + alpha(G without P)_s) quad &"(dominated" s "never optimal)" \
  &= max_(s "relevant") (tilde(alpha)(P)_s + alpha(G without P)_s) \
  &= max_(s "relevant") (tilde(alpha)(R')_s + c + alpha(G without P)_s) \
  &= max_(s in {0,1}^k) (alpha(R')_s + alpha(G without R')_s) + c \
  &= alpha(G[R' / P]) + c$
]

#proof("Reverse Direction ($arrow.l.double$)")[
Assume $P$ and $R'$ are interchangeable in *any* graph $G$ containing $P$, i.e., there exists a constant $c in ZZ$ such that:

$alpha(G) = alpha(G[R' / P]) + c$

for all graphs $G$ containing $P$.

For each relevant configuration $s in {0,1}^k$, construct $G_s$ that forces $s$ to be optimal (attach large cliques/independent sets to boundary vertices). Since $s$ is optimal in $G_s$:

$alpha(G_s) = alpha(P)_s + alpha(G_s without P)_s$

After replacing $P$ with $R'$:

$alpha(G_s[R' / P]) = alpha(R')_s + alpha(G_s without P)_s$

By interchangeability: $alpha(G_s) = alpha(G_s[R' / P]) + c$. Substituting and canceling $alpha(G_s without P)_s$:

$alpha(P)_s = alpha(R')_s + c$

Since $s$ is relevant, $tilde(alpha)(P)_s = alpha(P)_s$ and $tilde(alpha)(R')_s = alpha(R')_s$, so:

$tilde(alpha)(P)_s = tilde(alpha)(R')_s + c$

The constant $c$ is fixed for $(P, R')$ by interchangeability, hence the *same* for all relevant $s$.

For dominated configurations $t$, both sides equal $-infinity$ by definition, so the equation holds trivially.

*Conclusion*

We have shown that $tilde(alpha)(P)_s = tilde(alpha)(R')_s + c$ for all $s in {0,1}^k$ with *the same* constant $c$ (independent of $s$), completing the reverse direction.
]

Therefore, Theorem 3.7 is *tight*: it characterizes exactly the set of valid gadget replacements.

== Condition Strength Analysis

#align(center, table(
  columns: (1.2fr, 0.8fr, 1.5fr),
  table.header(
    [*Condition*],
    [*Strength*],
    [*Consequence*]
  ),
  [
    $alpha(P)[s] = alpha(R')[s] + c$ for all feasible $s in {0,1}^k$
  ],
  [Too strong],
  [
    False negatives: rejects valid gadgets by requiring *the same* constant difference on dominated configs that never appear in optimal solutions
  ],
  [
    $alpha(P)[s] = alpha(R')[s] + c$ for all $s$ (including infeasible)
  ],
  [Too weak/ill-defined],
  [
    Meaningless: "$-infinity = -infinity + c$" has no well-defined constant $c$
  ],
  [
    $tilde(alpha)(P)[s] = tilde(alpha)(R')[s] + c$ for all $s in {0,1}^k$
  ],
  [Necessary & sufficient],
  [
    Correct: considers only relevant configs via dominance filtering; provides tight characterization
  ],
))

== Summary

The reduced α-tensor $tilde(alpha)$ with dominance filtering is *necessary* for gadget verification because:

1. *Logical completeness*: Theorem 3.7 provides "if and only if" characterization, enabling complete gadget search
2. *Eliminates false negatives*: Lemma 3.3's requirement on dominated configs incorrectly rejects valid gadgets
3. *Handles infeasibility*: Explicit $-infinity$ assignment avoids ill-defined arithmetic
4. *Computational efficiency*: Only relevant configurations need verification, reducing from $2^k$ to typically $O(1)$-$O(k)$ checks

The condition $tilde(alpha)(P) = tilde(alpha)(R') + c$ (with *the same* constant $c$ for all configurations $s$) is both *necessary* and *sufficient* for gadget interchangeability, making it the correct criterion for computer-assisted gadget search (Algorithm C.1).

