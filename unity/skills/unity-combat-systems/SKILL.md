---
name: unity-combat-systems
description: Combat system architecture for Unity including hitbox/hurtbox systems, combo chains, cooldowns, damage calculation, hit stop, screen shake, and damage number popups.
author: Diego Villanueva
trigger: When implementing melee/ranged combat, hitbox systems, combo mechanics, damage calculation, or combat feel (hit stop, screen shake, VFX).
---

# Combat Systems

Combat feel separates professional games from amateur ones. It's not just about dealing damage — it's about the entire feedback chain: anticipation → action → impact → recovery. Every frame of the combat loop must communicate power and consequence.

## 1. Hitbox/Hurtbox System

```csharp
// ✅ Separation of concerns: Hitbox (attack) vs Hurtbox (receive)
public class Hitbox : MonoBehaviour
{
    [SerializeField] private int _damage;
    [SerializeField] private float _knockbackForce;
    [SerializeField] private LayerMask _targetLayer;

    private readonly HashSet<Collider2D> _alreadyHit = new();
    private bool _isActive;

    public void Activate(int damage)
    {
        _damage = damage;
        _alreadyHit.Clear();
        _isActive = true;
        GetComponent<Collider2D>().enabled = true;
    }

    public void Deactivate()
    {
        _isActive = false;
        GetComponent<Collider2D>().enabled = false;
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (!_isActive) return;
        if (_alreadyHit.Contains(other)) return;
        if (((1 << other.gameObject.layer) & _targetLayer) == 0) return;

        var hurtbox = other.GetComponent<Hurtbox>();
        if (hurtbox == null) return;

        _alreadyHit.Add(other);
        hurtbox.ReceiveHit(_damage, _knockbackForce, transform.position);
    }
}

public class Hurtbox : MonoBehaviour
{
    [SerializeField] private IntEventChannel _onDamageReceived;

    public void ReceiveHit(int damage, float knockback, Vector3 hitOrigin)
    {
        _onDamageReceived?.Raise(damage);

        // Knockback direction
        Vector2 direction = (transform.position - hitOrigin).normalized;
        GetComponentInParent<Rigidbody2D>()?.AddForce(direction * knockback, ForceMode2D.Impulse);
    }
}
```

## 2. Combo System

```csharp
// ✅ Input-buffered combo chain
public class ComboController : MonoBehaviour
{
    [SerializeField] private ComboData[] _comboChain;
    [SerializeField] private float _comboWindowDuration = 0.5f;

    private int _comboIndex;
    private float _comboTimer;
    private bool _canContinueCombo;

    public void OnAttackInput()
    {
        if (_comboIndex == 0 || (_canContinueCombo && _comboTimer > 0))
        {
            ExecuteCombo(_comboIndex);
            _comboIndex = (_comboIndex + 1) % _comboChain.Length;
            _comboTimer = _comboWindowDuration;
            _canContinueCombo = false;
        }
    }

    private void Update()
    {
        if (_comboTimer > 0)
        {
            _comboTimer -= Time.deltaTime;
            if (_comboTimer <= 0) ResetCombo();
        }
    }

    // Called by Animation Event at the "can continue" frame
    public void EnableComboWindow() => _canContinueCombo = true;

    private void ExecuteCombo(int index)
    {
        var data = _comboChain[index];
        _animator.SetTrigger(data.animationTrigger);
        _hitbox.Activate(data.damage);
    }

    private void ResetCombo()
    {
        _comboIndex = 0;
        _canContinueCombo = false;
    }
}

[System.Serializable]
public class ComboData
{
    public int animationTrigger;
    public int damage;
    public float attackSpeed;
    public AudioClip swingSound;
    public GameObject hitVFX;
}
```

## 3. Combat Feel (Juice)

```csharp
// ✅ Hit Stop: Freeze time briefly on impact
public class HitStop : MonoBehaviour
{
    public void Execute(float duration = 0.05f)
    {
        StartCoroutine(HitStopCoroutine(duration));
    }

    private IEnumerator HitStopCoroutine(float duration)
    {
        Time.timeScale = 0.05f; // Near-freeze
        yield return new WaitForSecondsRealtime(duration);
        Time.timeScale = 1f;
    }
}

// ✅ Impact feedback chain
public class CombatFeedback : MonoBehaviour
{
    [SerializeField] private CameraShake _cameraShake;
    [SerializeField] private HitStop _hitStop;
    [SerializeField] private VFXPool _hitVFXPool;
    [SerializeField] private SFXManager _sfxManager;

    public void OnHitConfirmed(Vector3 hitPoint, int damage)
    {
        // 1. Hit stop (brief time freeze)
        _hitStop.Execute(0.04f);

        // 2. Camera shake (proportional to damage)
        float shakeIntensity = Mathf.Clamp(damage / 100f, 0.1f, 0.5f);
        _cameraShake.Shake(shakeIntensity, 0.15f);

        // 3. VFX (hit sparks)
        _hitVFXPool.Spawn(hitPoint, Quaternion.identity);

        // 4. SFX (impact sound)
        _sfxManager.PlaySFX(_hitClip, hitPoint, volume: 0.8f);

        // 5. Damage number popup
        _damageNumberPool.Spawn(hitPoint, damage);
    }
}
```

## 4. Damage Calculation

```csharp
// ✅ Extensible damage pipeline
public class DamageCalculator
{
    public DamageResult Calculate(DamageContext context)
    {
        float baseDamage = context.BaseDamage;

        // 1. Apply attack multiplier
        baseDamage *= context.AttackMultiplier;

        // 2. Apply armor reduction
        float armorReduction = context.TargetArmor / (context.TargetArmor + 100f); // Diminishing returns
        baseDamage *= (1f - armorReduction);

        // 3. Critical hit check
        bool isCritical = Random.value < context.CritChance;
        if (isCritical) baseDamage *= context.CritMultiplier;

        // 4. Elemental effectiveness
        baseDamage *= GetElementalMultiplier(context.DamageElement, context.TargetElement);

        // 5. Random variance (±10%)
        baseDamage *= Random.Range(0.9f, 1.1f);

        return new DamageResult
        {
            FinalDamage = Mathf.Max(1, Mathf.RoundToInt(baseDamage)),
            IsCritical = isCritical,
            WasBlocked = false
        };
    }
}
```

## 5. Cooldown System

```csharp
// ✅ Reusable cooldown timer
public class Cooldown
{
    private float _duration;
    private float _timer;

    public bool IsReady => _timer <= 0f;
    public float Progress => 1f - Mathf.Clamp01(_timer / _duration);

    public Cooldown(float duration) => _duration = duration;

    public bool TryUse()
    {
        if (!IsReady) return false;
        _timer = _duration;
        return true;
    }

    public void Update(float deltaTime)
    {
        if (_timer > 0f) _timer -= deltaTime;
    }

    public void Reset() => _timer = 0f;
}

// Usage
private Cooldown _dashCooldown = new(1.5f);
private Cooldown _specialCooldown = new(8f);

private void Update()
{
    _dashCooldown.Update(Time.deltaTime);
    _specialCooldown.Update(Time.deltaTime);

    if (Input.GetButtonDown("Dash") && _dashCooldown.TryUse())
        PerformDash();
}
```

---

**Execution Protocol**
1. **Hitbox/Hurtbox Separation**: NEVER check damage on the same collider that handles movement. Use dedicated trigger colliders.
2. **AlreadyHit Set**: Track already-hit targets per attack to prevent multi-hit on sustained collisions.
3. **Animation Events for Hitbox Timing**: Activate/deactivate hitboxes via Animation Events, not timers.
4. **Feedback Chain**: Every hit MUST trigger: hit stop + camera shake + VFX + SFX + damage number. All five.
5. **Cooldowns as First-Class Objects**: Use a `Cooldown` class, not raw float timers scattered across MonoBehaviours.
