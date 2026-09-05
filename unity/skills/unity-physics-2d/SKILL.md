---
name: unity-physics-2d
description: Complete 2D physics mastery for Unity including Rigidbody2D, Collider2D, triggers, joints, raycasts, OverlapCircle, composite colliders, and collision layers.
author: Diego Villanueva
trigger: When implementing 2D character movement, collisions, triggers, platformer physics, or 2D projectile systems.
---

# Unity Physics 2D

Unity's 2D physics engine (Box2D-based) is fundamentally different from 3D physics. It operates on the XY plane, uses separate components (`Rigidbody2D`, `Collider2D`), and has its own `Physics2D` API. Mixing 2D and 3D physics components on the same GameObject is a catastrophic anti-pattern.

## 1. Rigidbody2D Body Types

```csharp
// Dynamic: Full physics simulation (gravity, forces, collisions)
// Use for: Players, enemies, projectiles, physics objects
rigidbody2D.bodyType = RigidbodyType2D.Dynamic;

// Kinematic: Moved via script, no gravity, collides with Dynamic
// Use for: Moving platforms, elevators, doors
rigidbody2D.bodyType = RigidbodyType2D.Kinematic;

// Static: Never moves, infinite mass
// Use for: Ground, walls, static level geometry
rigidbody2D.bodyType = RigidbodyType2D.Static;
```

## 2. Character Movement (FixedUpdate Only)

```csharp
// ✅ ALWAYS: Physics movement in FixedUpdate
public class PlayerMovement2D : MonoBehaviour
{
    [SerializeField] private float _moveSpeed = 8f;
    [SerializeField] private float _jumpForce = 14f;
    [SerializeField] private LayerMask _groundLayer;

    private Rigidbody2D _rb;
    private Vector2 _moveInput;
    private bool _jumpRequested;

    private void Awake() => _rb = GetComponent<Rigidbody2D>();

    private void Update()
    {
        // Read input in Update (responsive)
        _moveInput.x = Input.GetAxisRaw("Horizontal");
        if (Input.GetButtonDown("Jump")) _jumpRequested = true;
    }

    private void FixedUpdate()
    {
        // Apply movement in FixedUpdate (deterministic)
        _rb.linearVelocity = new Vector2(_moveInput.x * _moveSpeed, _rb.linearVelocity.y);

        if (_jumpRequested && IsGrounded())
        {
            _rb.linearVelocity = new Vector2(_rb.linearVelocity.x, _jumpForce);
            _jumpRequested = false;
        }
    }

    private bool IsGrounded()
    {
        return Physics2D.OverlapCircle(
            _groundCheckPoint.position, 0.15f, _groundLayer);
    }
}

// ❌ NEVER: Move Rigidbody2D in Update
void Update()
{
    _rb.MovePosition(transform.position + movement); // Jittery physics!
}
```

## 3. Ground Detection (Non-Allocating)

```csharp
// ✅ ALWAYS: Use NonAlloc for ground checks
private readonly Collider2D[] _groundBuffer = new Collider2D[4];
private readonly ContactFilter2D _groundFilter = new();

private void Awake()
{
    _groundFilter.SetLayerMask(_groundLayer);
    _groundFilter.useLayerMask = true;
}

public bool IsGrounded()
{
    int hitCount = Physics2D.OverlapCircle(
        _feetPosition.position, 0.1f, _groundFilter, _groundBuffer);
    return hitCount > 0;
}

// ✅ Boxcast for more precise ground detection
public bool IsGroundedBox()
{
    var hit = Physics2D.BoxCast(
        _collider.bounds.center,
        _collider.bounds.size,
        0f,
        Vector2.down,
        0.05f,
        _groundLayer);
    return hit.collider != null;
}
```

## 4. Raycasts & Linecasts

```csharp
// ✅ ALWAYS: Use NonAlloc raycasts
private readonly RaycastHit2D[] _rayBuffer = new RaycastHit2D[8];

public bool CanSeePlayer(Vector2 direction, float distance)
{
    int hitCount = Physics2D.RaycastNonAlloc(
        transform.position, direction, _rayBuffer, distance, _visionLayer);

    for (int i = 0; i < hitCount; i++)
    {
        if (_rayBuffer[i].collider.CompareTag("Player"))
            return true;
        if (_rayBuffer[i].collider.gameObject.layer == _wallLayer)
            return false; // Wall blocks vision
    }
    return false;
}

// ✅ CircleCast for wider detection (melee attack range)
public Collider2D DetectMeleeTarget()
{
    var hit = Physics2D.CircleCast(
        _attackPoint.position, _attackRadius, Vector2.zero, 0f, _enemyLayer);
    return hit.collider;
}
```

## 5. Triggers & Collision Callbacks

```csharp
// ✅ ALWAYS: Use collision layers instead of string tags
private void OnTriggerEnter2D(Collider2D other)
{
    // ❌ NEVER: String comparison
    // if (other.tag == "Coin") { ... }

    // ✅ ALWAYS: Layer mask comparison
    if (((1 << other.gameObject.layer) & _collectibleLayer) != 0)
    {
        CollectItem(other.GetComponent<ICollectible>());
    }
}

// ✅ Contact filter for selective collision
private void OnCollisionEnter2D(Collision2D collision)
{
    // Check if we landed on top of something (platformer)
    foreach (var contact in collision.contacts)
    {
        if (contact.normal.y > 0.7f) // Surface is mostly facing up
        {
            _isGrounded = true;
            break;
        }
    }
}
```

## 6. Joints 2D

```csharp
// ✅ Common joint configurations
// HingeJoint2D: Doors, rotating platforms, chains
var hinge = gameObject.AddComponent<HingeJoint2D>();
hinge.connectedBody = _anchorRb;
hinge.useLimits = true;
hinge.limits = new JointAngleLimits2D { min = -45f, max = 45f };

// SpringJoint2D: Elastic connections, grappling hooks
var spring = gameObject.AddComponent<SpringJoint2D>();
spring.connectedBody = _targetRb;
spring.distance = 3f;
spring.frequency = 4f;
spring.dampingRatio = 0.5f;

// DistanceJoint2D: Fixed-length ropes, chains
var dist = gameObject.AddComponent<DistanceJoint2D>();
dist.connectedBody = _anchorRb;
dist.maxDistanceOnly = true; // Can be closer, not farther
```

## 7. Composite Collider & Tilemap Physics

```csharp
// ✅ For tilemaps: Use CompositeCollider2D to merge tile colliders
// On the Tilemap GameObject:
// 1. TilemapCollider2D (Used By Composite = true)
// 2. CompositeCollider2D (Geometry Type = Polygons)
// 3. Rigidbody2D (Body Type = Static)
// This merges hundreds of individual tile colliders into optimized polygon shapes
```

## 8. Effectors 2D

```csharp
// ✅ Platform Effector 2D: One-way platforms
// On the platform collider:
// 1. BoxCollider2D (Used By Effector = true)
// 2. PlatformEffector2D (Use One Way = true, Surface Arc = 180°)

// ✅ Area Effector 2D: Wind zones, water currents
// 1. Collider2D (Is Trigger = true, Used By Effector = true)
// 2. AreaEffector2D (Force Angle = 90°, Force Magnitude = 5f)

// ✅ Buoyancy Effector 2D: Water buoyancy
// 1. Collider2D (Is Trigger = true, Used By Effector = true)
// 2. BuoyancyEffector2D (Surface Level = 0.5f, Density = 1f)
```

---

**Execution Protocol**
1. **FixedUpdate for Physics**: ALL Rigidbody2D manipulation (velocity, forces, MovePosition) MUST happen in `FixedUpdate()`.
2. **Layer Matrix Configuration**: Configure collision layers in Edit → Project Settings → Physics 2D. NEVER rely on tag-based filtering.
3. **NonAlloc Overloads**: ALWAYS use `Physics2D.RaycastNonAlloc`, `OverlapCircleNonAlloc`, etc. to avoid per-call GC allocations.
4. **Interpolation**: Set `Rigidbody2D.interpolation = RigidbodyInterpolation2D.Interpolate` for player-controlled objects to smooth visual movement between physics steps.
