---
name: unity-networking-multiplayer
description: Multiplayer networking for Unity including Netcode for GameObjects, NetworkVariable, RPCs, client prediction, server reconciliation, Mirror, and Photon.
author: Diego Villanueva
trigger: When implementing multiplayer gameplay, networked state synchronization, RPCs, client prediction, or choosing a networking framework.
---

# Networking & Multiplayer

Multiplayer game networking is fundamentally different from web networking. Games require real-time state synchronization at 20-60 ticks/second with latency compensation. This document covers Unity's official Netcode and alternative frameworks.

## 1. Framework Selection

```text
Netcode for GameObjects (NGO):
✅ Use for: Unity's official solution, deep integration, lobby/relay services
- Client-server authoritative model
- NetworkVariable for state sync
- RPCs for events
- Scene management, object spawning
- Unity Gaming Services integration (Relay, Lobby, Matchmaker)

Mirror:
✅ Use for: Self-hosted servers, dedicated server games, mature ecosystem
- Fork of UNET, battle-tested
- SyncVar/SyncList for state
- Command/ClientRpc for RPCs
- Extensive transport layer support

Photon (PUN/Fusion):
✅ Use for: Quick prototyping, cloud-hosted, mobile games
- Cloud-based relay (no server hosting)
- Room-based matchmaking
- Photon Fusion: state authority (more advanced)
```

## 2. Netcode for GameObjects (NGO) — Setup

```csharp
// ✅ Network Manager setup
// 1. Add NetworkManager component to scene
// 2. Add UnityTransport component
// 3. Register all network prefabs in NetworkManager

// ✅ NetworkBehaviour: The networked MonoBehaviour
public class PlayerNetwork : NetworkBehaviour
{
    // Synchronized state (server-authoritative)
    private NetworkVariable<int> _health = new(
        100,
        NetworkVariableReadPermission.Everyone,
        NetworkVariableWritePermission.Server);

    private NetworkVariable<Vector3> _networkPosition = new(
        default,
        NetworkVariableReadPermission.Everyone,
        NetworkVariableWritePermission.Owner);

    public override void OnNetworkSpawn()
    {
        if (IsOwner)
        {
            // Initialize local player
            _health.OnValueChanged += OnHealthChanged;
        }
    }

    private void OnHealthChanged(int oldValue, int newValue)
    {
        UpdateHealthUI(newValue);
    }
}
```

## 3. RPCs (Remote Procedure Calls)

```csharp
// ✅ Server RPC: Client → Server (request)
// Client RPC: Server → Client(s) (broadcast)

public class CombatNetwork : NetworkBehaviour
{
    // Client requests server to deal damage
    [ServerRpc]
    public void DealDamageServerRpc(ulong targetId, int damage)
    {
        // Validate on server (anti-cheat)
        if (damage > MAX_DAMAGE) return;
        if (!IsInRange(targetId)) return;

        // Apply damage on server
        var target = NetworkManager.SpawnManager.SpawnedObjects[targetId];
        target.GetComponent<HealthNetwork>().TakeDamage(damage);

        // Broadcast VFX to all clients
        PlayHitEffectClientRpc(target.transform.position);
    }

    // Server tells all clients to play VFX
    [ClientRpc]
    private void PlayHitEffectClientRpc(Vector3 position)
    {
        SpawnHitVFX(position);
    }
}
```

## 4. State Synchronization Patterns

```csharp
// ✅ NetworkVariable for continuous state
private NetworkVariable<PlayerState> _state = new();

public struct PlayerState : INetworkSerializable
{
    public Vector3 Position;
    public Quaternion Rotation;
    public float Speed;
    public bool IsGrounded;

    public void NetworkSerialize<T>(BufferSerializer<T> serializer) where T : IReaderWriter
    {
        serializer.SerializeValue(ref Position);
        serializer.SerializeValue(ref Rotation);
        serializer.SerializeValue(ref Speed);
        serializer.SerializeValue(ref IsGrounded);
    }
}

// ✅ Client-side interpolation for smooth remote player rendering
public class NetworkInterpolation : NetworkBehaviour
{
    private Vector3 _targetPosition;
    private Quaternion _targetRotation;
    private float _interpolationSpeed = 15f;

    private void Update()
    {
        if (!IsOwner)
        {
            // Smoothly interpolate remote player positions
            transform.position = Vector3.Lerp(
                transform.position, _targetPosition, _interpolationSpeed * Time.deltaTime);
            transform.rotation = Quaternion.Slerp(
                transform.rotation, _targetRotation, _interpolationSpeed * Time.deltaTime);
        }
    }
}
```

## 5. Client Prediction & Server Reconciliation

```csharp
// ✅ Client prediction for responsive movement
public class PredictedMovement : NetworkBehaviour
{
    private struct InputPayload
    {
        public int Tick;
        public Vector3 MoveDirection;
        public bool Jump;
    }

    private struct StatePayload
    {
        public int Tick;
        public Vector3 Position;
        public Vector3 Velocity;
    }

    private readonly Queue<InputPayload> _inputBuffer = new();
    private readonly List<StatePayload> _stateHistory = new();

    private void FixedUpdate()
    {
        if (IsOwner)
        {
            // 1. Capture input
            var input = new InputPayload { Tick = _currentTick, MoveDirection = _moveInput };

            // 2. Predict locally (immediate response)
            ApplyMovement(input);
            _stateHistory.Add(new StatePayload
            {
                Tick = _currentTick,
                Position = transform.position,
                Velocity = _rb.linearVelocity
            });

            // 3. Send input to server
            SendInputServerRpc(input);
        }
    }

    // Server processes input and sends authoritative state back
    [ServerRpc]
    private void SendInputServerRpc(InputPayload input)
    {
        ApplyMovement(input);
        SendStateClientRpc(new StatePayload
        {
            Tick = input.Tick,
            Position = transform.position,
            Velocity = _rb.linearVelocity
        });
    }

    // Client reconciles with server state
    [ClientRpc]
    private void SendStateClientRpc(StatePayload serverState)
    {
        if (!IsOwner) return;

        // Compare predicted state with server state
        var predicted = _stateHistory.Find(s => s.Tick == serverState.Tick);
        float error = Vector3.Distance(predicted.Position, serverState.Position);

        if (error > RECONCILIATION_THRESHOLD)
        {
            // Snap to server state and replay inputs
            transform.position = serverState.Position;
            ReplayInputsFrom(serverState.Tick);
        }
    }
}
```

## 6. Network Object Spawning

```csharp
// ✅ Spawn networked objects (server-authoritative)
[ServerRpc]
public void SpawnProjectileServerRpc(Vector3 position, Vector3 direction)
{
    var projectile = Instantiate(_projectilePrefab, position, Quaternion.LookRotation(direction));
    projectile.GetComponent<NetworkObject>().Spawn(); // Replicates to all clients
}

// ✅ Despawn
[ServerRpc]
public void DestroyProjectileServerRpc(ulong networkObjectId)
{
    if (NetworkManager.SpawnManager.SpawnedObjects.TryGetValue(networkObjectId, out var obj))
        obj.Despawn(); // Removes from all clients
}
```

---

**Execution Protocol**
1. **Server-Authoritative**: The server ALWAYS has the final say on game state. Clients predict, server validates.
2. **Validate All Client Input**: NEVER trust client-sent damage values, positions, or state changes. Validate on the server.
3. **Minimize Network Traffic**: Only sync what changes. Use `NetworkVariable` with `OnValueChanged` instead of syncing every frame.
4. **Interpolate Remote Players**: NEVER snap remote player positions. Use interpolation/extrapolation for smooth rendering.
5. **Use NetworkVariable for State, RPCs for Events**: Persistent values (health, position) = NetworkVariable. One-shot events (shoot, jump) = RPC.
