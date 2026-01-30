# Note 2: Mathematical Framework - α-Tensor and Problem Formulation
# 数学框架 - α张量与问题形式化

---

## 1. MIS as an Energy Minimization Problem
## 将 MIS 表述为能量最小化问题

### The Energy Function 能量函数

The unweighted MIS problem can be written as minimizing:

```
H_MIS(s) = -∑_{v∈V} s_v + ∑_{(u,v)∈E} U·s_u·s_v
```

**Where**:
- `s_v ∈ {0, 1}` — binary variable for vertex v (选中=1, 未选=0)
- U > 1 (typically U = ∞) — penalty for violating independence constraint

**Intuition** 直觉理解:
- First term: Reward for selecting more vertices (选更多点得更多奖励)
- Second term: Heavy penalty when two connected vertices are both selected (选相邻点受重罚)
- Minimizing this energy = Finding maximum independent set

### Weighted Version (MWIS) 加权版本

For Maximum Weight Independent Set:
```
H_MWIS(s) = -∑_{v∈V} δ_v·s_v + ∑_{(u,v)∈E} U·s_u·s_v
```
Where δ_v is the weight of vertex v.

---

## 2. Open Graphs and Boundary Vertices
## 开图与边界顶点

### Definition 定义

An **open graph** (开图) is a triple R = (V, E, ∂R) where:
- (V, E) is a standard graph
- ∂R ⊆ V is the set of **boundary vertices** (边界顶点)
- V \ ∂R are called **bulk vertices** (内部顶点) or **ancillas** (辅助顶点)

```
Visual example:
   
   ●───●───●     ← Boundary vertices (pins/边界点/引脚)
   │   │   │
   ○───○───○     ← Bulk vertices (ancillas/辅助顶点)
   │   │   │
   ●───●───●     ← Boundary vertices
```

**Why open graphs?**
- Gadgets need to connect to the rest of the circuit
- Boundary vertices are the "interface" (接口)
- When replacing patterns, boundary must match (边界必须匹配)

**Code Connection** 代码关联:
```julia
# From src/gadgets.jl - source_graph returns (locations, graph, pins)
# The 'pins' are the boundary vertices
function source_graph(::Cross{true})
    locs = Node.([(2,1), (2,2), (2,3), (1,2), (2,2), (3,2)])
    g = simplegraph([(1,2), (2,3), (4,5), (5,6), (1,6)])
    return locs, g, [1,4,6,3]  # [1,4,6,3] are the boundary/pin vertices
end
```

---

## 3. The α-Tensor Framework
## α 张量框架

### What is α-Tensor? 什么是α张量？

The **α-tensor** (α张量) encodes all possible MIS configurations on an open graph's boundary.

**Formal Definition**:
For an open graph R = (V, E, ∂R) with |∂R| = k boundary vertices:

```
α(R)[i₁, i₂, ..., iₖ] = max{ |S| : S is an independent set of R 
                              where s_{∂R_j} = iⱼ for j=1,...,k }
```

**In plain words**: 
Given a fixed configuration on the boundary, what's the maximum number of vertices we can add to form an independent set?

### Example 示例

Consider this simple gadget:
```
    1 (boundary)
    │
    ○ (ancilla)
    │
    2 (boundary)
```

The α-tensor is a 2×2 matrix (since 2 boundary vertices, each can be 0 or 1):

| i₁ (vertex 1) | i₂ (vertex 2) | α[i₁,i₂] | Explanation |
|---------------|---------------|----------|-------------|
| 0 | 0 | 1 | Neither boundary selected → ancilla can be selected |
| 0 | 1 | 1 | Only v2 selected → ancilla blocked (can't be selected) |
| 1 | 0 | 1 | Only v1 selected → ancilla blocked |
| 1 | 1 | 0 | Both selected → but they're connected through ancilla! Infeasible |

Wait, they're not directly connected, let me reconsider... Actually v1-ancilla-v2 is a path, so:
- If v1=1: ancilla must be 0
- If v2=1: ancilla must be 0  
- So α[1,1] = 2 (both v1 and v2 selected, ancilla=0)

This shows how α-tensor captures the internal structure's effect on boundary configurations.

### Reduced α-Tensor (约化 α 张量)

The **reduced α-tensor** (α̃) removes the boundary contribution:

```
α̃(R)[i₁,...,iₖ] = α(R)[i₁,...,iₖ] - ∑ⱼ iⱼ
```

**Why reduced?** 
When comparing two gadgets, we care about the "internal overhead", not the boundary vertices themselves.

---

## 4. The Replacement Theorem
## 替换定理 (核心定理)

### Theorem 3.7 (Most Important!) 定理3.7 (最重要!)

Two open graphs P and R' can be **interchanged** (相互替换) in a graph rewrite if:

```
α̃(P) = α̃(R') + c
```

Where c is a **constant** (常数) — meaning every entry differs by the same amount.

**What this means** 这意味着什么:
- If we replace pattern P with pattern R' in a graph
- The MIS size changes by exactly c (independent of what the rest of the graph looks like)
- We can track this overhead and recover the original solution!

### Key Insight 关键洞见

This theorem is the **foundation of the entire gadget framework**:
1. Design a gadget R' that:
   - Has the same boundary vertices as the pattern P
   - Has a reduced α-tensor differing by a constant from P
   - Can be embedded in a unit disk graph (可嵌入单位圆盘图)
2. Replace all instances of P with R'
3. Solve MIS on the new graph
4. Map solution back using the recorded transformations

**Code Connection** 代码关联:
```julia
# From src/extracting_results.jl - the mapping dictionaries encode α-tensor info
function mapped_entry_to_compact(::Cross{false})
    # Maps boundary configuration → "compact" representative
    return Dict([5 => 4, 12 => 4, 8 => 0, ...])
end

function source_entry_to_configs(::Cross{false})
    # Maps compact rep → possible internal configurations
    return Dict(Pair{Int64, Vector{BitVector}}[5 => [...], ...])
end
```

---

## 5. Understanding the α-Tensor Implementation
## 理解 α 张量的实现

### How is α-tensor computed? 如何计算α张量?

The paper mentions using **tropical tensor networks** (热带张量网络) to compute α-tensors efficiently.

**Basic idea**:
1. Each vertex contributes a tensor
2. Each edge contributes a constraint (no adjacent 1s)
3. Contract the network to get the α-tensor

**Tropical semiring** (热带半环):
- Instead of (×, +), use (max, +)
- This naturally finds maximum values (perfect for MIS!)

```julia
# From src/utils.jl - simplified version of independence check
# The actual α-tensor computation uses GenericTensorNetworks.jl
```

### Connection to Code 与代码的联系

In practice, the α-tensors are pre-computed for each gadget type:
```julia
# From src/extracting_results.jl
# These dictionaries store the pre-computed mapping information
# mis_overhead gives the constant 'c' in Theorem 3.7
mis_overhead(::Turn) = -1  # The Turn gadget reduces MIS by 1
mis_overhead(::Branch) = -1  # The Branch gadget reduces MIS by 1
mis_overhead(::TrivialTurn) = 0  # No change in MIS
```

---

## 6. Graph Rewriting Formalism
## 图重写形式化

### The Replacement Rule 替换规则

A **replacement rule** is written as (P, R) where:
- P = pattern to match (待匹配模式)
- R = replacement graph (替换图)

### Conditions for Valid Replacement 有效替换的条件

1. **Same boundary**: ∂P = ∂R (相同边界)
2. **α-tensor compatibility**: α̃(P) = α̃(R) + c for some constant c
3. **Geometric realizability**: R is embeddable in target graph class (R可嵌入目标图类)

### The Compose Operation (⊗) 组合操作

When two open graphs G and R share boundary vertices, they can be composed:
```
G ⊗ R = "glue" G and R along shared boundary
```

**Key property**:
```
α(G ⊗ R) = max over all boundary configs of [α(G) + α̃(R)]
```

This is why reduced α-tensor matters — it tells us how much the internal structure adds.

---

## 7. Summary: The Mathematical Pipeline
## 总结：数学流程

```
Original Graph G
       │
       ▼
Compute Path Decomposition (计算路径分解)
       │
       ▼
Create Copy Lines (创建复制线)
       │
       ▼
Apply Crossing Gadgets where edges exist (在边处应用交叉组件)
       │
       ▼
Apply Simplification Rules (应用简化规则)
       │
       ▼
Result: King's Subgraph with α(G_mapped) = α(G) + overhead
       │
       ▼
Solve MIS on mapped graph (解决映射图上的MIS)
       │
       ▼
Map configuration back using α-tensor info (用α张量信息映射回原图)
       │
       ▼
Original MIS Solution!
```

---

## Key Formulas to Remember 需要记住的关键公式

1. **Energy function**: H(s) = -∑ sᵥ + U ∑ sᵤsᵥ
2. **Reduced α-tensor**: α̃(R) = α(R) - ∑ boundary contributions
3. **Replacement condition**: α̃(P) = α̃(R') + c
4. **Size complexity**: O(|V| × pw(G))

---

## Next Note: The Gadget Framework in Detail




