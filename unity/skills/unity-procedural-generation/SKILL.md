---
name: unity-procedural-generation
description: Procedural content generation for Unity including Perlin/Simplex noise, Wave Function Collapse, L-Systems, dungeon generators, biome systems, and infinite terrain.
author: Diego Villanueva
trigger: When implementing procedural terrain, dungeon generation, noise-based world building, L-System vegetation, or Wave Function Collapse level design.
---

# Procedural Generation

Procedural generation creates infinite replayability by algorithmically generating content. Master these techniques: noise-based terrain, dungeon graph algorithms, Wave Function Collapse, and L-Systems.

## 1. Perlin Noise (Terrain & Heightmaps)

```csharp
// ✅ 2D heightmap terrain generation
public class TerrainGenerator : MonoBehaviour
{
    [SerializeField] private int _width = 256;
    [SerializeField] private int _height = 256;
    [SerializeField] private float _scale = 20f;
    [SerializeField] private int _octaves = 4;
    [SerializeField] private float _persistence = 0.5f;
    [SerializeField] private float _lacunarity = 2f;
    [SerializeField] private int _seed;

    public float[,] GenerateHeightMap()
    {
        var heightMap = new float[_width, _height];
        var rng = new System.Random(_seed);
        var offsets = new Vector2[_octaves];

        for (int i = 0; i < _octaves; i++)
            offsets[i] = new Vector2(rng.Next(-100000, 100000), rng.Next(-100000, 100000));

        float maxHeight = float.MinValue;
        float minHeight = float.MaxValue;

        for (int y = 0; y < _height; y++)
        {
            for (int x = 0; x < _width; x++)
            {
                float amplitude = 1f;
                float frequency = 1f;
                float noiseHeight = 0f;

                for (int i = 0; i < _octaves; i++)
                {
                    float sampleX = (x - _width / 2f) / _scale * frequency + offsets[i].x;
                    float sampleY = (y - _height / 2f) / _scale * frequency + offsets[i].y;
                    float perlinValue = Mathf.PerlinNoise(sampleX, sampleY) * 2f - 1f;

                    noiseHeight += perlinValue * amplitude;
                    amplitude *= _persistence;
                    frequency *= _lacunarity;
                }

                heightMap[x, y] = noiseHeight;
                maxHeight = Mathf.Max(maxHeight, noiseHeight);
                minHeight = Mathf.Min(minHeight, noiseHeight);
            }
        }

        // Normalize to 0-1
        for (int y = 0; y < _height; y++)
            for (int x = 0; x < _width; x++)
                heightMap[x, y] = Mathf.InverseLerp(minHeight, maxHeight, heightMap[x, y]);

        return heightMap;
    }
}
```

## 2. Dungeon Generation (BSP / Random Walk)

```csharp
// ✅ Binary Space Partitioning dungeon generator
public class BSPDungeon
{
    public List<RectInt> Rooms { get; } = new();
    public List<(Vector2Int, Vector2Int)> Corridors { get; } = new();

    public void Generate(RectInt bounds, int minRoomSize, int maxDepth)
    {
        var partitions = new List<RectInt> { bounds };
        Split(bounds, minRoomSize, maxDepth, 0, partitions);

        // Create rooms within partitions
        foreach (var partition in partitions)
        {
            int roomWidth = Random.Range(minRoomSize, partition.width - 2);
            int roomHeight = Random.Range(minRoomSize, partition.height - 2);
            int x = partition.x + Random.Range(1, partition.width - roomWidth);
            int y = partition.y + Random.Range(1, partition.height - roomHeight);
            Rooms.Add(new RectInt(x, y, roomWidth, roomHeight));
        }

        // Connect rooms with corridors
        for (int i = 0; i < Rooms.Count - 1; i++)
        {
            var centerA = Rooms[i].center;
            var centerB = Rooms[i + 1].center;
            Corridors.Add((
                Vector2Int.RoundToInt(centerA),
                Vector2Int.RoundToInt(centerB)));
        }
    }

    private void Split(RectInt rect, int minSize, int maxDepth, int depth, List<RectInt> results)
    {
        if (depth >= maxDepth || rect.width < minSize * 2 || rect.height < minSize * 2)
            return;

        bool splitHorizontal = Random.value > 0.5f;
        if (rect.width > rect.height * 1.5f) splitHorizontal = false;
        if (rect.height > rect.width * 1.5f) splitHorizontal = true;

        int splitPos = splitHorizontal
            ? Random.Range(rect.y + minSize, rect.yMax - minSize)
            : Random.Range(rect.x + minSize, rect.xMax - minSize);

        results.Remove(rect);

        if (splitHorizontal)
        {
            var a = new RectInt(rect.x, rect.y, rect.width, splitPos - rect.y);
            var b = new RectInt(rect.x, splitPos, rect.width, rect.yMax - splitPos);
            results.Add(a); results.Add(b);
            Split(a, minSize, maxDepth, depth + 1, results);
            Split(b, minSize, maxDepth, depth + 1, results);
        }
        else
        {
            var a = new RectInt(rect.x, rect.y, splitPos - rect.x, rect.height);
            var b = new RectInt(splitPos, rect.y, rect.xMax - splitPos, rect.height);
            results.Add(a); results.Add(b);
            Split(a, minSize, maxDepth, depth + 1, results);
            Split(b, minSize, maxDepth, depth + 1, results);
        }
    }
}
```

## 3. Wave Function Collapse (WFC)

```csharp
// ✅ WFC: Constraint-based level generation
// Each cell can be one of N tile types
// Tiles have adjacency rules (which tiles can be neighbors)
// Algorithm: repeatedly collapse the cell with lowest entropy

public class WFCCell
{
    public HashSet<int> PossibleTiles;
    public int CollapsedTile = -1;
    public bool IsCollapsed => CollapsedTile >= 0;
    public int Entropy => PossibleTiles.Count;
}

public class WFCSolver
{
    private readonly WFCCell[,] _grid;
    private readonly Dictionary<int, HashSet<int>>[] _adjacencyRules; // per direction

    public bool Solve()
    {
        while (HasUncollapsedCells())
        {
            var cell = GetLowestEntropyCell();
            if (cell.Entropy == 0) return false; // Contradiction!

            // Collapse: pick random tile from possibilities
            int tile = cell.PossibleTiles.ElementAt(Random.Range(0, cell.Entropy));
            cell.CollapsedTile = tile;
            cell.PossibleTiles = new HashSet<int> { tile };

            // Propagate constraints to neighbors
            PropagateConstraints(cell);
        }
        return true;
    }
}
```

## 4. L-Systems (Vegetation, Fractals)

```csharp
// ✅ L-System for procedural tree/plant generation
public class LSystem
{
    private Dictionary<char, string> _rules = new();
    private string _axiom;
    private float _angle;

    public LSystem(string axiom, float angle)
    {
        _axiom = axiom;
        _angle = angle;
    }

    public void AddRule(char symbol, string replacement) => _rules[symbol] = replacement;

    public string Generate(int iterations)
    {
        string current = _axiom;
        for (int i = 0; i < iterations; i++)
        {
            var sb = new StringBuilder();
            foreach (char c in current)
                sb.Append(_rules.ContainsKey(c) ? _rules[c] : c.ToString());
            current = sb.ToString();
        }
        return current;
    }
}

// Usage: Simple tree
// Axiom: "F"
// Rules: F → "FF+[+F-F-F]-[-F+F+F]"
// F = draw forward, + = turn right, - = turn left, [ = save, ] = restore
```

---

**Execution Protocol**
1. **Seed Everything**: ALL procedural generation MUST accept a seed for reproducibility and debugging.
2. **Generate Off Main Thread**: Large generation (terrain, dungeons) MUST run in Jobs or on a background thread.
3. **Validate Output**: After generation, validate connectivity (all rooms reachable), playability (spawn/exit accessible), and performance (polygon budget).
4. **WFC for Structured Content**: Use WFC for levels that need visual coherence (tiled environments, city blocks).
5. **Noise Composition**: Always use octave-based noise (persistence + lacunarity) for natural-looking terrain. Single-octave Perlin looks artificial.
