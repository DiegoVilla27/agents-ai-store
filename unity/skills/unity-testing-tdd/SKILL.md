---
name: unity-testing-tdd
description: Unity Test Framework mastery including NUnit, Edit Mode tests, Play Mode tests, Test-Driven Development, mocking with NSubstitute, and test coverage strategies.
author: Diego Villanueva
trigger: When writing unit tests, integration tests, Play Mode tests, implementing TDD, or setting up test infrastructure in Unity projects.
---

# Testing & TDD in Unity

Games are notoriously under-tested. Unity's Test Framework (based on NUnit) supports both Edit Mode tests (fast, pure C#) and Play Mode tests (full engine, MonoBehaviour lifecycle). Assembly Definitions make your code testable by enabling dependency injection.

## 1. Test Architecture

```text
Tests/
├── EditMode/
│   ├── EditTests.asmdef        # References: Core, Features (testOnly: true)
│   ├── Services/
│   │   ├── DamageCalculatorTests.cs
│   │   ├── InventoryServiceTests.cs
│   │   └── StateMachineTests.cs
│   └── Models/
│       └── PlayerDataTests.cs
└── PlayMode/
    ├── PlayTests.asmdef         # References: ALL (testOnly: true)
    ├── Integration/
    │   ├── PlayerMovementTests.cs
    │   └── CombatSystemTests.cs
    └── SceneTests/
        └── LevelLoadingTests.cs
```

## 2. Edit Mode Tests (Pure C#)

```csharp
// ✅ Fast, no engine overhead, run in milliseconds
using NUnit.Framework;

[TestFixture]
public class DamageCalculatorTests
{
    private DamageCalculator _calculator;

    [SetUp]
    public void SetUp()
    {
        _calculator = new DamageCalculator();
    }

    [Test]
    public void CalculateDamage_BaseDamage_ReturnsCorrectValue()
    {
        int result = _calculator.Calculate(baseDamage: 10, multiplier: 1f, armor: 0);
        Assert.AreEqual(10, result);
    }

    [Test]
    public void CalculateDamage_WithArmor_ReducesDamage()
    {
        int result = _calculator.Calculate(baseDamage: 100, multiplier: 1f, armor: 50);
        Assert.AreEqual(50, result);
    }

    [Test]
    public void CalculateDamage_NegativeArmor_ClampsToZero()
    {
        int result = _calculator.Calculate(baseDamage: 10, multiplier: 1f, armor: -5);
        Assert.That(result, Is.GreaterThanOrEqualTo(10));
    }

    [TestCase(10, 2f, 0, 20)]
    [TestCase(10, 0.5f, 0, 5)]
    [TestCase(100, 1.5f, 25, 125)]
    public void CalculateDamage_Parameterized(int base_, float mult, int armor, int expected)
    {
        int result = _calculator.Calculate(base_, mult, armor);
        Assert.AreEqual(expected, result);
    }
}
```

## 3. Play Mode Tests (MonoBehaviour Lifecycle)

```csharp
// ✅ Integration tests with full engine
using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

public class PlayerMovementTests
{
    private GameObject _playerGO;
    private PlayerMovement _movement;
    private Rigidbody2D _rb;

    [UnitySetUp]
    public IEnumerator SetUp()
    {
        _playerGO = new GameObject("TestPlayer");
        _rb = _playerGO.AddComponent<Rigidbody2D>();
        _movement = _playerGO.AddComponent<PlayerMovement>();

        yield return null; // Wait one frame for Awake/Start
    }

    [UnityTearDown]
    public IEnumerator TearDown()
    {
        Object.Destroy(_playerGO);
        yield return null;
    }

    [UnityTest]
    public IEnumerator Player_MovesRight_WhenInputIsPositive()
    {
        Vector3 startPos = _playerGO.transform.position;

        _movement.SetMoveInput(Vector2.right);

        // Wait several physics frames
        for (int i = 0; i < 10; i++)
            yield return new WaitForFixedUpdate();

        Assert.That(_playerGO.transform.position.x, Is.GreaterThan(startPos.x));
    }

    [UnityTest]
    public IEnumerator Player_DoesNotMoveVertically_OnFlatGround()
    {
        float startY = _playerGO.transform.position.y;

        _movement.SetMoveInput(Vector2.right);
        yield return new WaitForSeconds(0.5f);

        Assert.That(_playerGO.transform.position.y, Is.EqualTo(startY).Within(0.1f));
    }
}
```

## 4. Mocking with NSubstitute

```csharp
// ✅ Mock dependencies for isolated unit tests
// Install NSubstitute via NuGet or Unity Package
using NSubstitute;

[TestFixture]
public class CombatServiceTests
{
    private ICombatService _combatService;
    private IDamageable _mockTarget;
    private IAudioService _mockAudio;

    [SetUp]
    public void SetUp()
    {
        _mockTarget = Substitute.For<IDamageable>();
        _mockAudio = Substitute.For<IAudioService>();
        _combatService = new CombatService(_mockAudio);
    }

    [Test]
    public void Attack_DealsDamage_ToTarget()
    {
        _combatService.Attack(_mockTarget, damage: 25);

        _mockTarget.Received(1).TakeDamage(25); // Verify method was called
    }

    [Test]
    public void Attack_PlaysSFX()
    {
        _combatService.Attack(_mockTarget, damage: 25);

        _mockAudio.Received(1).PlaySFX(Arg.Any<string>()); // Verify SFX played
    }

    [Test]
    public void Attack_DoesNotDamage_DeadTarget()
    {
        _mockTarget.IsAlive.Returns(false);

        _combatService.Attack(_mockTarget, damage: 25);

        _mockTarget.DidNotReceive().TakeDamage(Arg.Any<int>());
    }
}
```

## 5. Testing State Machines

```csharp
[TestFixture]
public class StateMachineTests
{
    private StateMachine _sm;
    private IState _idleState;
    private IState _runState;

    [SetUp]
    public void SetUp()
    {
        _idleState = Substitute.For<IState>();
        _runState = Substitute.For<IState>();
        _sm = new StateMachine();
    }

    [Test]
    public void ChangeState_CallsExitOnPreviousState()
    {
        _sm.ChangeState(_idleState);
        _sm.ChangeState(_runState);

        _idleState.Received(1).Exit();
    }

    [Test]
    public void ChangeState_CallsEnterOnNewState()
    {
        _sm.ChangeState(_runState);

        _runState.Received(1).Enter();
    }

    [Test]
    public void Update_ExecutesCurrentState()
    {
        _sm.ChangeState(_idleState);
        _sm.Update();

        _idleState.Received(1).Execute();
    }
}
```

---

**Execution Protocol**
1. **Edit Mode for Logic**: ALL pure C# classes (services, calculators, state machines) MUST have Edit Mode unit tests.
2. **Play Mode for Integration**: MonoBehaviour interactions, physics, and scene loading require Play Mode tests.
3. **Interfaces for Testability**: Design services behind interfaces (`IDamageable`, `IAudioService`) to enable mocking.
4. **Assembly Definitions Enable Testing**: Test assemblies reference production assemblies. Without `.asmdef`, testing is impossible.
5. **Test Naming Convention**: `MethodName_Scenario_ExpectedBehavior` (e.g., `CalculateDamage_WithArmor_ReducesDamage`).
