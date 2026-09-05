---
name: unity-vfx-graph-particles
description: Visual Effect Graph and legacy Particle System mastery for Unity including GPU particles, spawn/update contexts, texture sheets, trails, mesh particles, and pooled VFX.
author: Diego Villanueva
trigger: When creating particle effects, explosions, magic spells, environmental VFX, trail effects, or high-performance GPU particle systems.
---

# VFX Graph & Particle System

Unity provides two particle systems: the legacy **Particle System** (Shuriken) for CPU-driven particles, and the **VFX Graph** for GPU-driven, high-count particle simulations. Choose based on particle count and complexity.

## 1. When to Use Each

```text
Particle System (CPU):                   VFX Graph (GPU):
- < 10,000 particles                    - 100,000+ particles
- Physics interactions needed            - No physics collisions
- Mobile-friendly                        - Desktop/Console only
- Simple effects (sparks, dust)          - Complex simulations (fire, smoke, magic)
- Mesh particle emission                 - Point cache / SDF emission
- Supported on all platforms             - Requires compute shaders
```

## 2. VFX Graph Architecture

```text
VFX Graph Contexts (execution order):
├── Spawn Context       → How many particles to create per frame
├── Initialize Context  → Set initial values (position, velocity, color, lifetime)
├── Update Context      → Modify particles each frame (forces, noise, collision)
└── Output Context      → How to render (billboard, mesh, trail, strip)

Data Flow:
- Blocks: Individual operations within a context
- Properties: Exposed parameters (controlled from C#)
- Subgraphs: Reusable VFX modules
```

```csharp
// ✅ Control VFX Graph from C#
using UnityEngine.VFX;

public class VFXController : MonoBehaviour
{
    [SerializeField] private VisualEffect _vfx;

    public void SetSpawnRate(float rate) => _vfx.SetFloat("SpawnRate", rate);
    public void SetColor(Color color) => _vfx.SetVector4("ParticleColor", color);
    public void SetPosition(Vector3 pos) => _vfx.SetVector3("SpawnPosition", pos);

    public void PlayBurst()
    {
        _vfx.SendEvent("OnBurst"); // Trigger a GPU Event in the graph
    }

    public void Stop()
    {
        _vfx.Stop();
        // Optionally wait for particles to die
        // _vfx.SetFloat("SpawnRate", 0); // Graceful stop
    }
}
```

## 3. Particle System (Shuriken) — Key Modules

```csharp
// ✅ Create optimized particle systems via code
public ParticleSystem CreateExplosion(Vector3 position)
{
    var ps = Instantiate(_explosionPrefab, position, Quaternion.identity);
    var main = ps.main;
    main.startLifetime = 0.8f;
    main.startSpeed = new ParticleSystem.MinMaxCurve(5f, 15f);
    main.startSize = new ParticleSystem.MinMaxCurve(0.1f, 0.5f);
    main.startColor = new ParticleSystem.MinMaxGradient(Color.yellow, Color.red);
    main.simulationSpace = ParticleSystemSimulationSpace.World;
    main.maxParticles = 200;

    var emission = ps.emission;
    emission.rateOverTime = 0; // No continuous emission
    emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 100) }); // Burst of 100

    var shape = ps.shape;
    shape.shapeType = ParticleSystemShapeType.Sphere;
    shape.radius = 0.5f;

    var sizeOverLifetime = ps.sizeOverLifetime;
    sizeOverLifetime.enabled = true;
    sizeOverLifetime.size = new ParticleSystem.MinMaxCurve(1f,
        new AnimationCurve(new Keyframe(0f, 1f), new Keyframe(1f, 0f)));

    var colorOverLifetime = ps.colorOverLifetime;
    colorOverLifetime.enabled = true;
    var gradient = new Gradient();
    gradient.SetKeys(
        new[] { new GradientColorKey(Color.white, 0f), new GradientColorKey(Color.red, 1f) },
        new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0f, 1f) });
    colorOverLifetime.color = gradient;

    ps.Play();
    return ps;
}
```

## 4. Particle Pooling

```csharp
// ✅ ALWAYS: Pool VFX instead of Instantiate/Destroy
public class VFXPool : MonoBehaviour
{
    [SerializeField] private ParticleSystem _prefab;
    [SerializeField] private int _poolSize = 20;

    private Queue<ParticleSystem> _pool = new();

    private void Awake()
    {
        for (int i = 0; i < _poolSize; i++)
        {
            var ps = Instantiate(_prefab, transform);
            ps.gameObject.SetActive(false);
            _pool.Enqueue(ps);
        }
    }

    public ParticleSystem Spawn(Vector3 position, Quaternion rotation)
    {
        if (_pool.Count == 0) return null;
        var ps = _pool.Dequeue();
        ps.transform.SetPositionAndRotation(position, rotation);
        ps.gameObject.SetActive(true);
        ps.Play();
        StartCoroutine(ReturnAfterDone(ps));
        return ps;
    }

    private IEnumerator ReturnAfterDone(ParticleSystem ps)
    {
        yield return new WaitUntil(() => !ps.isPlaying);
        ps.gameObject.SetActive(false);
        _pool.Enqueue(ps);
    }
}

// ❌ NEVER: Instantiate VFX on every hit/explosion
void OnHit() => Instantiate(explosionVFX, hitPoint, Quaternion.identity); // GC HELL
```

## 5. Trail Renderers & Particle Trails

```csharp
// ✅ Trail configuration for projectiles
// On the projectile prefab:
// TrailRenderer component:
//   - Time: 0.3f (trail duration)
//   - Width: AnimationCurve (1.0 → 0.0, tapers)
//   - Color: Gradient (bright → transparent)
//   - Min Vertex Distance: 0.1f
//   - Material: Additive/Unlit trail material

// ✅ Clear trail on pool reuse
public void OnSpawn()
{
    _trailRenderer.Clear(); // CRITICAL: prevents ghost trails from pool
    gameObject.SetActive(true);
}
```

## 6. Sub Emitters & Collision

```text
Sub Emitters:
- On Birth: Spawn sparks when firework launches
- On Collision: Spawn debris when particle hits surface
- On Death: Spawn explosion when particle expires

Collision Module:
- World collision for rain/snow hitting surfaces
- Planes for simple bounds
- Trigger module for entering/exiting volumes
```

---

**Execution Protocol**
1. **Pool ALL VFX**: NEVER `Instantiate`/`Destroy` particle systems at runtime. Use object pooling.
2. **World Space for Detached Effects**: Explosions, impacts, and environmental VFX use `SimulationSpace.World`. Attached effects (aura, trail) use `SimulationSpace.Local`.
3. **VFX Graph for High Count**: If you need >10K particles or complex GPU simulation, use VFX Graph. For simple effects, Particle System is lighter.
4. **Clear Trails on Reuse**: ALWAYS call `TrailRenderer.Clear()` when reusing pooled objects with trails.
5. **Prewarm Persistent Effects**: Enable `Prewarm` on looping effects (fire, waterfall) so they appear fully formed on scene load.
