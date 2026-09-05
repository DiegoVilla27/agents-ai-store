---
name: unity-animation-2d
description: Complete 2D animation mastery for Unity including Animator Controller, sprite sheets, bone-based animation with 2D Animation package, blend trees, and sprite swap.
author: Diego Villanueva
trigger: When implementing 2D character animations, sprite sheet workflows, bone-based 2D rigs, blend trees for directional movement, or sprite swap systems.
---

# Unity 2D Animation

2D animation in Unity supports two paradigms: frame-by-frame sprite sheets (classic pixel art) and bone-based skeletal animation (Spine-style). Both use the Animator Controller state machine for transitions.

## 1. Sprite Sheet Animation (Frame-by-Frame)

```text
Workflow:
1. Import sprite sheet → Sprite Mode: Multiple
2. Slice in Sprite Editor (Grid by Cell Size or Automatic)
3. Select frames in Project → Create Animation Clip
4. Configure Animator Controller with states and transitions
```

```csharp
// ✅ ALWAYS: Use hashed parameter IDs
private static readonly int IsRunning = Animator.StringToHash("IsRunning");
private static readonly int IsJumping = Animator.StringToHash("IsJumping");
private static readonly int VelocityY = Animator.StringToHash("VelocityY");
private static readonly int AttackTrigger = Animator.StringToHash("Attack");

public class PlayerAnimator2D : MonoBehaviour
{
    [SerializeField] private Animator _animator;
    [SerializeField] private SpriteRenderer _spriteRenderer;

    public void UpdateAnimations(Vector2 velocity, bool isGrounded)
    {
        _animator.SetBool(IsRunning, Mathf.Abs(velocity.x) > 0.01f);
        _animator.SetBool(IsJumping, !isGrounded);
        _animator.SetFloat(VelocityY, velocity.y);

        // Flip sprite based on direction
        if (velocity.x != 0)
            _spriteRenderer.flipX = velocity.x < 0;
    }

    public void PlayAttack() => _animator.SetTrigger(AttackTrigger);
}
```

## 2. Bone-Based Animation (2D Animation Package)

```text
Setup:
1. Install "2D Animation" package from Package Manager
2. Import character sprite → Sprite Editor → Skinning Editor
3. Create bones, assign mesh weights
4. Create Animation Clips that rotate/translate bones
5. Use Sprite Library + Sprite Resolver for sprite swapping
```

```csharp
// ✅ Sprite Library for character customization (armor, weapons, hats)
using UnityEngine.U2D.Animation;

public class CharacterCustomizer : MonoBehaviour
{
    [SerializeField] private SpriteLibraryAsset _defaultSkin;
    [SerializeField] private SpriteLibraryAsset _armorSkin;
    [SerializeField] private SpriteLibrary _spriteLibrary;

    public void EquipArmor() => _spriteLibrary.spriteLibraryAsset = _armorSkin;
    public void RemoveArmor() => _spriteLibrary.spriteLibraryAsset = _defaultSkin;
}
```

## 3. Blend Trees (Directional Animation)

```text
✅ 2D Freeform Directional Blend Tree for 8-direction movement:
Parameter X: MoveX (float)
Parameter Y: MoveY (float)

Motions:
  (0, 1)    → WalkUp
  (0, -1)   → WalkDown
  (1, 0)    → WalkRight
  (-1, 0)   → WalkLeft
  (1, 1)    → WalkUpRight
  (-1, 1)   → WalkUpLeft
  (1, -1)   → WalkDownRight
  (-1, -1)  → WalkDownLeft
  (0, 0)    → Idle
```

```csharp
// ✅ Feed normalized input to blend tree
private static readonly int MoveX = Animator.StringToHash("MoveX");
private static readonly int MoveY = Animator.StringToHash("MoveY");

public void UpdateDirection(Vector2 input)
{
    if (input.sqrMagnitude > 0.01f)
    {
        _animator.SetFloat(MoveX, input.x);
        _animator.SetFloat(MoveY, input.y);
    }
}
```

## 4. Animation Events

```csharp
// ✅ Use Animation Events for frame-precise callbacks
// In the Animation window, add events on specific keyframes
public class AttackAnimation : MonoBehaviour
{
    // Called by Animation Event on the damage frame
    public void OnAttackHit()
    {
        var hits = Physics2D.OverlapCircleAll(_attackPoint.position, _attackRadius, _enemyLayer);
        foreach (var hit in hits)
            hit.GetComponent<IDamageable>()?.TakeDamage(_damage);
    }

    // Called at the end of attack animation
    public void OnAttackEnd()
    {
        _isAttacking = false;
    }

    // Called on footstep frames for audio
    public void OnFootstep()
    {
        _audioSource.PlayOneShot(_footstepClips[Random.Range(0, _footstepClips.Length)]);
    }
}
```

## 5. Animator Override Controller (Shared State Machine)

```csharp
// ✅ Share one Animator Controller across multiple characters
// Base controller: has all states and transitions
// Override controller: swaps animation clips only

[CreateAssetMenu(menuName = "Data/Character Animation Set")]
public class CharacterAnimationSet : ScriptableObject
{
    public AnimatorOverrideController overrideController;
    public AnimationClip idle;
    public AnimationClip run;
    public AnimationClip jump;
    public AnimationClip attack;
}

public class AnimationLoader : MonoBehaviour
{
    [SerializeField] private Animator _animator;

    public void LoadAnimationSet(CharacterAnimationSet set)
    {
        _animator.runtimeAnimatorController = set.overrideController;
    }
}
```

---

**Execution Protocol**
1. **Hash All Parameters**: NEVER use string-based `SetBool("name")`. ALWAYS use `Animator.StringToHash` cached in `static readonly` fields.
2. **Trigger Reset**: Triggers persist until consumed. Call `ResetTrigger` if an animation transition might not consume it in time.
3. **Sprite Pivot Consistency**: ALL sprites in a sprite sheet MUST have the same pivot point (typically Bottom Center for characters).
4. **Animation Events for Gameplay**: Use Animation Events for damage frames, footstep audio, and VFX spawning — not timers or coroutines.
