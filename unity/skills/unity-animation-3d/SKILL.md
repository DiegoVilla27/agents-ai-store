---
name: unity-animation-3d
description: Complete 3D animation mastery for Unity including Mecanim, Animator state machines, blend trees, Avatar masks, IK, Animation Rigging, root motion, and animation layers.
author: Diego Villanueva
trigger: When implementing 3D character animations, blend trees, inverse kinematics, root motion, or layered animation systems.
---

# Unity 3D Animation (Mecanim)

Unity's Mecanim system provides production-grade 3D animation with humanoid retargeting, blend trees, IK, animation layers, and state machine behaviors. Understanding the animation pipeline from import to runtime is critical.

## 1. Animation Import Settings

```text
Model Import:
├── Rig Tab
│   ├── Animation Type: Humanoid (for retargetable characters)
│   ├── Avatar Definition: Create From This Model
│   └── Configure Avatar: Map bones to Unity's humanoid skeleton
├── Animation Tab
│   ├── Loop Time: ✅ (for idle, walk, run)
│   ├── Root Transform Rotation: Bake Into Pose (for non-rotating anims)
│   ├── Root Transform Position (Y): Based Upon → Feet
│   └── Root Transform Position (XZ): Based Upon → Center of Mass
└── Materials Tab: Extract Materials to separate folder
```

## 2. Animator Controller Architecture

```csharp
// ✅ ALWAYS: Organize Animator Controller with layers
// Base Layer: Locomotion (idle, walk, run, jump, fall)
// Upper Body Layer (AvatarMask): Attack, Reload, Wave (overrides upper body only)
// Full Body Override Layer: Death, Hit Reaction (overrides everything)

private static readonly int Speed = Animator.StringToHash("Speed");
private static readonly int IsGrounded = Animator.StringToHash("IsGrounded");
private static readonly int VerticalVelocity = Animator.StringToHash("VerticalVelocity");
private static readonly int AttackTrigger = Animator.StringToHash("Attack");
private static readonly int HitTrigger = Animator.StringToHash("Hit");

public class CharacterAnimator : MonoBehaviour
{
    [SerializeField] private Animator _animator;

    public void UpdateLocomotion(float speed, bool grounded, float verticalVel)
    {
        _animator.SetFloat(Speed, speed, 0.1f, Time.deltaTime); // Damp for smooth blend
        _animator.SetBool(IsGrounded, grounded);
        _animator.SetFloat(VerticalVelocity, verticalVel);
    }

    public void PlayAttack() => _animator.SetTrigger(AttackTrigger);
    public void PlayHitReaction() => _animator.SetTrigger(HitTrigger);
}
```

## 3. Blend Trees

```text
✅ 1D Blend Tree (Locomotion):
Parameter: Speed (float 0-1)
  0.0 → Idle
  0.5 → Walk
  1.0 → Run

✅ 2D Freeform Directional (Strafing):
Parameters: VelocityX, VelocityZ
  (0, 0)   → Idle
  (0, 1)   → Walk Forward
  (0, -1)  → Walk Backward
  (1, 0)   → Strafe Right
  (-1, 0)  → Strafe Left

✅ 2D Freeform Cartesian (Directional slopes):
Parameters: Speed, Slope
```

## 4. Root Motion vs In-Place Animation

```csharp
// Root Motion: Animation drives character position (realistic movement)
// Requires: Animator.applyRootMotion = true
// The animation clip itself contains translation data

// ✅ ALWAYS: Override OnAnimatorMove for custom root motion control
private void OnAnimatorMove()
{
    if (_useRootMotion)
    {
        // Apply animation's root motion to rigidbody
        _rb.MovePosition(_rb.position + _animator.deltaPosition);
        _rb.MoveRotation(_rb.rotation * _animator.deltaRotation);
    }
}

// In-Place: Code drives character position (precise game-feel)
// Requires: Animator.applyRootMotion = false
// Animations stay at origin, code moves the character
```

## 5. Animation Layers & Avatar Masks

```csharp
// ✅ Avatar Mask: Defines which bones a layer controls
// Create AvatarMask asset → Include/Exclude specific body parts

// Layer setup in Animator Controller:
// Layer 0: Base Layer (Weight: 1.0, Mask: None, Blend: Override)
//   → Controls full body locomotion (idle, walk, run, jump)
// Layer 1: Upper Body (Weight: 1.0, Mask: UpperBodyMask, Blend: Override)
//   → Controls arms/torso for attack, reload, wave
// Layer 2: Face (Weight: 1.0, Mask: FaceMask, Blend: Additive)
//   → Controls facial expressions, blinking

// Set layer weight dynamically
_animator.SetLayerWeight(1, _isAiming ? 1f : 0f); // Enable upper body override when aiming
```

## 6. Inverse Kinematics (IK)

```csharp
// ✅ Built-in Humanoid IK (feet placement, hand targeting)
public class IKController : MonoBehaviour
{
    [SerializeField] private Animator _animator;
    [SerializeField] private LayerMask _groundLayer;
    [Range(0f, 1f)]
    [SerializeField] private float _footIKWeight = 1f;

    private void OnAnimatorIK(int layerIndex)
    {
        // Foot IK: Plant feet on uneven terrain
        SetFootIK(AvatarIKGoal.LeftFoot, _leftFootTransform);
        SetFootIK(AvatarIKGoal.RightFoot, _rightFootTransform);

        // Hand IK: Aim weapon at target
        if (_aimTarget != null)
        {
            _animator.SetIKPositionWeight(AvatarIKGoal.RightHand, 1f);
            _animator.SetIKPosition(AvatarIKGoal.RightHand, _aimTarget.position);
        }

        // Look IK: Head tracks target
        _animator.SetLookAtWeight(1f, 0.3f, 0.6f, 1f, 0.5f);
        _animator.SetLookAtPosition(_lookTarget.position);
    }

    private void SetFootIK(AvatarIKGoal foot, Transform footBone)
    {
        if (Physics.Raycast(footBone.position + Vector3.up * 0.5f, Vector3.down,
            out var hit, 1f, _groundLayer))
        {
            _animator.SetIKPositionWeight(foot, _footIKWeight);
            _animator.SetIKPosition(foot, hit.point + Vector3.up * 0.05f);

            _animator.SetIKRotationWeight(foot, _footIKWeight);
            var footRotation = Quaternion.LookRotation(
                Vector3.ProjectOnPlane(transform.forward, hit.normal), hit.normal);
            _animator.SetIKRotation(foot, footRotation);
        }
    }
}
```

## 7. Animation Rigging Package (Procedural IK)

```csharp
// ✅ Animation Rigging: More powerful, non-humanoid IK
// Install: com.unity.animation.rigging

// Setup hierarchy:
// Character (Animator)
//   └── Rig (RigBuilder)
//       ├── TwoBoneIKConstraint (arm aiming)
//       ├── MultiAimConstraint (head tracking)
//       └── ChainIKConstraint (tentacle, tail)

// Control rig weight at runtime:
public class RigController : MonoBehaviour
{
    [SerializeField] private Rig _aimRig;

    public void EnableAiming(bool enable)
    {
        _aimRig.weight = enable ? 1f : 0f; // Smoothly blend with Mathf.Lerp
    }
}
```

## 8. StateMachineBehaviour (State Callbacks)

```csharp
// ✅ Attach logic to specific animation states
public class AttackStateBehaviour : StateMachineBehaviour
{
    public override void OnStateEnter(Animator animator, AnimatorStateInfo info, int layerIndex)
    {
        animator.GetComponent<CombatController>()?.OnAttackStart();
    }

    public override void OnStateExit(Animator animator, AnimatorStateInfo info, int layerIndex)
    {
        animator.GetComponent<CombatController>()?.OnAttackEnd();
    }
}
```

---

**Execution Protocol**
1. **Hash All Parameters**: Every `Animator.SetFloat/SetBool/SetTrigger` MUST use pre-hashed integer IDs.
2. **Damp Float Parameters**: Use `SetFloat(hash, value, dampTime, deltaTime)` for smooth blend tree transitions.
3. **Avatar Masks for Layers**: Upper body actions (attack, reload) MUST use a dedicated layer with an Avatar Mask.
4. **Root Motion Decision**: Use root motion for realistic character movement (RPG, adventure). Use in-place for precise game-feel (platformer, FPS).
5. **Animation Events for Timing**: Damage frames, footsteps, and VFX triggers MUST use Animation Events, not timers.
