---
name: unity-terrain-open-world
description: Unity Terrain system mastery including heightmaps, splat maps, detail/tree painting, LOD terrain, world streaming, and additive scene loading for open worlds.
author: Diego Villanueva
trigger: When building 3D terrain, open world environments, terrain LOD, world streaming, or configuring terrain details and vegetation.
---

# Terrain & Open World

Unity's Terrain system provides large-scale landscape rendering with heightmap sculpting, texture splatting, grass/tree instancing, and LOD. For open worlds, combine terrain with additive scene streaming.

## 1. Terrain Configuration

```text
✅ Terrain Settings:
├── Terrain Width/Length: 1000m (typical open world tile)
├── Terrain Height: 600m (enough for mountains)
├── Heightmap Resolution: 513 or 1025 (power of 2 + 1)
├── Detail Resolution: 1024 (grass density)
├── Detail Resolution Per Patch: 16
├── Control Texture Resolution: 512 or 1024 (splat map quality)
└── Base Texture Resolution: 1024

Performance Settings:
├── Pixel Error: 5-8 (higher = less triangles, lower quality)
├── Base Map Distance: 500m
├── Detail Distance: 80-150m
├── Tree Distance: 2000m
├── Billboard Start: 100m (trees become billboards)
├── Fade Length: 5
├── Max Mesh Trees: 50 (3D trees rendered simultaneously)
└── Draw Instanced: ✅ (GPU instancing for terrain rendering)
```

## 2. Terrain Layers (Splat Maps)

```csharp
// ✅ Create terrain layers via code (usually done in Editor)
// Terrain uses up to 16 layers (each adds a splat map pass)
// First 4 layers = single pass, each additional 4 = extra draw call

// Layer setup in Editor:
// Layer 0: Grass (Albedo, Normal, Tiling: 15)
// Layer 1: Dirt (Albedo, Normal, Tiling: 20)
// Layer 2: Rock (Albedo, Normal, Tiling: 10)
// Layer 3: Snow (Albedo, Normal, Tiling: 12)

// ✅ Programmatic painting based on slope/height
public void AutoPaint(TerrainData terrainData)
{
    int w = terrainData.alphamapWidth;
    int h = terrainData.alphamapHeight;
    float[,,] splatMap = new float[w, h, terrainData.alphamapLayers];

    for (int y = 0; y < h; y++)
    {
        for (int x = 0; x < w; x++)
        {
            float height = terrainData.GetHeight(y, x) / terrainData.size.y;
            float steepness = terrainData.GetSteepness(
                (float)y / h, (float)x / w) / 90f;

            // Rock on steep surfaces
            if (steepness > 0.5f) { splatMap[x, y, 2] = 1f; continue; }
            // Snow above certain height
            if (height > 0.7f) { splatMap[x, y, 3] = 1f; continue; }
            // Dirt on moderate slopes
            if (steepness > 0.2f) { splatMap[x, y, 1] = 1f; continue; }
            // Grass by default
            splatMap[x, y, 0] = 1f;
        }
    }

    terrainData.SetAlphamaps(0, 0, splatMap);
}
```

## 3. Scene Streaming (Open World)

```csharp
// ✅ Additive scene loading for open world streaming
public class WorldStreamer : MonoBehaviour
{
    [SerializeField] private float _loadDistance = 200f;
    [SerializeField] private float _unloadDistance = 300f;
    [SerializeField] private Transform _player;

    [System.Serializable]
    public struct WorldCell
    {
        public string sceneName;
        public Vector3 center;
        public bool isLoaded;
    }

    [SerializeField] private WorldCell[] _cells;

    private readonly HashSet<string> _loadingScenes = new();

    private void Update()
    {
        for (int i = 0; i < _cells.Length; i++)
        {
            float dist = Vector3.Distance(_player.position, _cells[i].center);

            if (dist < _loadDistance && !_cells[i].isLoaded && !_loadingScenes.Contains(_cells[i].sceneName))
            {
                LoadCell(i);
            }
            else if (dist > _unloadDistance && _cells[i].isLoaded)
            {
                UnloadCell(i);
            }
        }
    }

    private async void LoadCell(int index)
    {
        string sceneName = _cells[index].sceneName;
        _loadingScenes.Add(sceneName);

        await SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Additive);

        _cells[index].isLoaded = true;
        _loadingScenes.Remove(sceneName);
    }

    private async void UnloadCell(int index)
    {
        await SceneManager.UnloadSceneAsync(_cells[index].sceneName);
        _cells[index].isLoaded = false;
    }
}
```

## 4. Terrain LOD & Performance

```text
✅ LOD Strategy for Open World:
├── Terrain: Built-in LOD via Pixel Error setting
├── Trees: Billboard at distance (Tree Distance / Billboard Start)
├── Grass/Details: Fade out at Detail Distance
├── Props/Buildings: LODGroup component (3-4 levels)
│   ├── LOD0: Full mesh (0-30m)
│   ├── LOD1: Reduced mesh (30-80m)
│   ├── LOD2: Low-poly (80-200m)
│   └── Culled: Not rendered (>200m)
└── Occlusion Culling: Bake for static geometry (Edit → Bake)
```

## 5. Terrain Trees (SpeedTree/Instanced)

```text
✅ Tree Rendering Pipeline:
1. Close range: Full 3D mesh (SpeedTree or custom)
2. Medium range: Simplified mesh (LOD1)
3. Far range: Billboard (auto-generated cross quad)
4. Beyond tree distance: Not rendered

Configuration per tree prototype:
├── Bend Factor: 0.5 (wind response)
├── NavMesh Obstacle: ✅ (trees block pathfinding)
└── Random Width/Height: 0.8-1.2 (natural variation)
```

---

**Execution Protocol**
1. **Keep Terrain Layers ≤ 4**: Each group of 4 layers adds an extra draw call. Stay under 4 for mobile, 8 max for PC.
2. **Draw Instanced**: ALWAYS enable `Draw Instanced` on terrain for GPU instancing.
3. **Scene Streaming**: Split open worlds into additive scenes (~200m tiles). Load/unload based on player distance.
4. **LODGroup on Everything**: Every 3D asset MUST have a LODGroup with at least 3 levels + culled distance.
5. **Bake Occlusion Culling**: Use occlusion culling for environments with walls, buildings, or terrain features that block view.
