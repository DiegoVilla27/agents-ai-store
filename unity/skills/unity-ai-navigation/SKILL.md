---
name: unity-ai-navigation
description: NavMesh navigation and pathfinding mastery for Unity including NavMeshAgent, NavMeshSurface, OffMeshLinks, area costs, obstacle avoidance, and A* Pathfinding integration.
author: Diego Villanueva
trigger: When implementing AI pathfinding, NavMesh navigation, obstacle avoidance, patrol routes, or dynamic navigation mesh generation.
---

# AI Navigation (NavMesh)

Unity's NavMesh system provides automatic pathfinding on baked navigation surfaces. It handles obstacle avoidance, area-based costs, and off-mesh links for jumps and drops. For more control, integrate A* Pathfinding Project.

## 1. NavMesh Setup (NavMeshSurface)

```text
Modern workflow (com.unity.ai.navigation package):
1. Add NavMeshSurface component to a parent GameObject
2. Configure Agent Type (humanoid size, step height, slope)
3. Click "Bake" to generate NavMesh
4. Add NavMeshAgent to AI characters

✅ NavMeshSurface Settings:
├── Agent Type: Humanoid (radius 0.5, height 2.0)
├── Collect Objects: All / Volume / Children
├── Include Layers: Environment, Ground
├── Use Geometry: Render Meshes or Physics Colliders
└── Default Area: Walkable
```

```csharp
// ✅ Runtime NavMesh baking (procedural levels)
using Unity.AI.Navigation;

public class DynamicNavMesh : MonoBehaviour
{
    [SerializeField] private NavMeshSurface _surface;

    public void RebakeNavMesh()
    {
        _surface.BuildNavMesh(); // Synchronous bake
    }

    public async Awaitable RebakeNavMeshAsync()
    {
        var data = await _surface.UpdateNavMesh(_surface.navMeshData);
        // NavMesh updated without blocking main thread
    }
}
```

## 2. NavMeshAgent (AI Movement)

```csharp
// ✅ Basic AI navigation
public class EnemyAI : MonoBehaviour
{
    [SerializeField] private NavMeshAgent _agent;
    [SerializeField] private float _chaseRange = 15f;
    [SerializeField] private float _attackRange = 2f;
    [SerializeField] private float _patrolSpeed = 2f;
    [SerializeField] private float _chaseSpeed = 5f;

    private Transform _player;

    public void SetDestination(Vector3 target)
    {
        _agent.SetDestination(target);
    }

    public void Chase(Transform target)
    {
        _agent.speed = _chaseSpeed;
        _agent.SetDestination(target.position);
    }

    public void Patrol(Vector3 waypoint)
    {
        _agent.speed = _patrolSpeed;
        _agent.SetDestination(waypoint);
    }

    public bool HasReachedDestination()
    {
        return !_agent.pathPending
            && _agent.remainingDistance <= _agent.stoppingDistance
            && (!_agent.hasPath || _agent.velocity.sqrMagnitude < 0.01f);
    }

    public void Stop()
    {
        _agent.ResetPath();
        _agent.velocity = Vector3.zero;
    }
}
```

## 3. Patrol System (Waypoints)

```csharp
// ✅ Waypoint patrol with NavMeshAgent
public class PatrolBehavior : MonoBehaviour
{
    [SerializeField] private Transform[] _waypoints;
    [SerializeField] private float _waitTime = 2f;
    [SerializeField] private NavMeshAgent _agent;

    private int _currentWaypoint;
    private float _waitTimer;

    private void Update()
    {
        if (_agent.remainingDistance <= _agent.stoppingDistance)
        {
            _waitTimer += Time.deltaTime;
            if (_waitTimer >= _waitTime)
            {
                _currentWaypoint = (_currentWaypoint + 1) % _waypoints.Length;
                _agent.SetDestination(_waypoints[_currentWaypoint].position);
                _waitTimer = 0f;
            }
        }
    }
}
```

## 4. NavMesh Areas & Costs

```text
✅ Define area costs for intelligent pathfinding:
Area 0: Walkable      (cost 1.0) — Default ground
Area 1: Not Walkable  (cost ∞)   — Walls, obstacles
Area 2: Road          (cost 0.5) — Preferred path (faster)
Area 3: Mud           (cost 3.0) — Slow, avoided when possible
Area 4: Water         (cost 5.0) — Very slow, dangerous
Area 5: Restricted    (cost 10)  — Only used as last resort

// Agents will automatically prefer lower-cost paths
```

```csharp
// ✅ Set area cost per agent (different AI archetypes)
_agent.SetAreaCost(NavMesh.GetAreaFromName("Water"), 1f);  // Amphibious enemy: water is easy
_agent.SetAreaCost(NavMesh.GetAreaFromName("Road"), 0.1f); // Vehicle: prefers roads heavily
```

## 5. NavMeshObstacle (Dynamic Obstacles)

```csharp
// ✅ NavMeshObstacle: Carve holes in NavMesh at runtime
// Use for: Destructible walls, moving barriers, parked vehicles

// On the obstacle GameObject:
// NavMeshObstacle component:
//   Shape: Box or Capsule
//   Carve: ✅ (cuts a hole in NavMesh)
//   Move Threshold: 0.1 (re-carve when moved)
//   Time To Stationary: 0.5 (wait before carving)
//   Carve Only Stationary: ✅ (don't carve while moving)
```

## 6. OffMeshLinks (Jumps, Drops, Ladders)

```text
Setup:
1. Create empty GameObjects at start/end positions of the link
2. Add OffMeshLink component
3. Configure:
   - Start: Transform at jump origin
   - End: Transform at landing position
   - Bi-Directional: ✅ (for ladders) or ❌ (for drops)
   - Area Type: "Jump" (custom area with cost)
   - Auto Traverse: ❌ (handle animation manually)
```

```csharp
// ✅ Manual OffMeshLink traversal with animation
public class OffMeshLinkHandler : MonoBehaviour
{
    [SerializeField] private NavMeshAgent _agent;
    [SerializeField] private Animator _animator;

    private static readonly int JumpTrigger = Animator.StringToHash("Jump");

    private IEnumerator TraverseOffMeshLink()
    {
        _agent.autoTraversal = false;

        while (_agent.isOnOffMeshLink)
        {
            var link = _agent.currentOffMeshLinkData;
            Vector3 start = link.startPos;
            Vector3 end = link.endPos;

            _animator.SetTrigger(JumpTrigger);
            float duration = 0.5f;
            float elapsed = 0f;

            while (elapsed < duration)
            {
                float t = elapsed / duration;
                Vector3 pos = Vector3.Lerp(start, end, t);
                pos.y += Mathf.Sin(t * Mathf.PI) * 2f; // Arc
                transform.position = pos;
                elapsed += Time.deltaTime;
                yield return null;
            }

            _agent.CompleteOffMeshLink();
        }
    }
}
```

---

**Execution Protocol**
1. **NavMeshSurface Package**: Use `com.unity.ai.navigation` package, not the legacy bake workflow.
2. **Runtime Rebake for Procedural**: Call `NavMeshSurface.BuildNavMesh()` after generating procedural levels.
3. **Area Costs for Smart AI**: Define custom area types (Road, Mud, Water) and assign costs so AI naturally avoids hazards.
4. **Stopping Distance**: ALWAYS set `NavMeshAgent.stoppingDistance` > 0 to prevent jittering at the destination.
5. **NavMeshObstacle Carving**: Use `Carve Only Stationary` to prevent performance issues from constant re-baking.
