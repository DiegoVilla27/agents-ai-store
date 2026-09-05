---
name: unity-networking-dedicated-server
description: Dedicated server architecture for Unity multiplayer including Unity Multiplayer Services, Relay, Lobby, Matchmaker, headless builds, and authoritative server design.
author: Diego Villanueva
trigger: When setting up dedicated game servers, configuring Unity Gaming Services (Relay, Lobby), building headless servers, or designing authoritative multiplayer architecture.
---

# Dedicated Server & Multiplayer Services

Production multiplayer games require dedicated servers, matchmaking, and relay services. Unity Gaming Services (UGS) provides cloud infrastructure; alternatively, deploy your own headless server builds.

## 1. Architecture Models

```text
Peer-to-Peer (Host-based):
├── One player acts as host + server
├── Cheap, no server costs
├── Host advantage (0 latency)
├── If host disconnects, game ends
└── ✅ Use for: Co-op, casual games, prototypes

Client-Server (Dedicated):
├── Headless server binary runs on cloud
├── All players are equal (no host advantage)
├── Server persists regardless of player disconnects
├── Server costs (cloud hosting)
└── ✅ Use for: Competitive, MMO, persistent worlds

Relay-based:
├── NAT punch-through via relay servers
├── Players connect without port forwarding
├── Unity Relay Service handles connectivity
└── ✅ Use for: P2P games that need NAT traversal
```

## 2. Unity Relay (NAT Traversal)

```csharp
// ✅ Unity Relay: Connect players without port forwarding
using Unity.Services.Relay;
using Unity.Networking.Transport.Relay;

public class RelayManager : MonoBehaviour
{
    // Host creates a relay allocation
    public async Task<string> CreateRelay(int maxPlayers)
    {
        var allocation = await RelayService.Instance.CreateAllocationAsync(maxPlayers);
        var joinCode = await RelayService.Instance.GetJoinCodeAsync(allocation.AllocationId);

        // Configure Netcode transport to use Relay
        var transport = NetworkManager.Singleton.GetComponent<UnityTransport>();
        var relayData = new RelayServerData(allocation, "dtls"); // Encrypted
        transport.SetRelayServerData(relayData);

        NetworkManager.Singleton.StartHost();
        return joinCode; // Share this code with friends
    }

    // Client joins via code
    public async Task JoinRelay(string joinCode)
    {
        var allocation = await RelayService.Instance.JoinAllocationAsync(joinCode);

        var transport = NetworkManager.Singleton.GetComponent<UnityTransport>();
        var relayData = new RelayServerData(allocation, "dtls");
        transport.SetRelayServerData(relayData);

        NetworkManager.Singleton.StartClient();
    }
}
```

## 3. Unity Lobby (Matchmaking)

```csharp
// ✅ Unity Lobby: Room-based matchmaking
using Unity.Services.Lobbies;
using Unity.Services.Lobbies.Models;

public class LobbyManager : MonoBehaviour
{
    private Lobby _currentLobby;

    public async Task<Lobby> CreateLobby(string name, int maxPlayers)
    {
        var options = new CreateLobbyOptions
        {
            IsPrivate = false,
            Data = new Dictionary<string, DataObject>
            {
                { "GameMode", new DataObject(DataObject.VisibilityOptions.Public, "Deathmatch") },
                { "Map", new DataObject(DataObject.VisibilityOptions.Public, "Arena_01") },
                { "RelayCode", new DataObject(DataObject.VisibilityOptions.Member, "") }
            }
        };

        _currentLobby = await LobbyService.Instance.CreateLobbyAsync(name, maxPlayers, options);
        StartCoroutine(HeartbeatLobby()); // Keep lobby alive
        return _currentLobby;
    }

    public async Task<List<Lobby>> QueryLobbies()
    {
        var options = new QueryLobbiesOptions
        {
            Count = 25,
            Filters = new List<QueryFilter>
            {
                new(QueryFilter.FieldOptions.AvailableSlots, "0", QueryFilter.OpOptions.GT)
            },
            Order = new List<QueryOrder>
            {
                new(false, QueryOrder.FieldOptions.Created) // Newest first
            }
        };

        var response = await LobbyService.Instance.QueryLobbiesAsync(options);
        return response.Results;
    }

    private IEnumerator HeartbeatLobby()
    {
        while (_currentLobby != null)
        {
            LobbyService.Instance.SendHeartbeatPingAsync(_currentLobby.Id);
            yield return new WaitForSeconds(15f); // Heartbeat every 15s
        }
    }
}
```

## 4. Headless Server Build

```text
✅ Build Settings for Dedicated Server:
1. File → Build Settings → Target Platform: Dedicated Server
2. Select Server Platform (Linux for cloud, Windows for local testing)
3. Build produces a headless binary (no GPU, no window)

✅ Server-specific code:
#if UNITY_SERVER || UNITY_DEDICATED_SERVER
    // Server-only logic (no rendering, no input)
    Application.targetFrameRate = 60;
    QualitySettings.vSyncCount = 0;
    NetworkManager.Singleton.StartServer();
#else
    // Client code
    ShowMainMenu();
#endif
```

```csharp
// ✅ Server startup script
public class DedicatedServer : MonoBehaviour
{
    private void Start()
    {
        #if UNITY_SERVER
        Application.targetFrameRate = 60;
        Debug.Log($"Server starting on port {_port}...");

        var transport = NetworkManager.Singleton.GetComponent<UnityTransport>();
        transport.SetConnectionData("0.0.0.0", (ushort)_port);

        NetworkManager.Singleton.StartServer();
        NetworkManager.Singleton.OnClientConnectedCallback += OnClientConnected;
        NetworkManager.Singleton.OnClientDisconnectCallback += OnClientDisconnected;
        #endif
    }

    private void OnClientConnected(ulong clientId)
    {
        Debug.Log($"Client {clientId} connected. Total: {NetworkManager.Singleton.ConnectedClientsList.Count}");
    }
}
```

## 5. Network Tick Rate & Simulation

```csharp
// ✅ Configure network tick rate
// NetworkManager → Network Tick Rate: 30 (ticks per second)
// This is INDEPENDENT of frame rate
// Server simulates at 30 ticks/s, clients render at 60+ fps

// ✅ Use NetworkTime for synchronized timing
public class GameTimer : NetworkBehaviour
{
    private void Update()
    {
        // Synchronized time across all clients
        double networkTime = NetworkManager.ServerTime.Time;
        int currentTick = NetworkManager.ServerTime.Tick;
    }
}
```

---

**Execution Protocol**
1. **Server Build Target**: Use Unity's "Dedicated Server" build target for headless server binaries. Do NOT build a regular player build and hide the window.
2. **Relay for Casual**: Use Unity Relay for co-op and casual games where players join via code.
3. **Lobby for Matchmaking**: Use Unity Lobby for room-based matchmaking with filtering.
4. **Heartbeat Lobbies**: Send lobby heartbeat every 15 seconds or the lobby expires after 30 seconds.
5. **Tick Rate Selection**: 30 ticks/s for most games, 60+ for competitive FPS, 10 for slow-paced strategy.
