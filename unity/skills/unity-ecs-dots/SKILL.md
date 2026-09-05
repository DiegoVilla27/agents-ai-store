---
name: unity-ecs-dots
description: Entity Component System and Data-Oriented Technology Stack for Unity including Entities, Systems, IComponentData, Burst-compiled jobs, chunk iteration, and ECS worlds.
author: Diego Villanueva
trigger: When building systems that require processing thousands of entities efficiently, using ECS architecture, or leveraging DOTS for performance-critical simulations.
---

# ECS & DOTS (Data-Oriented Technology Stack)

Unity's ECS (Entity Component System) with DOTS is a paradigm shift from traditional MonoBehaviour OOP to data-oriented, cache-friendly, Burst-compiled architectures. Use ECS when you need to process 10,000+ entities at 60+ FPS (crowds, bullets, particles, terrain chunks, AI agents).

## 1. ECS Core Concepts

```text
Traditional OOP:  GameObject → MonoBehaviour (data + behavior)
ECS:              Entity     → Component (pure data) + System (pure logic)

Key differences:
- Components are STRUCTS (value types), tightly packed in memory chunks
- Systems iterate over components in cache-friendly linear order
- Burst compiles systems to SIMD-optimized native code
- Jobs parallelize system execution across CPU cores
```

## 2. Defining Components (Pure Data)

Components are blittable structs implementing `IComponentData`. They contain ONLY data — zero methods, zero logic.

```csharp
// ✅ ALWAYS: Components are pure data structs
public struct Position : IComponentData
{
    public float3 Value;
}

public struct Velocity : IComponentData
{
    public float3 Value;
}

public struct Health : IComponentData
{
    public int Current;
    public int Max;
}

public struct EnemyTag : IComponentData { } // Zero-size tag component for filtering

// Managed components (for referencing UnityEngine objects)
public class PrefabReference : IComponentData
{
    public GameObject Prefab; // Managed — use sparingly
}
```

## 3. Creating Entities (Baker)

Bakers convert GameObjects (authoring data) into ECS Entities at bake time.

```csharp
// ✅ Authoring component (MonoBehaviour on the authoring GameObject)
public class EnemyAuthoring : MonoBehaviour
{
    public float moveSpeed = 5f;
    public int maxHealth = 100;
}

// ✅ Baker: converts authoring data to ECS components
public class EnemyBaker : Baker<EnemyAuthoring>
{
    public override void Bake(EnemyAuthoring authoring)
    {
        var entity = GetEntity(TransformUsageFlags.Dynamic);

        AddComponent(entity, new Velocity { Value = float3.zero });
        AddComponent(entity, new Health { Current = authoring.maxHealth, Max = authoring.maxHealth });
        AddComponent(entity, new MoveSpeed { Value = authoring.moveSpeed });
        AddComponent<EnemyTag>(entity);
    }
}
```

## 4. Systems (Pure Logic)

Systems contain ALL the logic. They query for entities with specific component combinations and process them.

```csharp
// ✅ ALWAYS: Systems process components, not entities
[BurstCompile]
public partial struct MovementSystem : ISystem
{
    [BurstCompile]
    public void OnUpdate(ref SystemState state)
    {
        float dt = SystemAPI.Time.DeltaTime;

        // Idiomatic foreach with RefRW/RefRO
        foreach (var (transform, velocity) in
            SystemAPI.Query<RefRW<LocalTransform>, RefRO<Velocity>>())
        {
            transform.ValueRW.Position += velocity.ValueRO.Value * dt;
        }
    }
}

// ✅ Parallel job for massive entity counts
[BurstCompile]
public partial struct BoidFlockingSystem : ISystem
{
    [BurstCompile]
    public void OnUpdate(ref SystemState state)
    {
        var job = new BoidFlockingJob
        {
            DeltaTime = SystemAPI.Time.DeltaTime
        };

        state.Dependency = job.ScheduleParallel(state.Dependency);
    }
}

[BurstCompile]
public partial struct BoidFlockingJob : IJobEntity
{
    public float DeltaTime;

    public void Execute(ref LocalTransform transform, in Velocity velocity, in BoidSettings settings)
    {
        transform.Position += velocity.Value * DeltaTime;
    }
}
```

## 5. Querying Entities (EntityQuery)

```csharp
// ✅ SystemAPI.Query — modern, type-safe
foreach (var (health, entity) in
    SystemAPI.Query<RefRW<Health>>()
        .WithAll<EnemyTag>()              // Must have EnemyTag
        .WithNone<DeadTag>()              // Must NOT have DeadTag
        .WithEntityAccess())              // Also get the Entity reference
{
    if (health.ValueRO.Current <= 0)
    {
        state.EntityManager.AddComponent<DeadTag>(entity);
    }
}
```

## 6. Structural Changes (EntityCommandBuffer)

Structural changes (creating/destroying entities, adding/removing components) cannot happen during iteration. Use `EntityCommandBuffer` (ECB).

```csharp
// ✅ ALWAYS: Use ECB for structural changes
[BurstCompile]
public partial struct DamageSystem : ISystem
{
    [BurstCompile]
    public void OnUpdate(ref SystemState state)
    {
        var ecb = new EntityCommandBuffer(Allocator.TempJob);

        foreach (var (health, entity) in
            SystemAPI.Query<RefRW<Health>>()
                .WithAll<DamageEvent>()
                .WithEntityAccess())
        {
            health.ValueRW.Current -= 10;

            if (health.ValueRO.Current <= 0)
            {
                ecb.AddComponent<DeadTag>(entity);
                ecb.RemoveComponent<DamageEvent>(entity);
            }
        }

        ecb.Playback(state.EntityManager);
        ecb.Dispose();
    }
}
```

## 7. Hybrid Approach (ECS + MonoBehaviours)

Not everything needs ECS. Use ECS for high-volume data processing and MonoBehaviours for everything else.

```text
✅ USE ECS FOR:                      ✅ USE MONOBEHAVIOURS FOR:
- 1000+ bullets/projectiles          - Player controller (single entity)
- Crowd simulation (10K+ NPCs)      - Camera controller
- Terrain chunk processing           - UI systems
- Particle/VFX simulation            - Audio management
- Spatial queries (broad phase)      - Scene management
- Physics batching                   - Input handling
```

---

**Execution Protocol**
1. **Profile First**: Only move systems to ECS when MonoBehaviour performance is insufficient. ECS adds complexity.
2. **Components are Data, Systems are Logic**: NEVER put methods on `IComponentData` structs. NEVER store data in Systems.
3. **Burst-Compile Everything**: Every `ISystem` and `IJobEntity` MUST have `[BurstCompile]` unless they access managed types.
4. **ECB for Structural Changes**: NEVER call `EntityManager.CreateEntity` or `AddComponent` during a query iteration.
5. **Dispose NativeContainers**: Every `NativeArray`, `NativeList`, or `EntityCommandBuffer` MUST be disposed after use.
