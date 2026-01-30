# Note 4: The Complete Mapping Algorithm
# 完整映射算法

---

## 1. Overview of the Mapping Pipeline 映射流程概述

```
┌─────────────────────────────────────────────────────────────────┐
│                    INPUT: Arbitrary Graph G                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: PATH DECOMPOSITION (路径分解)                           │
│  - Find optimal vertex ordering                                  │
│  - Determines grid height (pathwidth)                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 2: CREATE CROSSING LATTICE (创建交叉格)                    │
│  - Each vertex → T-shaped copy line                              │
│  - Edges → crossings marked for connection                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 3: APPLY CROSSING GADGETS (应用交叉组件)                   │
│  - Replace crossings with BATOIDEA, Turn, Branch, etc.          │
│  - Record transformation history                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 4: APPLY SIMPLIFIERS (应用简化器)                          │
│  - Remove unnecessary vertices                                   │
│  - Optimize grid layout                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│             OUTPUT: King's Subgraph + Mapping Info               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Step 1: Path Decomposition 路径分解

### What is Path Decomposition? 什么是路径分解？

**Goal**: Arrange vertices in a linear order that minimizes "width" (宽度).

**Definition (Vertex Separation)** 顶点分离度:
Given an ordering v₁, v₂, ..., vₙ of vertices:
```
sep(i) = |{ w : w not yet ordered, but w has neighbor in {v₁,...,vᵢ} }|
pathwidth = max_i sep(i)
```

**Intuition** 直觉:
- Imagine revealing vertices one by one
- sep(i) = number of "active" connections to unrevealed vertices
- Want to minimize the maximum number of active connections

### Why Does Pathwidth Matter? 为什么路径宽度重要？

**Grid Height = Pathwidth + 1**

The copy lines need to be stacked vertically. Pathwidth determines how many can be active simultaneously, thus grid height.

### Code Implementation 代码实现

```julia
# From src/pathdecomposition/pathdecomposition.jl

# Method 1: MinhThiTrick (Exact, but slow for large graphs)
struct MinhThiTrick <: PathDecompositionMethod end

# Method 2: Greedy (Fast, but may not be optimal)
struct Greedy <: PathDecompositionMethod
    nrepeat::Int  # Run multiple times, keep best
end

# Usage:
result = pathwidth(graph, MinhThiTrick())  # Exact
result = pathwidth(graph, Greedy(nrepeat=10))  # Approximate
```

### The Layout Structure 布局结构

```julia
struct Layout{T}
    vertices::Vector{T}      # Ordered vertices
    vsep::Int               # Maximum vertex separation (pathwidth)
    neighbors::Vector{T}    # Current active neighbors
    disconnected::Vector{T} # Remaining unconnected vertices
end
```

### Branch-and-Bound Algorithm 分支定界算法

For exact pathwidth (MinhThiTrick):
```
function branch_and_bound(G):
    Initialize with empty layout, upper_bound = n
    
    For each possible next vertex v:
        new_layout = layout ⊙ v  # Add v to layout
        new_vsep = vsep_updated(G, layout, v)
        
        If new_vsep < upper_bound:
            If layout is complete:
                upper_bound = new_vsep
                best_layout = new_layout
            Else:
                Recursively explore with new_layout
    
    Return best_layout
```

---

## 3. Step 2: Create Crossing Lattice 创建交叉格

### Copy Lines Generation 复制线生成

Each vertex in original graph becomes a T-shaped copy line:

```julia
# From src/copyline.jl
function create_copylines(g::SimpleGraph, ordered_vertices::AbstractVector{Int})
    # For each vertex in order, create a CopyLine
    # CopyLine extends:
    #   - Vertically: from first edge to last edge in ordering
    #   - Horizontally: to rightmost connected vertex
    ...
end
```

**Visual Example**:
```
Original Graph:          Copy Lines on Grid:
   1───2───3                 1  2  3  (vslot positions)
   │   │                     │  │  │
   4───5                     │  │  │
                             ├──┤  │  (hslot for vertex 1)
                             │  ├──┤  (hslot for vertex 2)
                             │  │  │
                             ...
```

### Grid Layout 格点布局

```julia
# From src/mapping.jl
function ugrid(mode, g::SimpleGraph, vertex_order; padding=2, nrow)
    s = 4  # Spacing between copy lines
    
    # Calculate grid size
    N = (n-1)*s + 1 + 2*padding  # Width
    M = nrow*s + 1 + 2*padding   # Height
    
    # Create empty grid
    u = fill(empty_cell, M, N)
    
    # Add copy line vertices
    for tc in copylines
        for loc in copyline_locations(tc)
            add_cell!(u, loc)
        end
    end
    
    # Mark edge crossings
    for e in edges(g)
        mark_crossing(u, e.src, e.dst)
    end
    
    return MappingGrid(copylines, padding, u)
end
```

### Grid Cell Types 格子单元类型

```julia
# From src/mapping.jl
struct MCell{WT} <: AbstractCell{WT}
    occupied::Bool     # Is there a vertex here?
    doubled::Bool      # Two vertices at same location (before resolution)
    connected::Bool    # Edge crossing marker
    weight::WT         # Vertex weight (for weighted version)
end

# Printing symbols:
# ● = occupied (normal)
# ◉ = doubled (two vertices overlap)
# ◆ = connected (edge crossing point)
# ⋅ = empty
```

---

## 4. Step 3: Apply Crossing Gadgets 应用交叉组件

### The Application Algorithm 应用算法

```julia
# From src/mapping.jl
function apply_crossing_gadgets!(mode, ug::MappingGrid)
    ruleset = get_ruleset(mode)  # Get all gadget patterns
    tape = []  # Record transformations
    
    # Scan grid for patterns
    for j in 1:n  # Columns (vslot order)
        for i in 1:n  # Rows (hslot order)
            for pattern in ruleset
                if match(pattern, ug.content, x, y)
                    apply_gadget!(pattern, ug.content, x, y)
                    push!(tape, (pattern, x, y))
                    break  # Only one pattern per location
                end
            end
        end
    end
    
    return ug, tape
end
```

### Pattern Matching 模式匹配

```julia
# Check if pattern matches at position (i,j)
function Base.match(p::Pattern, matrix, i, j)
    a = source_matrix(p)
    m, n = size(a)
    # Check each cell in pattern against grid
    all(ci -> safe_get(matrix, i+ci.I[1]-1, j+ci.I[2]-1) == a[ci],
        CartesianIndices((m, n)))
end
```

### Applying a Gadget 应用组件

```julia
function apply_gadget!(p::Pattern, matrix, i, j)
    a = mapped_matrix(p)  # Get replacement pattern
    m, n = size(a)
    # Overwrite grid with mapped pattern
    for ci in CartesianIndices((m, n))
        safe_set!(matrix, i+ci.I[1]-1, j+ci.I[2]-1, a[ci])
    end
    return matrix
end
```

---

## 5. Step 4: Apply Simplifiers 应用简化器

### Purpose 目的

Remove unnecessary vertices to reduce graph size:
- Dangling legs (degree-1 vertices that don't affect MIS)
- Redundant paths

### Implementation 实现

```julia
# From src/mapping.jl
function apply_simplifier_gadgets!(ug::MappingGrid; ruleset, nrepeat=10)
    tape = []
    for _ in 1:nrepeat  # Multiple passes
        for pattern in ruleset
            # Scan entire grid
            for j in 0:size(ug, 2), i in 0:size(ug, 1)
                if match(pattern, ug.content, i, j)
                    apply_gadget!(pattern, ug.content, i, j)
                    push!(tape, (pattern, i, j))
                end
            end
        end
    end
    return ug, tape
end
```

### Default Simplifier 默认简化器

```julia
# From src/simplifiers.jl
@gg DanglingLeg =
    """ 
    ⋅ ⋅ ⋅ 
    ⋅ ● ⋅ 
    ⋅ ● ⋅ 
    ⋅ ● ⋅ 
    """=>"""
    ⋅ ⋅ ⋅ 
    ⋅ ⋅ ⋅ 
    ⋅ ⋅ ⋅ 
    ⋅ ● ⋅
    """
# Removes a path of 3 vertices leaving only 1 (at boundary)
```

---

## 6. The Complete map_graph Function 完整映射函数

```julia
# From src/mapping.jl
function map_graph(mode, g::SimpleGraph; 
                   vertex_order=MinhThiTrick(), 
                   ruleset=default_simplifier_ruleset(mode))
    
    # Step 1: Embed graph into initial grid
    ug = embed_graph(mode, g; vertex_order=vertex_order)
    
    # Track MIS overhead
    mis_overhead0 = mis_overhead_copylines(ug)
    
    # Step 2: Apply crossing gadgets
    ug, tape = apply_crossing_gadgets!(mode, ug)
    
    # Step 3: Apply simplifiers
    ug, tape2 = apply_simplifier_gadgets!(ug; ruleset=ruleset)
    
    # Calculate total overhead
    mis_overhead1 = sum(x -> mis_overhead(x[1]), tape)
    mis_overhead2 = sum(x -> mis_overhead(x[1]), tape2)
    
    # Package result
    return MappingResult(
        GridGraph(ug),           # The mapped grid graph
        ug.lines,                # Copy line information
        ug.padding,              # Grid padding
        vcat(tape, tape2),       # Transformation history
        mis_overhead0 + mis_overhead1 + mis_overhead2  # Total overhead
    )
end
```

### MappingResult Structure 映射结果结构

```julia
struct MappingResult{NT}
    grid_graph::GridGraph{NT}           # Final grid graph
    lines::Vector{CopyLine}              # Original copy lines
    padding::Int                         # Grid padding
    mapping_history::Vector{Tuple{Pattern,Int,Int}}  # Transformation log
    mis_overhead::Int                    # α(mapped) - α(original)
end
```

---

## 7. Solving and Mapping Back 求解与反向映射

### Solving the Mapped Graph 求解映射图

```julia
using GenericTensorNetworks

# Get the simple graph from grid graph
mapped_simple_graph = SimpleGraph(mapping_result.grid_graph)

# Solve MIS using tensor network methods
solution = solve(GenericTensorNetwork(
    IndependentSet(mapped_simple_graph)
), SingleConfigMax())
```

### Mapping Solution Back 反向映射解

```julia
# From src/mapping.jl
function map_config_back(res::MappingResult, cfg)
    # Convert configuration to grid format
    c = zeros(Int, size(res.grid_graph))
    for (i, n) in enumerate(res.grid_graph.nodes)
        c[n.loc...] = cfg[i]
    end
    
    # Reverse each transformation
    ug = MappingGrid(res.lines, res.padding, ...)
    unapply_gadgets!(ug, res.mapping_history, [c])
    
    return original_configuration
end
```

### The Unapply Process 反向应用过程

```julia
function unapply_gadgets!(ug::MappingGrid, tape, configurations)
    # Process in REVERSE order (后进先出)
    for (pattern, i, j) in reverse(tape)
        # Verify we're at correct state
        @assert unmatch(pattern, ug.content, i, j)
        
        # Map configuration back through gadget
        for c in configurations
            map_config_back!(pattern, i, j, c)
        end
        
        # Restore original pattern
        unapply_gadget!(pattern, ug.content, i, j)
    end
    
    # Convert grid config to original vertex config
    return map_config_copyback!(ug, configurations)
end
```

---

## 8. Complexity Analysis 复杂度分析

### Size Complexity 大小复杂度

**Theorem (Paper Section 4)**:
```
|V_mapped| = O(|V| × pw(G))
```

**Breakdown**:
- Each vertex becomes a copy line of length O(pw(G))
- |V| copy lines total
- Gadget replacement adds constant factor

### Optimality 最优性

**Theorem**: This reduction is optimal up to constant factors (assuming ETH).

**Proof sketch**:
- ETH implies MIS cannot be solved in time 2^o(n) on n-vertex graphs
- King's graph MIS can be solved in time 2^O(pw)
- If reduction had |V_mapped| = o(|V| × pw(G)), we could solve general MIS faster than ETH allows

---

## 9. Complete Example 完整示例

```julia
using UnitDiskMapping, Graphs

# Create a simple graph
g = smallgraph(:petersen)  # Petersen graph: 10 vertices

# Map to King's subgraph
result = map_graph(g; vertex_order=MinhThiTrick())

# Check properties
println("Original vertices: ", nv(g))
println("Mapped vertices: ", length(result.grid_graph.nodes))
println("MIS overhead: ", result.mis_overhead)
println("Grid size: ", result.grid_graph.size)

# Solve
using GenericTensorNetworks
solution = solve(GenericTensorNetwork(
    IndependentSet(SimpleGraph(result.grid_graph))
), SingleConfigMax())

# Map back
original_mis = map_config_back(result, solution[].c.data)
println("Original MIS: ", original_mis)
```

---

## Key Takeaways 关键要点

1. **Path decomposition** determines efficiency of reduction
2. **Copy lines** preserve vertex values across the grid
3. **Crossing gadgets** handle edge intersections
4. **Transformation history** enables solution mapping
5. **Size is O(|V| × pw(G))** — optimal under ETH

---

## Next Note: Code-Paper Connection and Examples




