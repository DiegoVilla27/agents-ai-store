---
name: unity-performance-profiling
description: Unity Profiler mastery including frame budget analysis, CPU/GPU profiling, draw call batching, LOD groups, occlusion culling, and performance optimization strategies.
author: Diego Villanueva
trigger: When profiling performance, analyzing frame times, reducing draw calls, optimizing rendering, or diagnosing frame drops and hitches.
---

# Performance Profiling & Optimization

Performance is not optional in games. A frame budget of 16.67ms (60fps) or 8.33ms (120fps) is absolute. Every millisecond matters. Profile first, optimize second, never guess.

## 1. Frame Budget

```text
Target FPS → Frame Budget:
30 fps → 33.33ms per frame (mobile, Switch)
60 fps → 16.67ms per frame (standard)
120 fps → 8.33ms per frame (competitive/VR)

Budget Allocation (60fps example):
├── CPU: ~10ms
│   ├── Game Logic: 3ms
│   ├── Physics: 2ms
│   ├── Animation: 1ms
│   ├── Rendering Prep: 2ms
│   └── Scripts: 2ms
├── GPU: ~10ms
│   ├── Shadow Maps: 2ms
│   ├── Opaque Pass: 3ms
│   ├── Transparent Pass: 2ms
│   ├── Post-Processing: 2ms
│   └── UI: 1ms
└── Overhead: ~3ms (OS, VSync)
```

## 2. Unity Profiler (CPU)

```text
✅ Window → Analysis → Profiler
Key Modules:
├── CPU Usage: Script execution time per method
├── GPU Usage: Render pass timings
├── Memory: Managed/native heap, texture memory
├── Rendering: Draw calls, triangles, batches
├── Physics: Collision checks, rigidbody count
└── Audio: Active sources, CPU load

✅ Deep Profile: Shows exact method timings (very slow, use sparingly)
✅ Timeline View: See per-frame execution on all threads
```

```csharp
// ✅ Custom profiler markers for your code
using Unity.Profiling;

public class EnemyManager : MonoBehaviour
{
    private static readonly ProfilerMarker s_UpdateEnemies =
        new("EnemyManager.UpdateEnemies");
    private static readonly ProfilerMarker s_PathfindingMarker =
        new("EnemyManager.Pathfinding");

    private void Update()
    {
        using (s_UpdateEnemies.Auto())
        {
            using (s_PathfindingMarker.Auto())
            {
                UpdatePathfinding();
            }
            UpdateBehavior();
            UpdateAnimations();
        }
    }
}
```

## 3. Frame Debugger

```text
✅ Window → Analysis → Frame Debugger
Shows every draw call in order. Use to identify:
- Why objects aren't batching (different materials, different meshes)
- Redundant passes (shadow maps for invisible objects)
- Overdraw (transparent objects rendered multiple times)
- Post-processing cost (each effect = a pass)
```

## 4. Draw Call Optimization

```csharp
// ✅ Batching strategies
// Static Batching: For objects that NEVER move
// → Mark as Static in Inspector → batched at build time

// Dynamic Batching: For small meshes (< 300 vertices)
// → Automatic, but limited effectiveness

// SRP Batcher: For objects sharing the same shader
// → Enabled in URP Asset → batches materials with same shader variant

// GPU Instancing: For many copies of the same mesh
// → Enable on material: "Enable GPU Instancing"

// ✅ Reduce draw calls
// 1. Texture Atlasing: Combine multiple textures into one atlas
// 2. Mesh Combining: Merge static meshes at runtime
// 3. Material Sharing: Use MaterialPropertyBlock instead of unique materials
```

```csharp
// ❌ NEVER: Create material instances per object
renderer.material.color = Color.red; // Creates a NEW material instance! Draw call +1

// ✅ ALWAYS: Use MaterialPropertyBlock
private MaterialPropertyBlock _mpb = new();

void SetColor(Renderer r, Color color)
{
    r.GetPropertyBlock(_mpb);
    _mpb.SetColor("_BaseColor", color);
    r.SetPropertyBlock(_mpb);
    // Shares the base material, no extra draw call
}
```

## 5. LOD Groups

```text
✅ Every 3D model visible at distance MUST have LODGroup:
LOD0: Full detail (0-15m)     → 100% triangles
LOD1: Medium detail (15-40m)  → 50% triangles
LOD2: Low detail (40-100m)    → 25% triangles
Culled: Not rendered (>100m)  → 0 triangles

Setup:
1. Add LODGroup component
2. Assign mesh renderers to each LOD level
3. Set transition percentages
4. Enable "Cross Fade" for smooth transitions
```

## 6. Occlusion Culling

```text
✅ For environments with walls/buildings:
1. Mark static geometry as "Occluder Static" and "Occludee Static"
2. Window → Rendering → Occlusion Culling → Bake
3. Objects behind walls are not rendered (zero GPU cost)

Settings:
├── Smallest Occluder: 5m (smallest wall that hides objects)
├── Smallest Hole: 0.25m (smallest gap camera can see through)
└── Backface Threshold: 100 (ignore backfaces for occlusion)
```

## 7. Common Performance Killers

```text
❌ Performance Anti-Patterns:
├── GetComponent<T>() in Update    → Cache in Awake()
├── Find/FindObjectOfType in loops → Cache references
├── String concatenation in Update → Use StringBuilder
├── LINQ in hot paths              → Use for loops
├── Debug.Log in builds            → Strip with #if UNITY_EDITOR
├── Camera.main every frame        → Cache reference
├── new List<T>() in Update        → Pre-allocate and reuse
├── Instantiate/Destroy in loops   → Object pooling
├── Physics.RaycastAll             → Use NonAlloc variants
└── Animator.SetTrigger("string")  → Use hashed int IDs
```

---

**Execution Protocol**
1. **Profile on Target Device**: ALWAYS profile on the target hardware (mobile, console). Editor performance is meaningless.
2. **Custom Profiler Markers**: Add `ProfilerMarker` to every system's Update loop for easy identification.
3. **Frame Debugger Before Optimizing**: Before reducing draw calls, open Frame Debugger to understand WHY objects aren't batching.
4. **LOD Everything**: Every 3D asset visible from > 20m MUST have a LODGroup.
5. **Zero GC Alloc in Update**: Use Profiler → GC.Alloc to find and eliminate all managed allocations in hot paths.
