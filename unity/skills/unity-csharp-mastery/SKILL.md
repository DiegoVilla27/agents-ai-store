---
name: unity-csharp-mastery
description: Advanced C# patterns for Unity including Jobs System, Burst Compiler, Span, NativeContainers, async/await with Awaitable, and zero-allocation coding techniques.
author: Diego Villanueva
trigger: When writing performance-critical C# code, using Jobs/Burst, managing memory, or choosing between coroutines and async/await in Unity.
---

# C# Mastery for Unity

Unity runs on a modified Mono/.NET runtime. Writing "normal" C# without understanding Unity's memory model, garbage collector behavior, and threading constraints leads to frame drops, GC spikes, and crashes. This document enforces high-performance C# patterns for game development.

## 1. Value Types vs Reference Types (GC Pressure)

The Unity garbage collector is non-generational and stop-the-world. Every `new` on a reference type (class) allocates on the managed heap and eventually triggers a GC spike (frame hitch).

```csharp
// ❌ NEVER: Allocating in hot paths (Update/FixedUpdate)
void Update()
{
    var enemies = new List<Enemy>(); // GC ALLOC EVERY FRAME!
    var message = $"HP: {health}";   // String allocation every frame!
    var ray = new Ray(transform.position, transform.forward); // This is OK — Ray is a struct
}

// ✅ ALWAYS: Pre-allocate and reuse
private readonly List<Enemy> _enemyBuffer = new(64);
private readonly StringBuilder _sb = new(128);
private readonly Collider[] _hitBuffer = new Collider[32];

void Update()
{
    _enemyBuffer.Clear(); // Reuse, don't reallocate
    _sb.Clear();
    _sb.Append("HP: ").Append(health);
    
    int hitCount = Physics.OverlapSphereNonAlloc(pos, radius, _hitBuffer); // Zero alloc
}
```

## 2. Span<T> and Stackalloc (Zero-Allocation Slicing)

`Span<T>` allows you to work with contiguous memory without heap allocations. Use `stackalloc` for small, short-lived buffers.

```csharp
// ✅ ALWAYS: Use Span for zero-allocation string parsing
public static bool TryParseVector3(ReadOnlySpan<char> input, out Vector3 result)
{
    result = Vector3.zero;
    Span<Range> ranges = stackalloc Range[3];
    int count = input.Split(ranges, ',');
    if (count != 3) return false;

    return float.TryParse(input[ranges[0]], out result.x)
        && float.TryParse(input[ranges[1]], out result.y)
        && float.TryParse(input[ranges[2]], out result.z);
}

// ✅ Use stackalloc for small temporary buffers
public void ProcessNearbyTargets(Vector3 position, float radius)
{
    Span<int> targetIds = stackalloc int[16];
    int count = FindTargetsNonAlloc(position, radius, targetIds);
    
    for (int i = 0; i < count; i++)
        ProcessTarget(targetIds[i]);
}
```

## 3. Jobs System & Burst Compiler

The C# Job System allows you to write multithreaded code that is safe by construction. Burst compiles your jobs to highly optimized native SIMD code.

```csharp
// ✅ ALWAYS: Use IJobParallelFor for data-parallel work
[BurstCompile]
public struct BoidMovementJob : IJobParallelFor
{
    [ReadOnly] public NativeArray<float3> Positions;
    [ReadOnly] public NativeArray<float3> Velocities;
    public NativeArray<float3> NewVelocities;
    public float DeltaTime;
    public float SeparationRadius;
    public float CohesionWeight;

    public void Execute(int index)
    {
        float3 separation = float3.zero;
        float3 cohesion = float3.zero;
        int neighborCount = 0;

        for (int i = 0; i < Positions.Length; i++)
        {
            if (i == index) continue;
            float dist = math.distance(Positions[index], Positions[i]);
            if (dist < SeparationRadius)
            {
                separation += math.normalize(Positions[index] - Positions[i]) / dist;
                cohesion += Positions[i];
                neighborCount++;
            }
        }

        if (neighborCount > 0)
        {
            cohesion = (cohesion / neighborCount - Positions[index]) * CohesionWeight;
        }

        NewVelocities[index] = Velocities[index] + (separation + cohesion) * DeltaTime;
    }
}

// Schedule the job
var job = new BoidMovementJob
{
    Positions = _positions,
    Velocities = _velocities,
    NewVelocities = _newVelocities,
    DeltaTime = Time.deltaTime,
    SeparationRadius = 2f,
    CohesionWeight = 0.5f
};
JobHandle handle = job.Schedule(_positions.Length, 64); // batch size 64
handle.Complete();
```

## 4. NativeContainers (Unmanaged Memory)

NativeContainers (`NativeArray`, `NativeList`, `NativeHashMap`) allocate on unmanaged memory, bypassing the GC entirely. They are mandatory for Jobs and Burst.

```csharp
// ✅ ALWAYS: Use NativeContainers for large data processed by Jobs
private NativeArray<float3> _positions;
private NativeArray<float3> _velocities;

private void Awake()
{
    _positions = new NativeArray<float3>(1000, Allocator.Persistent);
    _velocities = new NativeArray<float3>(1000, Allocator.Persistent);
}

private void OnDestroy()
{
    // CRITICAL: You MUST dispose NativeContainers or you WILL leak memory
    if (_positions.IsCreated) _positions.Dispose();
    if (_velocities.IsCreated) _velocities.Dispose();
}
```

## 5. Async/Await in Unity (Awaitable)

Unity 6+ introduces `Awaitable`, a first-class async primitive that is lifecycle-aware and cancellation-safe.

```csharp
// ✅ Unity 6+: Use Awaitable (not Task)
public class LevelLoader : MonoBehaviour
{
    public async Awaitable LoadLevelAsync(string sceneName)
    {
        var ct = destroyCancellationToken; // Auto-cancelled when GameObject is destroyed

        // Show loading screen
        _loadingUI.SetActive(true);

        await Awaitable.WaitForSecondsAsync(0.5f, ct); // Frame-accurate delay

        var op = SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Additive);
        while (!op.isDone)
        {
            _progressBar.value = op.progress;
            await Awaitable.NextFrameAsync(ct);
        }

        _loadingUI.SetActive(false);
    }
}

// ❌ NEVER: async void (exceptions vanish, no cancellation)
private async void LoadLevel() { /* DANGEROUS */ }

// ❌ NEVER: Task.Run in Unity (runs off main thread, cannot touch Unity API)
await Task.Run(() => transform.position = Vector3.zero); // CRASH!
```

## 6. Coroutines (When to Use)

Coroutines are still valid for simple frame-based sequences where async/await is overkill.

```csharp
// ✅ Coroutines for simple visual sequences
private IEnumerator FlashDamage()
{
    _spriteRenderer.color = Color.red;
    yield return _waitFlash; // Cache WaitForSeconds!
    _spriteRenderer.color = Color.white;
}

// ✅ ALWAYS: Cache YieldInstructions to avoid GC
private static readonly WaitForSeconds _waitFlash = new(0.1f);
private static readonly WaitForEndOfFrame _waitEndOfFrame = new();
private static readonly WaitForFixedUpdate _waitFixed = new();
```

## 7. Extension Methods (Fluent Unity API)

```csharp
// ✅ Useful Vector extensions (zero allocation)
public static class VectorExtensions
{
    public static Vector3 WithX(this Vector3 v, float x) => new(x, v.y, v.z);
    public static Vector3 WithY(this Vector3 v, float y) => new(v.x, y, v.z);
    public static Vector3 WithZ(this Vector3 v, float z) => new(v.x, v.y, z);
    public static Vector3 Flat(this Vector3 v) => new(v.x, 0f, v.z);
    public static Vector2 ToXZ(this Vector3 v) => new(v.x, v.z);
}

// ✅ Transform extensions
public static class TransformExtensions
{
    public static void LookAtSmooth(this Transform t, Vector3 target, float speed)
    {
        var dir = (target - t.position).Flat();
        if (dir.sqrMagnitude < 0.001f) return;
        var rot = Quaternion.LookRotation(dir);
        t.rotation = Quaternion.Slerp(t.rotation, rot, speed * Time.deltaTime);
    }
}
```

## 8. Hashing Strings (Animator & Shader Parameters)

```csharp
// ❌ NEVER: String lookups every frame
animator.SetBool("IsRunning", true);     // String hash computed every call
material.SetFloat("_Dissolve", value);   // Same problem

// ✅ ALWAYS: Pre-hash parameter names
private static readonly int IsRunning = Animator.StringToHash("IsRunning");
private static readonly int Dissolve = Shader.PropertyToID("_Dissolve");

animator.SetBool(IsRunning, true);       // Integer lookup — zero allocation
material.SetFloat(Dissolve, value);
```

---

**Execution Protocol**
1. **Profile Before Optimizing**: Use the Unity Profiler to identify actual bottlenecks before applying Jobs/Burst. Premature optimization is the root of all evil.
2. **Dispose NativeContainers**: Every `NativeArray`, `NativeList`, or `NativeHashMap` MUST be disposed in `OnDestroy` or via `using` statements.
3. **Cache Everything**: WaitForSeconds, material property IDs, component references, and buffer arrays must be cached as fields, never allocated in hot paths.
4. **Zero Allocation in Update**: The `Update()`, `FixedUpdate()`, and `LateUpdate()` methods must produce ZERO managed allocations in release builds.
