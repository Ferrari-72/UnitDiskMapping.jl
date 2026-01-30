# Note 3: The Gadget Framework - Building Blocks
# 组件框架 - 构建模块

---

## 1. What are Gadgets? 什么是组件？

**Gadgets** (组件/小工具) are the fundamental building blocks for graph transformation. Each gadget:
1. Has a **pattern** (source) — what we want to replace (要替换的模式)
2. Has a **replacement** — what we replace it with (替换后的图案)
3. Preserves MIS equivalence (保持MIS等价性)
4. Is embeddable on a unit disk / King's grid (可嵌入到单位圆盘/国王格)

---

## 2. Core Gadget Types 核心组件类型

### 2.1 Copy Gadget (复制组件) - The Backbone

**Purpose**: "Copy" a vertex's value along a line on the grid

**Structure** (T-shape or ⊢ shape):
```
      vslot
        ↓
        |          ← vstart
        |
        |-------   ← hslot
        |      ↑   ← vstop
             hstop
```

**Code Connection** 代码关联:
```julia
# From src/copyline.jl
struct CopyLine
    vertex::Int   # Which original vertex this represents
    vslot::Int    # Column position
    hslot::Int    # Row position (center)
    vstart::Int   # Where vertical line starts
    vstop::Int    # Where vertical line ends
    hstop::Int    # Where horizontal line ends
end
```

**Key Property**: All vertices on a copy line must have the same value in any MIS solution.

**Why T-shape?**
- Vertical part connects to other vertices above/below
- Horizontal part allows edges to cross

**Code Example**:
```julia
# From src/mapping.jl - creating copy lines
function copyline_locations(::Type{NT}, tc::CopyLine; padding::Int) where NT
    # Returns all grid positions for this copy line
    s = 4  # Spacing between copy lines
    locations = NT[]
    # ... (grows up, down, and right from center)
    return locations
end
```

### 2.2 Crossing Gadget (交叉组件) - BATOIDEA

**Problem**: In 2D, when two edges cross, we need a gadget to handle this!

**The CROSS Pattern** (what we need to replace):
```
Source (4 terminals):          
        1
        │
    2 ──┼── 3
        │
        4

Constraint: Edge 1-3 crosses edge 2-4
```

**The BATOIDEA Solution** (魔鬼鱼组件 - named for its shape):
```
Found by computer search!
Size: 11 vertices
Embeddable on square grid

     ⋅ ● ⋅ ⋅ ⋅
     ● ● ● ● ●
     ⋅ ● ● ● ⋅
     ⋅ ⋅ ● ⋅ ⋅
```

**Code Implementation**:
```julia
# From src/gadgets.jl
struct Cross{CON} <: CrossPattern end

# For connected crossing (edges actually exist)
function source_graph(::Cross{false})
    locs = Node.([(2,1), (2,2), (2,3), (2,4), (2,5), (1,3), (2,3), (3,3), (4,3)])
    g = simplegraph([(1,2), (2,3), (3,4), (4,5), (6,7), (7,8), (8,9)])
    return locs, g, [1,6,9,5]  # pins: left, top, bottom, right
end

function mapped_graph(::Cross{false})
    locs = Node.([(2,1), (2,2), (2,3), (2,4), (2,5), (1,3), (3,3), (4,3), (3,2), (3,4)])
    locs, unitdisk_graph(locs, 1.5), [1,6,8,5]
end
```

**MIS Overhead**:
```julia
mis_overhead(::Cross{false}) = -1  # Reduces MIS by 1
```

### 2.3 Turn Gadget (转弯组件)

**Purpose**: Change direction of a copy line by 90°

**Pattern → Replacement**:
```
Source:              Mapped:
⋅ ● ⋅ ⋅             ⋅ ● ⋅ ⋅
⋅ ● ⋅ ⋅      →      ⋅ ⋅ ● ⋅
⋅ ● ● ●             ⋅ ⋅ ⋅ ●
⋅ ⋅ ⋅ ⋅             ⋅ ⋅ ⋅ ⋅
```

**Code**:
```julia
struct Turn <: CrossPattern end

function source_graph(::Turn)
    locs = Node.([(1,2), (2,2), (3,2), (3,3), (3,4)])
    g = simplegraph([(1,2), (2,3), (3,4), (4,5)])
    return locs, g, [1,5]  # Input and output pins
end

mis_overhead(::Turn) = -1
```

### 2.4 Branch Gadget (分支组件)

**Purpose**: Split one copy line into two branches (for vertices with degree > 2)

**Pattern**:
```
Source (Y-shape):        Mapped:
⋅ ● ⋅ ⋅                 ⋅ ● ⋅ ⋅
⋅ ● ⋅ ⋅        →        ⋅ ⋅ ● ⋅
⋅ ● ● ●                 ⋅ ● ⋅ ●
⋅ ● ● ⋅                 ⋅ ⋅ ● ⋅
⋅ ● ⋅ ⋅                 ⋅ ● ⋅ ⋅
```

**Code**:
```julia
struct Branch <: CrossPattern end

function source_graph(::Branch)
    locs = Node.([(1,2), (2,2), (3,2),(3,3),(3,4),(4,3),(4,2),(5,2)])
    g = simplegraph([(1,2), (2,3), (3,4), (4,5), (4,6), (6,7), (7,8)])
    return locs, g, [1, 5, 8]  # Three pins: top, right, bottom
end

mis_overhead(::Branch) = -1
```

### 2.5 Other Supporting Gadgets 其他辅助组件

| Gadget | Purpose | MIS Overhead |
|--------|---------|--------------|
| `EndTurn` | Terminate a copy line | -1 |
| `WTurn` | Alternative turn | -1 |
| `TCon` | T-connection | 0 |
| `TrivialTurn` | Simple corner | 0 |
| `BranchFix` | Fix branching artifacts | -1 |
| `BranchFixB` | Alternative branch fix | -1 |

---

## 3. Gadget Transformations 组件变换

### Rotation (旋转)

Any gadget can be rotated by 90°, 180°, 270°:

```julia
# From src/gadgets.jl
struct RotatedGadget{GT} <: Pattern
    gadget::GT
    n::Int  # Number of 90° rotations
end

# Example: Turn rotated 90° clockwise
RotatedGadget(Turn(), 1)
```

### Reflection (镜像)

Gadgets can be reflected across axes:

```julia
struct ReflectedGadget{GT} <: Pattern
    gadget::GT
    mirror::String  # "x", "y", "diag", or "offdiag"
end

# Example: Reflect across y-axis
ReflectedGadget(Cross{true}(), "y")
```

### Generating All Variants 生成所有变体

```julia
# From src/gadgets.jl
function rotated_and_reflected(p::Pattern)
    patterns = Pattern[p]
    source_matrices = [source_matrix(p)]
    # Try all rotations and reflections
    for pi in [[RotatedGadget(p, i) for i=1:3]..., 
               [ReflectedGadget(p, axis) for axis in ["x", "y", "diag", "offdiag"]]...]
        m = source_matrix(pi)
        if m ∉ source_matrices  # Avoid duplicates
            push!(patterns, pi)
            push!(source_matrices, m)
        end
    end
    return patterns
end
```

---

## 4. The Crossing Ruleset 交叉规则集

The complete set of gadgets used for mapping:

```julia
# From src/mapping.jl
const crossing_ruleset = (
    Cross{false}(),           # Main crossing gadget
    Turn(), WTurn(),          # Turn gadgets
    Branch(), BranchFix(),    # Branching
    TCon(), TrivialTurn(),    # Connections
    RotatedGadget(TCon(), 1), 
    ReflectedGadget(Cross{true}(), "y"),
    ReflectedGadget(TrivialTurn(), "y"), 
    BranchFixB(), EndTurn(),
    ReflectedGadget(RotatedGadget(TCon(), 1), "y")
)
```

---

## 5. How Computer Search Found BATOIDEA 计算机如何搜索到BATOIDEA

### The Search Algorithm 搜索算法 (Algorithm C.1)

```
For each graph size n (from small to large):
    For each non-isomorphic graph G of size n:
        For each choice of 4 boundary vertices:
            R' = (G, boundary)
            
            If passes_filtering_rules(R'):
                Compute α̃(R')
                If α̃(R') differs from α̃(CROSS) by constant:
                    If has_unit_disk_embedding(R'):
                        FOUND! Return R'
```

### Filtering Rules (过滤规则) - Key Optimizations

1. **Boundary connection**: Boundaries (1,3) or (2,4) cannot be directly connected
2. **Symmetry**: Use problem symmetries to avoid redundant searches
   - CROSS is symmetric under: 1↔3, 2↔4, (1,3)↔(2,4)
3. **Crossing criteria**: Paths must geometrically cross in any unit disk embedding

### Unit Disk Embedding Test 单位圆盘嵌入测试

Uses variational optimization:
```
Loss = Σ_{(i,j)∈E} relu(||xi - xj||² - 0.99)     # Edges should be close
     + Σ_{(i,j)∉E} relu(1.01 - ||xi - xj||²)     # Non-edges should be far
```

If Loss = 0, then graph has unit disk embedding.

### Search Results 搜索结果

4 valid replacement graphs found for CROSS at size 11:
- **BATOIDEA** (top-right in paper Figure 6) — **can be embedded on square grid!**
- 3 others are valid but don't fit square grid

---

## 6. Visualizing Gadgets 组件可视化

```julia
# You can visualize any gadget using:
using UnitDiskMapping

# Show source pattern
source_matrix(Turn())

# Show mapped result
mapped_matrix(Turn())

# Or print both:
Turn()  # Will show source → mapped transformation
```

Example output:
```
⋅ ● ⋅ ⋅
⋅ ● ⋅ ⋅
⋅ ● ● ●
⋅ ⋅ ⋅ ⋅
   ↓
⋅ ● ⋅ ⋅
⋅ ⋅ ● ⋅
⋅ ⋅ ⋅ ●
⋅ ⋅ ⋅ ⋅
```

---

## 7. Adding Custom Gadgets 添加自定义组件

The codebase provides a macro for defining new simplification gadgets:

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
```

This defines a gadget that removes "dangling legs" (悬挂支路) — vertices with degree 1.

---

## 8. Summary: Gadget Properties 组件属性总结

For each gadget, we track:

| Property | Description | Used For |
|----------|-------------|----------|
| `source_graph` | Original pattern | Pattern matching |
| `mapped_graph` | Replacement graph | Applying transformation |
| `size` | Grid dimensions | Layout calculations |
| `cross_location` | Center point | Alignment |
| `mis_overhead` | α difference constant | Solution mapping |
| `mapped_entry_to_compact` | Boundary config mapping | Back-mapping |
| `source_entry_to_configs` | Internal configs | Back-mapping |

---

## Next Note: The Complete Mapping Algorithm




