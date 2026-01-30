# Note 5: Code-Paper Connection
# 代码与论文对应关系

---

## 1. File Structure Overview 文件结构概览

```
src/
├── UnitDiskMapping.jl    ← Main module, exports all functions
├── Core.jl               ← Basic types: Node, GridGraph, Cell
├── copyline.jl           ← Copy line structures (Section 3)
├── gadgets.jl            ← Gadget definitions (Section 3)
├── mapping.jl            ← Main mapping algorithm (Section 4)
├── pathdecomposition/    ← Pathwidth algorithms (Section 4.1)
│   ├── pathdecomposition.jl
│   ├── greedy.jl
│   └── branching.jl
├── simplifiers.jl        ← Simplification gadgets
├── extracting_results.jl ← α-tensor data for back-mapping
├── weighted.jl           ← Weighted version (not main focus)
├── visualize.jl          ← Visualization utilities
├── utils.jl              ← Helper functions
├── dragondrop.jl         ← QUBO mapping (supplementary)
├── multiplier.jl         ← Factoring problem (supplementary)
└── logicgates.jl         ← Logic gates (supplementary)
```

---

## 2. Paper Sections ↔ Code Files 论文章节与代码对应

### Section 1: Introduction
**No direct code correspondence** — Background and motivation

### Section 2: Background and Notation 背景与符号

| Paper Concept | Code Location | Code Element |
|---------------|---------------|--------------|
| Graph G = (V, E) | `Graphs.jl` (external) | `SimpleGraph` |
| Bitstring s | Various | `Vector{Int}` or `BitVector` |
| H_MIS energy | Not directly implemented | See `GenericTensorNetworks.jl` |
| Unit disk graph | `src/Core.jl` | `unit_disk_graph()`, `GridGraph` |
| α(G) (MIS size) | External solver | `GenericTensorNetworks.IndependentSet` |

**Code Example**:
```julia
# Creating a unit disk graph (Definition 2.1 in paper)
# From src/Core.jl
function unit_disk_graph(locs::AbstractVector, radius::Real)
    g = SimpleGraph(length(locs))
    for i = 1:length(locs)
        for j = i+1:length(locs)
            # Connect if distance ≤ radius
            if sqrt(sum(abs2, locs[i] .- locs[j])) <= radius
                add_edge!(g, i, j)
            end
        end
    end
    return g
end
```

### Section 3: Graph Rewriting Framework 图重写框架

#### 3.1 Open Graphs (开图)

| Paper Concept | Code Location | Code Element |
|---------------|---------------|--------------|
| Open graph R = (V, E, ∂R) | `src/gadgets.jl` | `source_graph()` returns `(locs, graph, pins)` |
| Boundary vertices ∂R | `src/gadgets.jl` | `pins` in return tuple |
| Pattern P | `src/gadgets.jl` | `abstract type Pattern` |

**Code Example**:
```julia
# From src/gadgets.jl - Turn gadget
# This is equation (3.1) type pattern in the paper
function source_graph(::Turn)
    locs = Node.([(1,2), (2,2), (3,2), (3,3), (3,4)])  # Vertex locations
    g = simplegraph([(1,2), (2,3), (3,4), (4,5)])      # Edges
    return locs, g, [1,5]  # Boundary vertices (pins)
end
```

#### 3.2 α-Tensor (α张量)

| Paper Concept | Code Location | Code Element |
|---------------|---------------|--------------|
| α-tensor | `src/extracting_results.jl` | `source_entry_to_configs()` |
| Reduced α-tensor | `src/extracting_results.jl` | `mapped_entry_to_compact()` |
| MIS overhead (constant c) | `src/extracting_results.jl` | `mis_overhead()` |

**Code Example**:
```julia
# From src/extracting_results.jl
# This encodes the α-tensor for the Cross{false} gadget
function source_entry_to_configs(::Cross{false})
    # Keys: boundary configuration (as integer)
    # Values: possible internal configurations
    return Dict(
        0 => [[0,1,0,1,0,0,0,1,0], [0,1,0,1,0,0,1,0,0]],
        1 => [[1,0,1,0,0,0,0,1,0], ...],
        ...
    )
end

# The MIS overhead (Theorem 3.7's constant c)
mis_overhead(::Cross{false}) = -1
```

#### 3.3 Crossing Gadget (交叉组件)

**Paper Figure 4/6 ↔ Code**:

| Paper | Code |
|-------|------|
| CROSS pattern | `Cross{false}()` |
| BATOIDEA replacement | `mapped_graph(::Cross{false})` |

**Code for BATOIDEA**:
```julia
# From src/gadgets.jl - This is the BATOIDEA gadget
# Paper Section 3.2, Equation (3.1)
function mapped_graph(::Cross{false})
    # The 11-vertex replacement found by computer search
    locs = Node.([
        (2,1), (2,2), (2,3), (2,4), (2,5),  # Horizontal line
        (1,3),                               # Top
        (3,3), (4,3),                        # Bottom
        (3,2), (3,4)                         # Additional diagonal
    ])
    return locs, unitdisk_graph(locs, 1.5), [1,6,8,5]  # Pins
end
```

### Section 4: Reduction Scheme 归约方案

#### 4.1 Path Decomposition (路径分解)

| Paper Concept | Code Location | Code Element |
|---------------|---------------|--------------|
| Path decomposition | `src/pathdecomposition/` | `pathwidth()` |
| Vertex separation | `pathdecomposition.jl` | `vsep()`, `Layout` |
| Optimal algorithm | `branching.jl` | `MinhThiTrick` |
| Greedy approximation | `greedy.jl` | `Greedy` |

**Code Example**:
```julia
# From src/pathdecomposition/pathdecomposition.jl
struct Layout{T}
    vertices::Vector{T}    # Ordered vertices
    vsep::Int             # Vertex separation (= pathwidth)
    neighbors::Vector{T}  # Active neighbors
    disconnected::Vector{T}
end

# Usage (Paper Algorithm 1 equivalent):
result = pathwidth(graph, MinhThiTrick())  # Exact
result = pathwidth(graph, Greedy())        # Approximate
```

#### 4.2 Copying Gadget (复制组件)

| Paper Concept | Code Location | Code Element |
|---------------|---------------|--------------|
| T-shaped copy line | `src/copyline.jl` | `CopyLine` struct |
| Creating copy lines | `src/copyline.jl` | `create_copylines()` |
| Grid embedding | `src/mapping.jl` | `ugrid()`, `embed_graph()` |

**Code Example**:
```julia
# From src/copyline.jl
# This implements the T-shaped copy gadget from Section 4.2
struct CopyLine
    vertex::Int   # Original vertex this represents
    vslot::Int    # Column position (vertical slot)
    hslot::Int    # Row position (horizontal slot)
    vstart::Int   # Top of vertical part
    vstop::Int    # Bottom of vertical part
    hstop::Int    # Right end of horizontal part
end
```

#### 4.3 Complete Mapping (完整映射)

| Paper Algorithm | Code Location | Code Function |
|-----------------|---------------|---------------|
| Main reduction | `src/mapping.jl` | `map_graph()` |
| Apply gadgets | `src/mapping.jl` | `apply_crossing_gadgets!()` |
| Simplification | `src/mapping.jl` | `apply_simplifier_gadgets!()` |
| Back-mapping | `src/mapping.jl` | `map_config_back()` |

---

## 3. Key Theorems ↔ Code Verification 关键定理与代码验证

### Theorem 3.7 (Replacement Theorem)

**Verification in tests**:
```julia
# From test/gadgets.jl (conceptual)
# For each gadget, verify:
# 1. Boundary configurations match
# 2. Reduced α-tensors differ by constant

function test_gadget_equivalence(gadget)
    source_alpha = compute_alpha_tensor(source_graph(gadget))
    mapped_alpha = compute_alpha_tensor(mapped_graph(gadget))
    
    # Check they differ by a constant
    diff = source_alpha .- mapped_alpha
    @test all(d -> d == diff[1], diff)  # All differences equal
end
```

### Theorem 4.3 (Size Bound)

**Verification**:
```julia
# The size bound O(|V| × pw(G)) can be verified:
result = map_graph(graph)
mapped_size = length(result.grid_graph.nodes)
pw = pathwidth(graph, MinhThiTrick()).vsep

# Should satisfy: mapped_size = O(nv(graph) × pw)
```

---

## 4. Running the Examples 运行示例

### Tutorial File 教程文件

The file `examples/tutorial.jl` demonstrates the entire pipeline:

```julia
# From examples/tutorial.jl

using UnitDiskMapping, Graphs, GenericTensorNetworks

# 1. Create source graph
graph = smallgraph(:petersen)

# 2. Map to King's subgraph
result = map_graph(graph; vertex_order=MinhThiTrick())

# 3. Solve mapped graph
solution = solve(
    GenericTensorNetwork(IndependentSet(SimpleGraph(result.grid_graph))),
    SingleConfigMax()
)[]

# 4. Map solution back
original_config = map_config_back(result, solution.c.data)

# 5. Verify
@assert is_independent_set(graph, original_config)
```

### Visualization 可视化

```julia
using LuxorGraphPlot

# Show the mapped grid graph
LuxorGraphPlot.show_graph(result.grid_graph)

# Show configuration on grid
show_config(result.grid_graph, solution.c.data)

# Show with weights (for weighted version)
show_grayscale(result.grid_graph)
```

---

## 5. Important Data Structures 重要数据结构

### GridGraph (网格图)

```julia
# From src/Core.jl
struct GridGraph{NT<:Node}
    size::Tuple{Int,Int}   # Grid dimensions
    nodes::Vector{NT}       # List of occupied nodes
    radius::Float64         # Connection radius (1.5 for King's)
end

# Example:
# A 5×5 grid with nodes at (1,1), (2,3), (4,5):
GridGraph((5,5), [Node(1,1), Node(2,3), Node(4,5)], 1.5)
```

### MappingResult (映射结果)

```julia
# From src/mapping.jl
struct MappingResult{NT}
    grid_graph::GridGraph{NT}   # The mapped graph
    lines::Vector{CopyLine}      # Copy line info (for back-mapping)
    padding::Int                 # Grid padding
    mapping_history::Vector{Tuple{Pattern,Int,Int}}  # Gadget applications
    mis_overhead::Int            # α(mapped) - α(original)
end
```

### Pattern Hierarchy (模式层次)

```
abstract type Pattern
├── abstract type CrossPattern <: Pattern  (交叉模式)
│   ├── Cross{CON}
│   ├── Turn
│   ├── Branch
│   ├── BranchFix
│   ├── WTurn
│   ├── TCon
│   ├── TrivialTurn
│   ├── EndTurn
│   └── BranchFixB
└── abstract type SimplifyPattern <: Pattern  (简化模式)
    └── DanglingLeg

RotatedGadget{GT} <: Pattern  (旋转变体)
ReflectedGadget{GT} <: Pattern  (镜像变体)
```

---

## 6. Creating New Gadgets 创建新组件

If you need to add a gadget (e.g., for triangular lattice):

### Step 1: Define the pattern
```julia
# In src/gadgets.jl or new file
struct MyNewGadget <: CrossPattern end

Base.size(::MyNewGadget) = (rows, cols)
cross_location(::MyNewGadget) = (center_row, center_col)
iscon(::MyNewGadget) = false  # or true if connected
```

### Step 2: Define source and mapped graphs
```julia
function source_graph(::MyNewGadget)
    locs = Node.([...])  # Vertex locations
    g = simplegraph([...])  # Edge list
    return locs, g, [pin_indices...]  # Boundary vertices
end

function mapped_graph(::MyNewGadget)
    locs = Node.([...])
    return locs, unitdisk_graph(locs, radius), [pin_indices...]
end
```

### Step 3: Run createmap.jl to generate extracting_results
```bash
julia project/createmap.jl
```
This computes `mis_overhead`, `mapped_entry_to_compact`, `source_entry_to_configs`.

### Step 4: Add to ruleset
```julia
# In src/mapping.jl
const my_ruleset = (..., MyNewGadget(), ...)
```

---

## 7. Testing 测试

The `test/` directory mirrors `src/`:

| Test File | Tests For |
|-----------|-----------|
| `test/gadgets.jl` | Gadget α-tensor equivalence |
| `test/mapping.jl` | End-to-end mapping correctness |
| `test/pathdecomposition/` | Pathwidth algorithms |
| `test/copyline.jl` | Copy line generation |

**Run tests**:
```bash
julia --project -e "using Pkg; Pkg.test()"
```

---

## Next Note: Future Directions - Triangular Lattice




