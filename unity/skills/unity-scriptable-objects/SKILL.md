---
name: unity-scriptable-objects
description: ScriptableObject-Driven Architecture for Unity including event channels, runtime sets, shared variables, enum-like objects, and configuration assets.
author: Diego Villanueva
trigger: When designing data-driven systems, decoupling game systems, creating configuration assets, or implementing event-driven communication in Unity.
---

# ScriptableObject-Driven Architecture

ScriptableObjects are Unity's most underutilized architectural tool. They are data containers that live as project assets (not in scenes), surviving scene loads and providing a natural decoupling mechanism between systems that don't know about each other.

## 1. Configuration Assets (Data-Driven Design)

Every gameplay value (speed, damage, cooldown, spawn rates) MUST be externalized into ScriptableObject assets. This allows designers to iterate without recompiling and enables A/B testing.

```csharp
// ✅ ALWAYS: Externalize all gameplay data
[CreateAssetMenu(fileName = "NewWeaponData", menuName = "Data/Weapon")]
public class WeaponData : ScriptableObject
{
    [Header("Identity")]
    public string weaponName;
    public Sprite icon;
    public GameObject prefab;

    [Header("Stats")]
    public int baseDamage = 10;
    public float attackSpeed = 1.2f;
    public float range = 2f;
    public DamageType damageType;

    [Header("Audio")]
    public AudioClip attackSound;
    public AudioClip hitSound;

    [Header("VFX")]
    public GameObject hitVFXPrefab;
    public float screenShakeIntensity = 0.3f;
}

// Usage: Reference in MonoBehaviour via Inspector
public class WeaponController : MonoBehaviour
{
    [SerializeField] private WeaponData _data; // Drag asset in Inspector
    
    public void Attack()
    {
        DealDamage(_data.baseDamage);
        PlaySound(_data.attackSound);
        SpawnVFX(_data.hitVFXPrefab);
    }
}
```

```csharp
// ❌ ATROCIOUS: Hardcoded values scattered across MonoBehaviours
public class WeaponController : MonoBehaviour
{
    public int damage = 10;           // Duplicated across 20 prefabs
    public float speed = 1.2f;        // No single source of truth
    public string weaponName = "Sword"; // Impossible to iterate at scale
}
```

## 2. Event Channels (Decoupled Pub/Sub)

ScriptableObject Event Channels enable fire-and-forget communication without compile-time dependencies between features.

```csharp
// ✅ Generic Typed Event Channel
public abstract class EventChannel<T> : ScriptableObject
{
    private readonly HashSet<Action<T>> _listeners = new();

    public void Register(Action<T> listener) => _listeners.Add(listener);
    public void Unregister(Action<T> listener) => _listeners.Remove(listener);

    public void Raise(T value)
    {
        foreach (var listener in _listeners)
            listener?.Invoke(value);
    }
}

// Concrete implementations
[CreateAssetMenu(menuName = "Events/Int Event")]
public class IntEventChannel : EventChannel<int> { }

[CreateAssetMenu(menuName = "Events/Float Event")]
public class FloatEventChannel : EventChannel<float> { }

[CreateAssetMenu(menuName = "Events/String Event")]
public class StringEventChannel : EventChannel<string> { }

[CreateAssetMenu(menuName = "Events/Vector3 Event")]
public class Vector3EventChannel : EventChannel<Vector3> { }

// Void Event (no payload)
[CreateAssetMenu(menuName = "Events/Void Event")]
public class VoidEventChannel : ScriptableObject
{
    private readonly HashSet<Action> _listeners = new();
    public void Register(Action l) => _listeners.Add(l);
    public void Unregister(Action l) => _listeners.Remove(l);
    public void Raise() { foreach (var l in _listeners) l?.Invoke(); }
}
```

## 3. Runtime Sets (Dynamic Collections)

A Runtime Set is a ScriptableObject that holds a list of active objects. Objects register themselves on `OnEnable` and unregister on `OnDisable`.

```csharp
// ✅ Runtime Set: tracks all active enemies without FindObjectsOfType
[CreateAssetMenu(menuName = "Runtime Sets/Transform Set")]
public class TransformRuntimeSet : ScriptableObject
{
    private readonly List<Transform> _items = new();
    public IReadOnlyList<Transform> Items => _items;

    public void Add(Transform t) { if (!_items.Contains(t)) _items.Add(t); }
    public void Remove(Transform t) => _items.Remove(t);
}

// Enemy registers itself
public class EnemyRegistrar : MonoBehaviour
{
    [SerializeField] private TransformRuntimeSet _enemySet;

    private void OnEnable() => _enemySet.Add(transform);
    private void OnDisable() => _enemySet.Remove(transform);
}

// Radar/minimap reads the set without knowing about Enemy
public class RadarUI : MonoBehaviour
{
    [SerializeField] private TransformRuntimeSet _enemySet;

    private void Update()
    {
        foreach (var enemy in _enemySet.Items)
            DrawBlip(enemy.position);
    }
}
```

## 4. Shared Variables (Observable Values)

Shared Variables are ScriptableObject wrappers around a single value. Multiple systems can read/write the same variable without knowing about each other.

```csharp
// ✅ Shared Variable with change notification
[CreateAssetMenu(menuName = "Variables/Int Variable")]
public class IntVariable : ScriptableObject
{
    [SerializeField] private int _initialValue;
    private int _runtimeValue;

    public event Action<int> OnValueChanged;

    public int Value
    {
        get => _runtimeValue;
        set
        {
            if (_runtimeValue == value) return;
            _runtimeValue = value;
            OnValueChanged?.Invoke(_runtimeValue);
        }
    }

    private void OnEnable() => _runtimeValue = _initialValue;

    #if UNITY_EDITOR
    [ContextMenu("Reset to Initial")]
    private void ResetValue() => Value = _initialValue;
    #endif
}

// Player writes:
public class PlayerHealth : MonoBehaviour
{
    [SerializeField] private IntVariable _healthVariable;
    
    public void TakeDamage(int amount) => _healthVariable.Value -= amount;
}

// UI reads:
public class HealthDisplay : MonoBehaviour
{
    [SerializeField] private IntVariable _healthVariable;
    [SerializeField] private TMP_Text _label;
    
    private void OnEnable() => _healthVariable.OnValueChanged += UpdateDisplay;
    private void OnDisable() => _healthVariable.OnValueChanged -= UpdateDisplay;
    private void UpdateDisplay(int hp) => _label.text = $"HP: {hp}";
}
```

## 5. Enum-Like ScriptableObjects (Extensible Enums)

Traditional C# enums are closed and require recompilation to add new values. SO-based enums are open for extension.

```csharp
// ✅ Extensible "enum" via ScriptableObject
[CreateAssetMenu(menuName = "Data/Damage Type")]
public class DamageType : ScriptableObject
{
    public string displayName;
    public Color displayColor = Color.white;
    public Sprite icon;
    [Range(0f, 1f)] public float armorPenetration;
}

// Create assets: "Fire.asset", "Ice.asset", "Lightning.asset"
// Designers can add new damage types without touching code!
```

## 6. Factory Pattern with ScriptableObjects

```csharp
// ✅ SO-based factory for spawning configured prefabs
[CreateAssetMenu(menuName = "Factories/Enemy Factory")]
public class EnemyFactory : ScriptableObject
{
    [SerializeField] private EnemyData[] _enemyTypes;

    public GameObject Spawn(EnemyType type, Vector3 position, Quaternion rotation)
    {
        var data = _enemyTypes.First(e => e.type == type);
        var instance = Instantiate(data.prefab, position, rotation);
        instance.GetComponent<EnemyController>().Initialize(data);
        return instance;
    }
}
```

---

**Execution Protocol**
1. **One Asset, One Truth**: Every gameplay constant must exist in exactly ONE ScriptableObject asset. No duplication across prefabs.
2. **Register/Unregister Symmetry**: ALWAYS unregister listeners in `OnDisable` to prevent memory leaks and null reference exceptions.
3. **Reset Runtime State**: ScriptableObjects persist between Play Mode sessions in the Editor. Use `OnEnable` to reset runtime values to their initial state.
4. **Organize Assets**: Store SO assets in `Assets/_Project/Data/` with subfolders per type (Weapons, Events, Config, RuntimeSets).
