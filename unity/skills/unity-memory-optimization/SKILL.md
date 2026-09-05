---
name: unity-memory-optimization
description: Memory profiling and optimization for Unity including object pooling, GC allocation reduction, texture compression, mesh optimization, and asset lifecycle management.
author: Diego Villanueva
trigger: When diagnosing memory issues, implementing object pooling, reducing garbage collection spikes, or optimizing texture and mesh memory usage.
---

# Memory Optimization

Unity's garbage collector is non-generational and stop-the-world. Every GC spike is a visible frame hitch. Mastering memory means zero allocations in hot paths, aggressive pooling, and controlled asset lifecycles.

## 1. Object Pooling (Universal Pool)

```csharp
// ✅ Generic object pool using Unity's built-in ObjectPool
using UnityEngine.Pool;

public class ProjectilePool : MonoBehaviour
{
    [SerializeField] private Projectile _prefab;
    [SerializeField] private int _defaultCapacity = 50;
    [SerializeField] private int _maxSize = 200;

    private ObjectPool<Projectile> _pool;

    private void Awake()
    {
        _pool = new ObjectPool<Projectile>(
            createFunc: () =>
            {
                var obj = Instantiate(_prefab, transform);
                obj.SetPool(_pool);
                return obj;
            },
            actionOnGet: proj => proj.gameObject.SetActive(true),
            actionOnRelease: proj =>
            {
                proj.gameObject.SetActive(false);
                proj.ResetState();
            },
            actionOnDestroy: proj => Destroy(proj.gameObject),
            defaultCapacity: _defaultCapacity,
            maxSize: _maxSize
        );
    }

    public Projectile Get() => _pool.Get();

    public void Return(Projectile proj) => _pool.Release(proj);
}
```

## 2. Zero-Allocation Patterns

```csharp
// ✅ Pre-allocate collections
private readonly List<Transform> _buffer = new(64);
private readonly Dictionary<int, Enemy> _enemyMap = new(128);
private readonly StringBuilder _sb = new(256);
private readonly Collider[] _overlapResults = new Collider[32];

// ✅ Cache component references
private Rigidbody _rb;
private Animator _anim;
private Transform _cachedTransform;

private void Awake()
{
    _rb = GetComponent<Rigidbody>();
    _anim = GetComponent<Animator>();
    _cachedTransform = transform;
}

// ✅ Cache WaitForSeconds
private static readonly WaitForSeconds Wait1s = new(1f);
private static readonly WaitForSeconds Wait05s = new(0.5f);

// ✅ Use struct enumerators (no boxing)
// foreach on List<T> uses struct enumerator (OK)
// foreach on IEnumerable<T> boxes the enumerator (BAD in hot paths)

// ✅ Avoid closures in hot paths (they capture and allocate)
// ❌ enemies.Where(e => e.IsAlive).ToList(); // Lambda + LINQ + ToList = 3 allocations
// ✅ Manual loop with pre-allocated list
_buffer.Clear();
for (int i = 0; i < _enemies.Count; i++)
    if (_enemies[i].IsAlive) _buffer.Add(_enemies[i]);
```

## 3. Texture Memory

```text
✅ Texture Compression by Platform:
├── PC: BC7 (RGBA), BC5 (Normal Maps)
├── Android: ASTC 6x6 (quality) or ASTC 8x8 (size)
├── iOS: ASTC 6x6
├── Switch: ASTC 4x4
└── WebGL: DXT5/ETC2

✅ Texture Settings:
├── Max Size: Match actual usage (don't ship 4096 for a button icon)
├── Generate Mip Maps: ✅ for 3D objects, ❌ for UI sprites
├── Read/Write Enabled: ❌ (doubles memory usage!)
├── Streaming Mipmaps: ✅ for large textures (loads lower mips first)
└── Crunch Compression: ✅ for build size reduction

Memory Impact:
- 1024x1024 RGBA uncompressed: 4MB
- 1024x1024 ASTC 6x6: ~0.5MB (8x reduction!)
- Enable mipmaps: +33% memory, but prevents GPU aliasing
```

## 4. Mesh Memory

```text
✅ Mesh Optimization:
├── Read/Write Enabled: ❌ (doubles mesh memory!)
├── Mesh Compression: Medium or High
├── Optimize Mesh Data: ✅ (strips unused vertex channels)
├── Index Format: 16-bit for meshes < 65k vertices
└── Generate Lightmap UVs: Only if using lightmaps

✅ Mesh LOD memory savings:
LOD0: 10,000 tris → 500KB
LOD1:  5,000 tris → 250KB
LOD2:  2,000 tris → 100KB
At 100m only LOD2 loaded → 80% memory saved
```

## 5. Memory Profiler

```text
✅ Window → Analysis → Memory Profiler
Key metrics:
├── Total Reserved: Memory reserved by Unity
├── Used: Actually consumed memory
├── Managed Heap: C# objects (affected by GC)
├── Native Memory: Textures, meshes, audio (not GC'd)
├── GC Allocated: Memory allocated per frame
└── Texture Memory: Total GPU texture footprint

✅ Take snapshots at key moments:
1. Main Menu loaded
2. Gameplay peak (100 enemies, all VFX)
3. After scene transition (check for leaks)

✅ Compare snapshots: Objects that exist in snapshot 2 but not 1
   that shouldn't be there → MEMORY LEAK
```

## 6. Asset Lifecycle

```csharp
// ✅ Proper asset lifecycle management
// Scene assets: Loaded with scene, unloaded with scene
// Addressables: Loaded on demand, released when ref count = 0
// Resources: Loaded forever unless manually unloaded (AVOID)

// ✅ Force cleanup between scenes
public async Awaitable CleanupAndLoadScene(string sceneName)
{
    // 1. Unload current scene
    await SceneManager.UnloadSceneAsync(SceneManager.GetActiveScene());

    // 2. Unload unused assets
    await Resources.UnloadUnusedAssets();

    // 3. Force GC collection (do this ONLY during loading screens)
    GC.Collect();
    GC.WaitForPendingFinalizers();
    GC.Collect();

    // 4. Load new scene
    await SceneManager.LoadSceneAsync(sceneName);
}

// ❌ NEVER: Call GC.Collect() during gameplay — it's a full stop-the-world pause
```

---

**Execution Protocol**
1. **Pool Everything**: Bullets, VFX, enemies, UI elements, audio sources — if it spawns at runtime, it must be pooled.
2. **Zero GC in Update**: Monitor `GC.Alloc` in Profiler. Hot paths MUST produce 0 bytes of managed allocation.
3. **Disable Read/Write**: ALWAYS disable "Read/Write Enabled" on textures and meshes unless you need CPU access.
4. **ASTC Compression**: Use ASTC on mobile. Never ship uncompressed textures to mobile devices.
5. **Memory Snapshots**: Take Memory Profiler snapshots before and after scene transitions to detect leaks.
