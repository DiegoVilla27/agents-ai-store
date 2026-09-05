---
name: unity-physics-3d
description: Complete 3D physics mastery for Unity including Rigidbody, CharacterController, ragdolls, joints, SphereCast, collision layers, PhysicsMaterial, and vehicle physics.
author: Diego Villanueva
trigger: When implementing 3D character movement, vehicle physics, ragdolls, physics-based interactions, or 3D projectile systems.
---

# Unity Physics 3D

Unity's 3D physics (PhysX-based) provides production-grade rigid body dynamics, joint systems, and collision detection. Understanding the physics pipeline and when to use Rigidbody vs CharacterController is critical for professional game development.

## 1. Rigidbody vs CharacterController

```text
Rigidbody:                              CharacterController:
- Full physics simulation               - Script-driven movement
- Responds to forces, gravity           - No forces, no gravity (manual)
- Bounces off objects naturally          - Slides along surfaces
- Use for: physics objects, vehicles     - Use for: FPS/TPS characters, NPCs
- Manipulate in FixedUpdate             - Manipulate in Update
```

## 2. Rigidbody Movement

```csharp
// ✅ ALWAYS: Rigidbody manipulation in FixedUpdate
public class PhysicsCharacter : MonoBehaviour
{
    [SerializeField] private float _moveForce = 50f;
    [SerializeField] private float _maxSpeed = 10f;
    [SerializeField] private float _jumpImpulse = 8f;

    private Rigidbody _rb;
    private Vector3 _moveInput;
    private bool _jumpRequested;

    private void Awake() => _rb = GetComponent<Rigidbody>();

    private void Update()
    {
        _moveInput = new Vector3(Input.GetAxisRaw("Horizontal"), 0, Input.GetAxisRaw("Vertical"));
        if (Input.GetButtonDown("Jump")) _jumpRequested = true;
    }

    private void FixedUpdate()
    {
        // Force-based movement (physics-driven, responsive to collisions)
        if (_rb.linearVelocity.magnitude < _maxSpeed)
        {
            _rb.AddForce(_moveInput.normalized * _moveForce, ForceMode.Force);
        }

        if (_jumpRequested && IsGrounded())
        {
            _rb.AddForce(Vector3.up * _jumpImpulse, ForceMode.Impulse);
            _jumpRequested = false;
        }
    }
}
```

## 3. CharacterController Movement

```csharp
// ✅ CharacterController for precise, non-physics movement
public class FPSController : MonoBehaviour
{
    [SerializeField] private float _speed = 8f;
    [SerializeField] private float _gravity = -20f;
    [SerializeField] private float _jumpHeight = 1.5f;

    private CharacterController _cc;
    private Vector3 _velocity;

    private void Awake() => _cc = GetComponent<CharacterController>();

    private void Update()
    {
        // Ground check via CharacterController
        if (_cc.isGrounded && _velocity.y < 0f)
            _velocity.y = -2f; // Small downward force to stay grounded

        // Horizontal movement
        float x = Input.GetAxisRaw("Horizontal");
        float z = Input.GetAxisRaw("Vertical");
        Vector3 move = transform.right * x + transform.forward * z;
        _cc.Move(move.normalized * (_speed * Time.deltaTime));

        // Jump
        if (Input.GetButtonDown("Jump") && _cc.isGrounded)
            _velocity.y = Mathf.Sqrt(_jumpHeight * -2f * _gravity);

        // Gravity
        _velocity.y += _gravity * Time.deltaTime;
        _cc.Move(_velocity * Time.deltaTime);
    }
}
```

## 4. Raycasts & SphereCast (3D)

```csharp
// ✅ ALWAYS: NonAlloc raycasts
private readonly RaycastHit[] _hitBuffer = new RaycastHit[16];

// Precise raycast (hitscan weapons)
public bool RaycastShoot(Vector3 origin, Vector3 direction, float range, out RaycastHit hit)
{
    return Physics.Raycast(origin, direction, out hit, range, _targetLayer,
        QueryTriggerInteraction.Ignore);
}

// SphereCast (melee attacks, bullet with thickness)
public bool SphereCastAttack(Vector3 origin, Vector3 direction, float radius, float range)
{
    int hitCount = Physics.SphereCastNonAlloc(
        origin, radius, direction, _hitBuffer, range, _enemyLayer);

    for (int i = 0; i < hitCount; i++)
    {
        _hitBuffer[i].collider.GetComponent<IDamageable>()?.TakeDamage(25);
    }
    return hitCount > 0;
}

// OverlapSphere (AoE detection)
private readonly Collider[] _overlapBuffer = new Collider[32];

public void ExplosionDamage(Vector3 center, float radius, int damage)
{
    int hitCount = Physics.OverlapSphereNonAlloc(center, radius, _overlapBuffer, _damageableLayer);

    for (int i = 0; i < hitCount; i++)
    {
        var damageable = _overlapBuffer[i].GetComponent<IDamageable>();
        if (damageable == null) continue;

        float distance = Vector3.Distance(center, _overlapBuffer[i].transform.position);
        float falloff = 1f - (distance / radius);
        damageable.TakeDamage(Mathf.RoundToInt(damage * falloff));
    }
}
```

## 5. Physics Materials

```csharp
// ✅ Configure physics materials as assets, not in code
// Create PhysicMaterial assets:
// - Ice.physicMaterial: friction=0, bounciness=0
// - Rubber.physicMaterial: friction=1, bounciness=0.8
// - Metal.physicMaterial: friction=0.4, bounciness=0.2

// Assign to colliders via Inspector or code:
_collider.material = _iceMaterial;
```

## 6. Joints (3D)

```csharp
// ✅ ConfigurableJoint: The most flexible joint
var joint = gameObject.AddComponent<ConfigurableJoint>();
joint.connectedBody = _targetRb;

// Lock rotation axes (hinge-like behavior)
joint.angularXMotion = ConfigurableJointMotion.Free;
joint.angularYMotion = ConfigurableJointMotion.Locked;
joint.angularZMotion = ConfigurableJointMotion.Locked;

// Spring-damper for soft connection
var drive = new JointDrive
{
    positionSpring = 500f,
    positionDamper = 50f,
    maximumForce = Mathf.Infinity
};
joint.xDrive = drive;
joint.yDrive = drive;
joint.zDrive = drive;
```

## 7. Ragdolls

```csharp
// ✅ Toggle ragdoll on/off
public class RagdollController : MonoBehaviour
{
    private Rigidbody[] _ragdollBodies;
    private Collider[] _ragdollColliders;
    private Animator _animator;

    private void Awake()
    {
        _ragdollBodies = GetComponentsInChildren<Rigidbody>();
        _ragdollColliders = GetComponentsInChildren<Collider>();
        _animator = GetComponent<Animator>();
        DisableRagdoll();
    }

    public void EnableRagdoll(Vector3 impactForce, Vector3 impactPoint)
    {
        _animator.enabled = false;
        foreach (var rb in _ragdollBodies)
        {
            rb.isKinematic = false;
            rb.detectCollisions = true;
        }
        // Apply impact force to the closest body part
        var closest = _ragdollBodies
            .OrderBy(rb => Vector3.Distance(rb.position, impactPoint))
            .First();
        closest.AddForce(impactForce, ForceMode.Impulse);
    }

    public void DisableRagdoll()
    {
        foreach (var rb in _ragdollBodies)
        {
            rb.isKinematic = true;
            rb.detectCollisions = false;
        }
        _animator.enabled = true;
    }
}
```

## 8. Collision Layers Strategy

```text
Layer Setup (recommended):
Layer 0:  Default
Layer 6:  Player
Layer 7:  Enemy
Layer 8:  Projectile
Layer 9:  Environment
Layer 10: Trigger
Layer 11: Interactable
Layer 12: Ragdoll

Collision Matrix:
- Player ↔ Environment ✅
- Player ↔ Enemy ✅
- Player ↔ Projectile (enemy) ✅
- Enemy ↔ Projectile (player) ✅
- Projectile ↔ Projectile ❌ (bullets don't collide with each other)
- Ragdoll ↔ Environment ✅
- Ragdoll ↔ Player ❌
```

---

**Execution Protocol**
1. **FixedUpdate for Rigidbody**: ALL `Rigidbody` operations (AddForce, MovePosition, velocity) MUST be in `FixedUpdate`.
2. **CharacterController in Update**: `CharacterController.Move()` runs in `Update` with `Time.deltaTime`.
3. **Interpolation**: Enable `Rigidbody.interpolation = Interpolate` for player-controlled physics objects.
4. **NonAlloc Always**: Use `Physics.RaycastNonAlloc`, `OverlapSphereNonAlloc`, `SphereCastNonAlloc` in production code.
5. **Continuous Collision Detection**: Set `Rigidbody.collisionDetectionMode = ContinuousDynamic` for fast-moving objects (bullets) to prevent tunneling.
