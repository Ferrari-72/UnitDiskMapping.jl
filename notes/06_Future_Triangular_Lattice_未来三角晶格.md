# Note 6: Future Directions - Triangular Lattice Unweighted MIS Reduction
# 未来方向 - 三角晶格无权MIS归约

---

## 1. Why Triangular Lattice? 为什么研究三角晶格？

### Current Paper: King's Graph (Square Grid) 当前论文：国王图（方格）

```
King's Graph connectivity:
● ● ●
● K ●    Each vertex connects to 8 neighbors
● ● ●    (4 orthogonal + 4 diagonal)
```

### Triangular Lattice 三角晶格

```
Triangular Lattice connectivity:
    ●   ●   ●
   / \ / \ / \
  ●   ●   ●   ●     Each vertex connects to 6 neighbors
   \ / \ / \ /
    ●   ●   ●
```

### Motivation 动机

1. **Different hardware**: Some quantum systems naturally form triangular arrangements
2. **Different connectivity**: 6-neighbor vs 8-neighbor changes gadget design
3. **Potentially tighter packing**: Triangular grids can be more efficient for some problems
4. **Theoretical interest**: Understanding what graph structures support efficient reduction

---

## 2. Key Challenges for Triangular Lattice 三角晶格的关键挑战

### Challenge 1: Different Crossing Geometry 不同的交叉几何

In King's graph:
```
Paths can cross at 90° angles
      |
   ---+---
      |
```

In triangular lattice:
```
Paths must cross at 60° or 120° angles
      /
   --+
      \
```

**This means**: The BATOIDEA gadget (designed for square grid) won't work!

### Challenge 2: New Gadget Search Space 新的组件搜索空间

For King's graph, the paper searched graphs up to 11 vertices and found 4 valid crossing gadgets.

For triangular lattice:
- Different unit disk geometry
- Different neighbor structure
- Need to re-run exhaustive search

### Challenge 3: Copy Line Structure 复制线结构

The T-shaped copy lines rely on:
- Horizontal lines (0° direction)
- Vertical lines (90° direction)
- 45° diagonal connections

For triangular:
- Need to work with 60° angles
- Copy lines might be "bent" differently

---

## 3. Research Plan 研究计划

### Phase 1: Understand the Unit Disk Constraint 理解单位圆盘约束

**Question**: What is the unit disk graph on a triangular lattice?

**Task**:
1. Define triangular lattice coordinates
2. Determine which vertices are within unit distance
3. Visualize the connectivity pattern

```julia
# Proposed code for triangular unit disk graph
function triangular_unit_disk_graph(locs::AbstractVector{Tuple{Float64,Float64}}, radius::Real)
    # Similar to unit_disk_graph, but locs are on triangular lattice
    g = SimpleGraph(length(locs))
    for i = 1:length(locs)
        for j = i+1:length(locs)
            if euclidean_distance(locs[i], locs[j]) <= radius
                add_edge!(g, i, j)
            end
        end
    end
    return g
end

# Triangular lattice coordinates:
# Row 0: (0,0), (1,0), (2,0), ...
# Row 1: (0.5, √3/2), (1.5, √3/2), ...
# Row 2: (0, √3), (1, √3), ...
```

### Phase 2: Find Crossing Gadgets 寻找交叉组件

**Method**: Adapt Algorithm C.1 from the paper

```
For each graph size n (start small, n=5,6,7,...):
    For each non-isomorphic graph G of size n:
        For each choice of 4 boundary vertices:
            R' = (G, boundary)
            
            If has_triangular_embedding(R'):  # NEW: triangular instead of square
                Compute α̃(R')
                If α̃(R') differs from α̃(CROSS) by constant:
                    FOUND! Record R'
```

**Key function to implement**:
```julia
function has_triangular_embedding(graph, boundary_vertices)
    # Variational optimization with triangular lattice constraint
    # Similar to has_unit_disk_embedding but on triangular grid
end
```

### Phase 3: Design Copy Lines 设计复制线

**Questions to answer**:
1. What is the triangular analogue of the T-shaped copy line?
2. How do branches work on 60° angles?
3. What's the spacing between copy lines?

**Possible approach**: "Y-shaped" or "Mercedes" copy lines
```
    /
   /
  ●
   \
    \
```

### Phase 4: Implement Full Pipeline 实现完整流程

1. New `TriangularMappingGrid` type
2. Triangular copy line generation
3. New gadget ruleset for triangular
4. Back-mapping functions

---

## 4. Code Modification Strategy 代码修改策略

### Option A: Extend Existing Code 扩展现有代码

```julia
# Add to src/Core.jl
abstract type LatticeType end
struct SquareLattice <: LatticeType end
struct TriangularLattice <: LatticeType end

# Parameterize functions by lattice type
function unitdisk_graph(locs, radius, ::SquareLattice)
    # Current implementation
end

function unitdisk_graph(locs, radius, ::TriangularLattice)
    # New triangular implementation
end
```

### Option B: Create Parallel Module 创建并行模块

```
src/
├── UnitDiskMapping.jl          (keep as is)
├── triangular/
│   ├── TriangularMapping.jl    (new main module)
│   ├── triangular_core.jl      (triangular types)
│   ├── triangular_gadgets.jl   (new gadgets)
│   └── triangular_mapping.jl   (mapping algorithm)
```

### Recommended Approach 推荐方法

**Start with Option B** (parallel module):
- Doesn't break existing code
- Easier to experiment
- Can later refactor to Option A if patterns emerge

---

## 5. Specific Tasks for You 具体任务

### Task 1: Study Unit Disk Geometry 研究单位圆盘几何

```julia
# Experiment: Visualize triangular lattice unit disk connections
using Plots

function triangular_lattice(rows, cols)
    locs = Tuple{Float64, Float64}[]
    for r in 0:rows-1
        for c in 0:cols-1
            x = c + (r % 2) * 0.5
            y = r * sqrt(3)/2
            push!(locs, (x, y))
        end
    end
    return locs
end

# Plot and check connectivity
locs = triangular_lattice(5, 5)
# What radius gives 6-connectivity?
```

### Task 2: Understand CROSS Pattern 理解CROSS模式

Study why CROSS (the pattern) has these specific properties:
- 4 boundary vertices
- Paths must cross geometrically
- Why is the α-tensor symmetric under 1↔3, 2↔4?

**Read carefully**: Appendix C.1 (Crossing Criteria)

### Task 3: Small Gadget Enumeration 小组件枚举

Start with small graphs (n=5,6,7) and manually check:
1. Can they embed on triangular lattice?
2. Do they satisfy crossing criteria?
3. What's their α-tensor?

### Task 4: Implement Basic Infrastructure 实现基础设施

```julia
# File: src/triangular/triangular_core.jl

struct TriangularNode
    q::Int  # "row" in triangular coords
    r::Int  # "column" in triangular coords
end

# Convert to Cartesian
function to_cartesian(n::TriangularNode)
    x = n.r + n.q * 0.5
    y = n.q * sqrt(3)/2
    return (x, y)
end

# Distance function
function distance(n1::TriangularNode, n2::TriangularNode)
    p1, p2 = to_cartesian(n1), to_cartesian(n2)
    return sqrt((p1[1]-p2[1])^2 + (p1[2]-p2[2])^2)
end
```

---

## 6. Discussion Points with Advisor 与导师讨论要点

### Theoretical Questions 理论问题

1. **Does triangular lattice MIS have different complexity from King's graph MIS?**
   - Both are unit disk graphs, but different structures

2. **What's the expected vertex overhead for triangular reduction?**
   - Still O(|V| × pw(G))? Or different?

3. **Are there problems more natural on triangular vs square lattices?**
   - Physics problems with hexagonal symmetry?

### Practical Questions 实践问题

1. **Which neutral-atom hardware uses triangular arrangements?**
   - Need to understand hardware constraints

2. **Is the computer search tractable for triangular?**
   - May need more sophisticated algorithms

3. **What about other lattices (hexagonal, honeycomb)?**
   - General framework for arbitrary lattice types?

### Research Direction Questions 研究方向问题

1. **Should we prioritize finding any gadget, or optimal gadget?**
   - Trade-off between completeness and time

2. **How important is grid-embeddability for triangular?**
   - The current paper values square grid embedding highly

3. **Can we prove non-existence if no gadget found at certain size?**
   - Lower bounds would be valuable

---

## 7. Related Literature 相关文献

Papers to read:

1. **Original weighted reduction**: Nguyen et al., PRX Quantum 4, 010316 (2023)
   - Understand the weighted approach first

2. **Path decomposition**: Robertson & Seymour, Graph Minors series
   - Deep understanding of pathwidth

3. **Unit disk graph recognition**: Breu & Kirkpatrick (1998)
   - NP-hard in general, but we only need small graphs

4. **Neutral atom computing**: Ebadi et al., Science 376, 1209 (2022)
   - Hardware constraints and capabilities

---

## 8. Timeline Suggestion 时间建议

| Week | Task |
|------|------|
| 1-2 | Study paper deeply, understand all proofs |
| 3-4 | Implement triangular lattice infrastructure |
| 5-6 | Enumerate small crossing gadgets |
| 7-8 | Implement gadget search algorithm |
| 9-10 | Test and debug on small examples |
| 11-12 | Document findings, discuss with advisor |

---

## 9. Success Criteria 成功标准

**Minimum viable result**:
- Find at least ONE valid crossing gadget for triangular lattice
- Prove it preserves MIS equivalence

**Good result**:
- Complete gadget set for triangular reduction
- Working implementation with back-mapping

**Excellent result**:
- Optimal (smallest) gadgets
- Complexity analysis
- Comparison with square lattice reduction

---

## Key Questions to Ask Your Advisor 问导师的关键问题

1. "对于三角晶格，您预期交叉组件的大小会比方格（11顶点）更大还是更小？"
   "For triangular lattice, do you expect the crossing gadget to be larger or smaller than 11 vertices?"

2. "在硬件方面，是否有特定的三角排列中性原子系统我们应该关注？"
   "Are there specific triangular-arrangement neutral atom systems we should target?"

3. "您认为路径分解在三角晶格中会有不同的表现吗？"
   "Do you think path decomposition will behave differently for triangular lattice?"

4. "如果我们找不到有效的交叉组件，这意味着什么？"
   "What would it mean if we cannot find a valid crossing gadget?"

5. "是否应该先尝试加权版本的三角归约？"
   "Should we try weighted triangular reduction first?"

---

## Appendix: Quick Reference for Gadget Search 组件搜索快速参考

### The α-tensor check 检查α张量

```julia
# Pseudocode for checking if gadget is valid
function is_valid_crossing_gadget(R_prime, CROSS)
    # 1. Compute reduced α-tensors
    alpha_R = compute_reduced_alpha_tensor(R_prime)
    alpha_CROSS = compute_reduced_alpha_tensor(CROSS)
    
    # 2. Check if they differ by constant
    diff = alpha_R .- alpha_CROSS
    if all(d -> d == diff[1], diff)
        return true, diff[1]  # Valid! Overhead = diff[1]
    else
        return false, nothing
    end
end
```

### Unit disk embedding check for triangular 三角单位圆盘嵌入检查

```julia
function has_triangular_embedding(graph, boundary)
    # Variational optimization
    # Variables: triangular coordinates for each vertex
    # Constraints: 
    #   - Edges must have distance ≤ 1
    #   - Non-edges must have distance > 1
    #   - Boundary vertices at specified positions
    
    # Loss function (similar to Appendix C.2)
    function loss(coords)
        L = 0.0
        for (i,j) in edges(graph)
            L += relu(distance(coords[i], coords[j])^2 - 0.99)
        end
        for (i,j) in non_edges(graph)
            L += relu(1.01 - distance(coords[i], coords[j])^2)
        end
        return L
    end
    
    # Optimize and check if loss → 0
end
```

Good luck with your research! 研究顺利！ 🎯




