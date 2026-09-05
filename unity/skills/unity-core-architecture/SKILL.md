---
name: unity-core-architecture
description: The definitive architectural standard for Unity projects using Modular Feature-First Design, Assembly Definitions, Dependency Injection, and ScriptableObject-driven decoupling.
author: Diego Villanueva
trigger: When structuring a new Unity project, defining folder hierarchies, creating Assembly Definitions, or organizing feature modules.
---

# Unity Core Architecture

Unity provides zero architectural opinions. Without strict boundaries, projects devolve into a single `Scripts/` folder with 300+ MonoBehaviours referencing each other through `FindObjectOfType`. This document defines the **Modular Feature-First Architecture** standard enforced across all Unity projects.

## 1. Assembly Definitions (Compile-Time Boundaries)

Assembly Definitions (`.asmdef`) are the single most impactful architectural tool in Unity. They split your codebase into isolated compilation units, enforcing dependency direction and reducing recompilation from minutes to seconds.

```text
Assets/_Project/
├── Core/
│   ├── Core.asmdef                 # References: NONE (root dependency)
│   ├── Bootstrap/GameBootstrapper.cs
│   ├── Events/VoidEventChannel.cs
│   ├── Events/TypedEventChannel.cs
│   └── ServiceLocator/ServiceLocator.cs
├── Shared/
│   ├── Shared.asmdef              # References: Core
│   ├── Extensions/VectorExtensions.cs
│   ├── UI/HealthBarWidget.cs
│   └── Interfaces/IDamageable.cs
├── Features/
│   ├── Player/
│   │   ├── Player.asmdef          # References: Core, Shared
│   │   ├── Models/PlayerData.cs
│   │   ├── Services/PlayerMovementService.cs
│   │   ├── Controllers/PlayerController.cs
│   │   └── ScriptableObjects/PlayerConfig.cs
│   ├── Enemy/
│   │   ├── Enemy.asmdef           # References: Core, Shared
│   │   └── ...
│   └── Inventory/
│       ├── Inventory.asmdef       # References: Core, Shared
│       └── ...
└── Tests/
    ├── EditMode/
    │   └── EditTests.asmdef       # References: Core, Features (testOnly)
    └── PlayMode/
        └── PlayTests.asmdef       # References: ALL (testOnly)
```

### Assembly Definition Rules:
1. **Core references NOTHING**: It is the foundation layer.
2. **Shared references only Core**: For shared widgets and interfaces.
3. **Features reference Core + Shared ONLY**: Never another Feature.
4. **Features NEVER reference each other**: Communication goes through Core event channels or interfaces.

```json
// ✅ Player.asmdef
{
    "name": "Player",
    "rootNamespace": "Game.Features.Player",
    "references": ["Core", "Shared"],
    "includePlatforms": [],
    "excludePlatforms": [],
    "autoReferenced": false
}
```

## 2. Dependency Injection (VContainer / Zenject)

MonoBehaviours should NOT instantiate their own dependencies. Use a DI container to wire services, repositories, and configurations.

```csharp
// ✅ ALWAYS: VContainer Lifetime Scope
using VContainer;
using VContainer.Unity;

public class GameLifetimeScope : LifetimeScope
{
    [SerializeField] private PlayerConfig _playerConfig;

    protected override void Configure(IContainerBuilder builder)
    {
        // Register ScriptableObject configs
        builder.RegisterInstance(_playerConfig);

        // Register services as singletons
        builder.Register<IPlayerMovementService, PlayerMovementService>(Lifetime.Singleton);
        builder.Register<ICombatService, CombatService>(Lifetime.Singleton);

        // Register MonoBehaviour entry points
        builder.RegisterEntryPoint<GameFlowController>();
    }
}
```

```csharp
// ❌ ATROCIOUS: Hardcoded dependencies inside MonoBehaviour
public class PlayerController : MonoBehaviour
{
    private void Awake()
    {
        var service = new PlayerMovementService(new PlayerConfig()); // Untestable!
        var enemy = FindObjectOfType<EnemyController>(); // Fragile!
    }
}
```

## 3. ScriptableObject Event Channels (Decoupled Communication)

Cross-feature communication MUST use ScriptableObject Event Channels. This eliminates compile-time coupling between features.

```csharp
// ✅ Generic Typed Event Channel
[CreateAssetMenu(menuName = "Events/Int Event Channel")]
public class IntEventChannel : ScriptableObject
{
    private readonly HashSet<Action<int>> _listeners = new();

    public void Register(Action<int> listener) => _listeners.Add(listener);
    public void Unregister(Action<int> listener) => _listeners.Remove(listener);

    public void Raise(int value)
    {
        foreach (var listener in _listeners)
            listener?.Invoke(value);
    }
}

// Usage in Player feature (publisher):
public class PlayerHealth : MonoBehaviour
{
    [SerializeField] private IntEventChannel _onHealthChanged; // Drag SO asset in Inspector
    
    public void TakeDamage(int amount)
    {
        _currentHealth -= amount;
        _onHealthChanged.Raise(_currentHealth); // Fire and forget
    }
}

// Usage in UI feature (subscriber):
public class HealthBarUI : MonoBehaviour
{
    [SerializeField] private IntEventChannel _onHealthChanged;
    
    private void OnEnable() => _onHealthChanged.Register(UpdateBar);
    private void OnDisable() => _onHealthChanged.Unregister(UpdateBar);
    
    private void UpdateBar(int health) => _slider.value = health;
}
```

## 4. The Bootstrapper Pattern

Every game needs a deterministic initialization sequence. Use a single bootstrapper that loads in an empty `_Boot` scene.

```csharp
// ✅ ALWAYS: Deterministic boot sequence
public class GameBootstrapper : MonoBehaviour
{
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void Initialize()
    {
        // Ensure boot scene is always first
        if (SceneManager.GetActiveScene().name != "_Boot")
        {
            SceneManager.LoadScene("_Boot");
        }
    }

    private async void Start()
    {
        // 1. Initialize core services
        ServiceLocator.Initialize();

        // 2. Load persistent managers (audio, input, save)
        await SceneManager.LoadSceneAsync("_PersistentManagers", LoadSceneMode.Additive);

        // 3. Load the main menu or first gameplay scene
        await SceneManager.LoadSceneAsync("MainMenu", LoadSceneMode.Additive);

        // 4. Unload boot scene
        await SceneManager.UnloadSceneAsync("_Boot");
    }
}
```

## 5. Scene Architecture (Additive Loading)

**❌ NEVER** put everything in one massive scene.
**✅ ALWAYS** use additive scene loading for modularity.

```text
Scenes/
├── _Boot.unity                    # Empty bootstrapper scene
├── _PersistentManagers.unity      # Audio, Input, SaveSystem (DontDestroyOnLoad)
├── Menus/
│   ├── MainMenu.unity
│   └── PauseMenu.unity
├── Levels/
│   ├── Level_01_Environment.unity # Geometry, lighting, static objects
│   ├── Level_01_Gameplay.unity    # Enemies, pickups, triggers
│   └── Level_01_UI.unity          # HUD overlay for this level
└── Shared/
    └── SharedUI.unity             # Persistent HUD elements
```

---

**Execution Protocol**
1. **Assembly Definitions First**: Before writing ANY code, define the `.asmdef` boundaries for Core, Shared, and each Feature.
2. **No God MonoBehaviours**: If a MonoBehaviour exceeds 200 lines, extract logic into plain C# service classes.
3. **Inspector-Driven Wiring**: Use `[SerializeField]` to wire dependencies in the Inspector. Reserve DI containers for complex dependency graphs.
4. **Namespace Everything**: Every script MUST have a namespace matching its assembly (e.g., `namespace Game.Features.Player`).
