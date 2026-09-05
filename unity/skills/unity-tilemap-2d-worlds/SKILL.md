---
name: unity-tilemap-2d-worlds
description: Unity Tilemap system mastery including Rule Tiles, animated tiles, Tilemap Collider, isometric grids, hex grids, and chunk-based 2D world loading.
author: Diego Villanueva
trigger: When building 2D levels with tilemaps, creating Rule Tiles, implementing isometric or hex grids, or managing large 2D worlds with chunk loading.
---

# Tilemap & 2D World Building

Unity's Tilemap system provides efficient tile-based level design for 2D games. Combined with Rule Tiles and custom brushes, it enables rapid level creation with automatic visual coherence.

## 1. Tilemap Layer Architecture

```text
✅ Use multiple Tilemap layers on a single Grid:
Grid (parent)
├── Tilemap_Ground      (Sorting Layer: Ground, Order: 0)
├── Tilemap_Walls       (Sorting Layer: Ground, Order: 1) + TilemapCollider2D
├── Tilemap_Decoration  (Sorting Layer: Decoration, Order: 0)
├── Tilemap_Foreground  (Sorting Layer: Foreground, Order: 0)
└── Tilemap_Collision   (Sorting Layer: None, invisible) + CompositeCollider2D
```

## 2. Rule Tiles (Automatic Tiling)

```text
Rule Tile: Automatically selects the correct sprite based on neighbor context.
Example: A grass tile that shows edges, corners, and center variations.

Setup:
1. Create → 2D → Tiles → Rule Tile
2. Define neighbor rules: (✅ = same tile, ❌ = different tile, ◻ = any)
3. Each rule maps to a sprite or animation

Rule Example (Platform edge):
  ◻ ◻ ◻
  ❌ ✅ ✅  → Left edge sprite
  ◻ ✅ ✅

  ◻ ◻ ◻
  ✅ ✅ ❌  → Right edge sprite
  ✅ ✅ ◻
```

## 3. Tilemap Colliders

```csharp
// ✅ Optimized tilemap collision setup:
// On collision tilemap:
// 1. TilemapCollider2D (Used By Composite: ✅)
// 2. CompositeCollider2D (Geometry Type: Polygons)
// 3. Rigidbody2D (Body Type: Static)
// This merges all tile colliders into optimized polygon shapes
// CRITICAL for performance — individual tile colliders are extremely slow

// For one-way platforms:
// Separate tilemap with PlatformEffector2D
```

## 4. Isometric Tilemap

```text
Grid Settings for Isometric:
├── Cell Layout: Isometric
├── Cell Size: (1, 0.5, 1) — standard iso ratio
└── Cell Swizzle: XYZ

Tilemap Renderer:
├── Sort Order: Top Right (ensures correct depth sorting)
└── Mode: Individual (required for correct iso sorting)

✅ Isometric Z-as-Y sorting:
- Renderer component → Transparency Sort Mode: Custom Axis
- Transparency Sort Axis: (0, 1, -0.26) for standard isometric
```

```csharp
// ✅ Convert screen position to isometric tile position
public Vector3Int ScreenToIsoCell(Vector2 screenPos)
{
    Vector3 worldPos = Camera.main.ScreenToWorldPoint(screenPos);
    return _grid.WorldToCell(worldPos);
}

// ✅ Place tiles programmatically
public void SetTile(Vector3Int cellPos, TileBase tile)
{
    _tilemap.SetTile(cellPos, tile);
}
```

## 5. Hex Grid

```text
Grid Settings for Hex:
├── Cell Layout: Hexagonal (Point Top or Flat Top)
├── Cell Size: Auto-calculated
└── Cell Swizzle: XYZ

Hex Grid Neighbors:
- Point-Top hex has 6 neighbors at specific offsets
- Even/odd row offset for staggered coordinates
```

```csharp
// ✅ Get hex neighbors (offset coordinates)
public static Vector3Int[] GetHexNeighbors(Vector3Int cell, bool evenRow)
{
    if (evenRow)
    {
        return new[]
        {
            cell + new Vector3Int(1, 0, 0),   // Right
            cell + new Vector3Int(-1, 0, 0),  // Left
            cell + new Vector3Int(0, 1, 0),   // Upper Right
            cell + new Vector3Int(-1, 1, 0),  // Upper Left
            cell + new Vector3Int(0, -1, 0),  // Lower Right
            cell + new Vector3Int(-1, -1, 0)  // Lower Left
        };
    }
    else
    {
        return new[]
        {
            cell + new Vector3Int(1, 0, 0),
            cell + new Vector3Int(-1, 0, 0),
            cell + new Vector3Int(1, 1, 0),
            cell + new Vector3Int(0, 1, 0),
            cell + new Vector3Int(1, -1, 0),
            cell + new Vector3Int(0, -1, 0)
        };
    }
}
```

## 6. Chunk-Based World Loading (Large 2D Worlds)

```csharp
// ✅ Load/unload tilemap chunks based on player position
public class ChunkManager2D : MonoBehaviour
{
    [SerializeField] private int _chunkSize = 16;
    [SerializeField] private int _loadRadius = 2;
    [SerializeField] private Transform _player;

    private readonly Dictionary<Vector2Int, TilemapChunk> _loadedChunks = new();

    private void Update()
    {
        Vector2Int playerChunk = WorldToChunk(_player.position);

        // Load nearby chunks
        for (int x = -_loadRadius; x <= _loadRadius; x++)
        {
            for (int y = -_loadRadius; y <= _loadRadius; y++)
            {
                var chunkPos = playerChunk + new Vector2Int(x, y);
                if (!_loadedChunks.ContainsKey(chunkPos))
                    LoadChunk(chunkPos);
            }
        }

        // Unload distant chunks
        var toUnload = _loadedChunks.Keys
            .Where(k => Vector2Int.Distance(k, playerChunk) > _loadRadius + 1)
            .ToList();
        foreach (var key in toUnload)
            UnloadChunk(key);
    }

    private Vector2Int WorldToChunk(Vector3 worldPos) =>
        new(Mathf.FloorToInt(worldPos.x / _chunkSize),
            Mathf.FloorToInt(worldPos.y / _chunkSize));
}
```

---

**Execution Protocol**
1. **Composite Colliders**: ALWAYS use `CompositeCollider2D` with tilemaps. Individual tile colliders destroy performance.
2. **Rule Tiles for Consistency**: Use Rule Tiles for terrain, walls, and any auto-tiling patterns. Never manually place edge/corner tiles.
3. **Separate Collision Layer**: Use an invisible tilemap layer for collision geometry. Visual and collision layers can differ.
4. **Chunk Loading for Large Worlds**: Any 2D world larger than 10 screens MUST use chunk-based loading to manage memory.
5. **Sorting Order**: Use Sorting Layers and Order in Layer to control draw order. NEVER rely on hierarchy position for rendering order.
