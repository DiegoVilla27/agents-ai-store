---
name: unity-design-patterns
description: Game development design patterns for Unity including Observer, Command, State, Strategy, Object Pool, Flyweight, Service Locator, and Component patterns with C# implementations.
author: Diego Villanueva
trigger: When implementing game systems that require decoupling, undo/redo, state machines, object recycling, or extensible behavior selection.
---

# Design Patterns for Game Development

Design patterns are not academic exercises — they are survival tools for managing the complexity of interactive real-time systems. Every pattern here is presented in its Unity-native form with concrete C# implementations.

## 1. State Pattern (Finite State Machine)

The backbone of character controllers, AI, and UI flows. States encapsulate behavior and transitions.

```csharp
// ✅ ALWAYS: Clean State Machine with explicit transitions
public interface IState
{
    void Enter();
    void Execute();  // Called every frame
    void FixedExecute(); // Called every physics step
    void Exit();
}

public class StateMachine
{
    private IState _currentState;
    public IState CurrentState => _currentState;

    public void ChangeState(IState newState)
    {
        _currentState?.Exit();
        _currentState = newState;
        _currentState?.Enter();
    }

    public void Update() => _currentState?.Execute();
    public void FixedUpdate() => _currentState?.FixedExecute();
}

// Concrete state
public class PlayerIdleState : IState
{
    private readonly PlayerController _player;
    private readonly StateMachine _sm;

    public PlayerIdleState(PlayerController player, StateMachine sm)
    {
        _player = player;
        _sm = sm;
    }

    public void Enter() => _player.Animator.Play("Idle");
    
    public void Execute()
    {
        if (_player.InputService.MoveInput.sqrMagnitude > 0.01f)
            _sm.ChangeState(_player.RunState);
        if (_player.InputService.JumpPressed)
            _sm.ChangeState(_player.JumpState);
    }

    public void FixedExecute() { }
    public void Exit() { }
}
```

## 2. Command Pattern (Input Abstraction & Undo)

Encapsulate actions as objects. Essential for input remapping, replay systems, and undo/redo.

```csharp
// ✅ Command pattern for input-driven actions
public interface ICommand
{
    void Execute();
    void Undo();
}

public class MoveCommand : ICommand
{
    private readonly Transform _transform;
    private readonly Vector3 _direction;
    private readonly float _distance;
    private Vector3 _previousPosition;

    public MoveCommand(Transform transform, Vector3 direction, float distance)
    {
        _transform = transform;
        _direction = direction;
        _distance = distance;
    }

    public void Execute()
    {
        _previousPosition = _transform.position;
        _transform.position += _direction * _distance;
    }

    public void Undo() => _transform.position = _previousPosition;
}

// Command history for undo/redo
public class CommandInvoker
{
    private readonly Stack<ICommand> _undoStack = new();
    private readonly Stack<ICommand> _redoStack = new();

    public void Execute(ICommand command)
    {
        command.Execute();
        _undoStack.Push(command);
        _redoStack.Clear();
    }

    public void Undo()
    {
        if (_undoStack.Count == 0) return;
        var command = _undoStack.Pop();
        command.Undo();
        _redoStack.Push(command);
    }

    public void Redo()
    {
        if (_redoStack.Count == 0) return;
        var command = _redoStack.Pop();
        command.Execute();
        _undoStack.Push(command);
    }
}
```

## 3. Observer Pattern (Event-Driven Architecture)

Decouple systems that react to changes without direct references.

```csharp
// ✅ Lightweight C# event system (no MonoBehaviour dependency)
public class GameEvents
{
    public event Action<int> OnScoreChanged;
    public event Action<Vector3> OnPlayerDied;
    public event Action OnLevelCompleted;

    public void RaiseScoreChanged(int score) => OnScoreChanged?.Invoke(score);
    public void RaisePlayerDied(Vector3 pos) => OnPlayerDied?.Invoke(pos);
    public void RaiseLevelCompleted() => OnLevelCompleted?.Invoke();
}

// ❌ NEVER: Tight coupling via direct reference chains
// EnemyController -> PlayerController -> ScoreManager -> UIManager
// If ANY of these is null, the entire chain breaks
```

## 4. Object Pool Pattern (Zero Runtime Allocation)

Creating and destroying GameObjects is expensive. Pool and recycle them.

```csharp
// ✅ ALWAYS: Pool frequently spawned objects (bullets, VFX, enemies)
public class GameObjectPool
{
    private readonly GameObject _prefab;
    private readonly Transform _parent;
    private readonly Queue<GameObject> _pool = new();
    private readonly int _maxSize;

    public GameObjectPool(GameObject prefab, int initialSize, int maxSize, Transform parent = null)
    {
        _prefab = prefab;
        _maxSize = maxSize;
        _parent = parent;

        for (int i = 0; i < initialSize; i++)
            _pool.Enqueue(CreateInstance());
    }

    public GameObject Get(Vector3 position, Quaternion rotation)
    {
        var obj = _pool.Count > 0 ? _pool.Dequeue() : CreateInstance();
        obj.transform.SetPositionAndRotation(position, rotation);
        obj.SetActive(true);
        return obj;
    }

    public void Return(GameObject obj)
    {
        obj.SetActive(false);
        if (_pool.Count < _maxSize)
            _pool.Enqueue(obj);
        else
            Object.Destroy(obj);
    }

    private GameObject CreateInstance()
    {
        var obj = Object.Instantiate(_prefab, _parent);
        obj.SetActive(false);
        return obj;
    }
}

// ❌ NEVER: Instantiate/Destroy in hot paths
void Fire()
{
    var bullet = Instantiate(bulletPrefab, firePoint.position, firePoint.rotation); // SLOW
    Destroy(bullet, 3f); // Even slower — delayed GC
}
```

## 5. Strategy Pattern (Swappable Algorithms)

Define a family of algorithms, encapsulate each one, and make them interchangeable.

```csharp
// ✅ Strategy for swappable movement behaviors
public interface IMovementStrategy
{
    void Move(Transform transform, Vector3 input, float speed);
}

public class GroundMovement : IMovementStrategy
{
    public void Move(Transform t, Vector3 input, float speed)
    {
        t.position += input.normalized * (speed * Time.deltaTime);
    }
}

public class FlyingMovement : IMovementStrategy
{
    public void Move(Transform t, Vector3 input, float speed)
    {
        var direction = new Vector3(input.x, input.y, input.z);
        t.position += direction.normalized * (speed * Time.deltaTime);
    }
}

public class SwimmingMovement : IMovementStrategy
{
    private readonly float _drag;
    public SwimmingMovement(float drag) => _drag = drag;

    public void Move(Transform t, Vector3 input, float speed)
    {
        t.position += input.normalized * (speed * _drag * Time.deltaTime);
    }
}

// Controller swaps strategies dynamically
public class CharacterController : MonoBehaviour
{
    private IMovementStrategy _movement = new GroundMovement();

    public void EnterWater() => _movement = new SwimmingMovement(0.6f);
    public void ExitWater() => _movement = new GroundMovement();
    public void StartFlying() => _movement = new FlyingMovement();

    private void Update() => _movement.Move(transform, _input, _speed);
}
```

## 6. Service Locator Pattern (Lightweight DI)

When a full DI container (VContainer/Zenject) is overkill, use a simple Service Locator for global services.

```csharp
// ✅ Minimal Service Locator
public static class ServiceLocator
{
    private static readonly Dictionary<Type, object> _services = new();

    public static void Register<T>(T service) where T : class
    {
        _services[typeof(T)] = service;
    }

    public static T Get<T>() where T : class
    {
        if (_services.TryGetValue(typeof(T), out var service))
            return (T)service;
        throw new InvalidOperationException($"Service {typeof(T).Name} not registered.");
    }

    public static void Reset() => _services.Clear();
}

// Register in bootstrapper
ServiceLocator.Register<IAudioService>(new AudioService());
ServiceLocator.Register<ISaveService>(new SaveService());

// Consume anywhere
var audio = ServiceLocator.Get<IAudioService>();
audio.PlaySFX("explosion");
```

## 7. Flyweight Pattern (Shared Data)

When thousands of objects share the same data (enemy stats, tile properties), store the shared data once and reference it.

```csharp
// ✅ ScriptableObject IS the Flyweight
// 1000 enemy instances share the same EnemyData asset
[CreateAssetMenu(menuName = "Data/Enemy")]
public class EnemyData : ScriptableObject // Shared (flyweight)
{
    public string enemyName;
    public int maxHealth;
    public float moveSpeed;
    public Sprite sprite;
}

public class EnemyInstance : MonoBehaviour // Unique per instance
{
    [SerializeField] private EnemyData _data; // Shared reference
    private int _currentHealth; // Unique per instance

    private void Awake() => _currentHealth = _data.maxHealth;
}
```

---

**Execution Protocol**
1. **State Machines for Complex Behavior**: If a system has more than 3 distinct behavioral modes, use a State Machine instead of nested `if/else` chains.
2. **Pool Everything That Spawns Frequently**: Bullets, particles, enemies, UI popups — if it spawns more than once per second, it must be pooled.
3. **Command for Undoable Actions**: Any action that must support undo, replay, or remote execution (multiplayer) should be modeled as a Command.
4. **Strategy for Variant Behaviors**: When the same entity can behave differently (movement styles, attack patterns, AI behaviors), use Strategy, not inheritance.
