---
name: unity-ai-behavior-trees
description: Advanced AI architecture for Unity including Behavior Trees, Finite State Machines, GOAP, Utility AI, steering behaviors, sensory systems, and threat assessment.
author: Diego Villanueva
trigger: When implementing complex AI decision-making, behavior trees, goal-oriented action planning, enemy AI, boss AI, or NPC behavioral systems.
---

# AI Behavior Architecture

Simple AI uses `if/else` chains. Professional AI uses composable, data-driven decision architectures. This document covers the four major AI paradigms and when to use each.

## 1. Finite State Machine (FSM)

Best for simple AI with < 5 states. Beyond that, transitions become unmanageable (state explosion).

```csharp
// ✅ Lightweight FSM for simple enemy AI
public enum EnemyState { Idle, Patrol, Chase, Attack, Dead }

public class EnemyFSM : MonoBehaviour
{
    private EnemyState _state = EnemyState.Idle;

    private void Update()
    {
        switch (_state)
        {
            case EnemyState.Idle: UpdateIdle(); break;
            case EnemyState.Patrol: UpdatePatrol(); break;
            case EnemyState.Chase: UpdateChase(); break;
            case EnemyState.Attack: UpdateAttack(); break;
            case EnemyState.Dead: break;
        }
    }

    private void TransitionTo(EnemyState newState)
    {
        ExitState(_state);
        _state = newState;
        EnterState(newState);
    }
}
```

## 2. Behavior Trees

The industry standard for complex AI. Trees are modular, composable, and debuggable.

```csharp
// ✅ Behavior Tree Node Types
public enum NodeStatus { Running, Success, Failure }

public abstract class BTNode
{
    public abstract NodeStatus Evaluate(AIContext context);
}

// Composite: Sequence (AND — all children must succeed)
public class Sequence : BTNode
{
    private readonly List<BTNode> _children;
    public Sequence(params BTNode[] children) => _children = new(children);

    public override NodeStatus Evaluate(AIContext context)
    {
        foreach (var child in _children)
        {
            var status = child.Evaluate(context);
            if (status != NodeStatus.Success)
                return status; // Return Running or Failure immediately
        }
        return NodeStatus.Success;
    }
}

// Composite: Selector (OR — first child that succeeds wins)
public class Selector : BTNode
{
    private readonly List<BTNode> _children;
    public Selector(params BTNode[] children) => _children = new(children);

    public override NodeStatus Evaluate(AIContext context)
    {
        foreach (var child in _children)
        {
            var status = child.Evaluate(context);
            if (status != NodeStatus.Failure)
                return status; // Return Running or Success immediately
        }
        return NodeStatus.Failure;
    }
}

// Decorator: Inverter (NOT)
public class Inverter : BTNode
{
    private readonly BTNode _child;
    public Inverter(BTNode child) => _child = child;

    public override NodeStatus Evaluate(AIContext context)
    {
        return _child.Evaluate(context) switch
        {
            NodeStatus.Success => NodeStatus.Failure,
            NodeStatus.Failure => NodeStatus.Success,
            _ => NodeStatus.Running
        };
    }
}

// Leaf: Condition check
public class IsPlayerInRange : BTNode
{
    private readonly float _range;
    public IsPlayerInRange(float range) => _range = range;

    public override NodeStatus Evaluate(AIContext context)
    {
        float dist = Vector3.Distance(context.Transform.position, context.Player.position);
        return dist <= _range ? NodeStatus.Success : NodeStatus.Failure;
    }
}

// Leaf: Action
public class ChasePlayer : BTNode
{
    public override NodeStatus Evaluate(AIContext context)
    {
        context.Agent.SetDestination(context.Player.position);
        return context.Agent.remainingDistance > context.AttackRange
            ? NodeStatus.Running
            : NodeStatus.Success;
    }
}
```

```csharp
// ✅ Building a behavior tree
public class GuardAI : MonoBehaviour
{
    private BTNode _root;

    private void Awake()
    {
        _root = new Selector(
            // Priority 1: Attack if in range and can see player
            new Sequence(
                new IsPlayerInRange(3f),
                new HasLineOfSight(),
                new AttackPlayer()
            ),
            // Priority 2: Chase if player detected
            new Sequence(
                new IsPlayerInRange(15f),
                new HasLineOfSight(),
                new ChasePlayer()
            ),
            // Priority 3: Investigate last known position
            new Sequence(
                new HasLastKnownPosition(),
                new MoveToLastKnownPosition(),
                new LookAround()
            ),
            // Priority 4: Default patrol
            new PatrolWaypoints()
        );
    }

    private void Update() => _root.Evaluate(_context);
}
```

## 3. Goal-Oriented Action Planning (GOAP)

For AI that dynamically plans action sequences to achieve goals (e.g., Skyrim NPCs, F.E.A.R. AI).

```csharp
// ✅ GOAP: AI plans sequences of actions to satisfy goals
public class GOAPAction
{
    public string Name;
    public float Cost;
    public Dictionary<string, bool> Preconditions;  // What must be true before this action
    public Dictionary<string, bool> Effects;          // What becomes true after this action

    public virtual bool IsValid(WorldState state) =>
        Preconditions.All(p => state.GetBool(p.Key) == p.Value);
}

// Example actions:
// Action: AttackEnemy
//   Preconditions: HasWeapon=true, EnemyInRange=true
//   Effects: EnemyDead=true
//   Cost: 1.0

// Action: PickUpWeapon
//   Preconditions: WeaponNearby=true
//   Effects: HasWeapon=true
//   Cost: 0.5

// Action: MoveToEnemy
//   Preconditions: EnemyVisible=true
//   Effects: EnemyInRange=true
//   Cost: 2.0

// GOAP Planner uses A* search over action space to find the cheapest plan
// Goal: EnemyDead=true
// Plan: MoveToWeapon → PickUpWeapon → MoveToEnemy → AttackEnemy
```

## 4. Utility AI (Scoring-Based Decisions)

For AI that weighs multiple competing desires simultaneously (The Sims, strategy games).

```csharp
// ✅ Utility AI: Score every possible action, pick the highest
public class UtilityAI : MonoBehaviour
{
    private readonly List<UtilityAction> _actions = new();

    public void RegisterAction(UtilityAction action) => _actions.Add(action);

    public UtilityAction GetBestAction(AIContext context)
    {
        UtilityAction best = null;
        float bestScore = float.MinValue;

        foreach (var action in _actions)
        {
            float score = action.CalculateScore(context);
            if (score > bestScore)
            {
                bestScore = score;
                best = action;
            }
        }
        return best;
    }
}

public abstract class UtilityAction
{
    public abstract float CalculateScore(AIContext context);
    public abstract void Execute(AIContext context);
}

// Example: Enemy decides between Attack, Flee, Heal
public class FleeAction : UtilityAction
{
    public override float CalculateScore(AIContext ctx)
    {
        float healthPct = ctx.Health / (float)ctx.MaxHealth;
        float enemyProximity = 1f - Mathf.Clamp01(ctx.DistanceToPlayer / 20f);
        return (1f - healthPct) * enemyProximity * 100f; // High score when low HP + enemy near
    }

    public override void Execute(AIContext ctx) => ctx.Agent.SetDestination(ctx.FleePoint);
}
```

## 5. Sensory System (Sight, Hearing)

```csharp
// ✅ AI Perception: sight cone + hearing radius
public class AISenses : MonoBehaviour
{
    [SerializeField] private float _viewDistance = 20f;
    [SerializeField] private float _viewAngle = 120f;
    [SerializeField] private float _hearingRadius = 10f;
    [SerializeField] private LayerMask _targetLayer;
    [SerializeField] private LayerMask _obstructionLayer;

    public bool CanSeeTarget(Transform target)
    {
        Vector3 direction = (target.position - transform.position);
        float distance = direction.magnitude;

        if (distance > _viewDistance) return false;

        float angle = Vector3.Angle(transform.forward, direction);
        if (angle > _viewAngle * 0.5f) return false;

        // Line-of-sight check
        return !Physics.Raycast(transform.position + Vector3.up,
            direction.normalized, distance, _obstructionLayer);
    }

    public bool CanHearTarget(Vector3 soundPosition, float soundVolume)
    {
        float distance = Vector3.Distance(transform.position, soundPosition);
        return distance <= _hearingRadius * soundVolume;
    }
}
```

---

**Execution Protocol**
1. **FSM for Simple AI** (< 5 states): Guards, turrets, simple enemies.
2. **Behavior Trees for Complex AI**: Boss fights, squad AI, stealth AI, multi-phase enemies.
3. **GOAP for Autonomous AI**: NPCs that plan, open-world AI, simulation games.
4. **Utility AI for Competing Needs**: The Sims-style, survival games, strategy AI.
5. **Always Add Sensing**: AI MUST use vision cones and hearing radius, not omniscient `FindObjectOfType`.
