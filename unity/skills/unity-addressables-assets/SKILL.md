---
name: unity-addressables-assets
description: Unity Addressables system mastery including asset bundles, remote content delivery, memory management, reference counting, catalog updates, and downloadable content (DLC).
author: Diego Villanueva
trigger: When implementing dynamic asset loading, Addressables, remote asset delivery, DLC, memory management, or migrating from Resources.Load.
---

# Addressables Asset System

Addressables replace `Resources.Load()` with an async, reference-counted, remote-capable asset loading system. Assets are loaded by address (string key) and can live locally or on a CDN.

## 1. Why Addressables

```text
❌ Resources.Load() Problems:
- ALL assets in Resources/ are included in build (bloated APK/IPA)
- Synchronous loading blocks main thread
- No remote loading capability
- No memory management (loaded forever)

✅ Addressables Solutions:
- Only loads what's needed, when needed
- Async loading (no frame drops)
- Remote hosting on CDN (download on demand)
- Reference counting (auto-unload when unused)
- Catalog system for content updates without app update
```

## 2. Setup & Configuration

```csharp
// ✅ Mark assets as Addressable in Inspector
// 1. Select asset → check "Addressable" in Inspector
// 2. Assign to an Addressable Group
// 3. Set address (default is asset path, can customize)

// Group Strategy:
// Group: "Local_Static"  → Ships with build (UI, core assets)
//   Build Path: LocalBuildPath
//   Load Path: LocalLoadPath
//
// Group: "Remote_Levels"  → Downloaded from CDN
//   Build Path: RemoteBuildPath
//   Load Path: RemoteLoadPath (https://cdn.example.com/...)
```

## 3. Loading Assets

```csharp
// ✅ Load by address (async)
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;

public class AssetLoader : MonoBehaviour
{
    // AssetReference: Drag-and-drop in Inspector (type-safe)
    [SerializeField] private AssetReference _enemyPrefabRef;
    [SerializeField] private AssetReferenceSprite _iconRef;

    private AsyncOperationHandle<GameObject> _loadHandle;

    public async Awaitable<GameObject> SpawnEnemy(Vector3 position)
    {
        _loadHandle = Addressables.InstantiateAsync(_enemyPrefabRef, position, Quaternion.identity);
        var instance = await _loadHandle.Task;
        return instance;
    }

    // ✅ Load by string address
    public async Awaitable<Sprite> LoadIcon(string address)
    {
        var handle = Addressables.LoadAssetAsync<Sprite>(address);
        var sprite = await handle.Task;
        return sprite; // Remember to release when done!
    }

    // ✅ Load multiple assets by label
    public async Awaitable<IList<GameObject>> LoadAllEnemies()
    {
        var handle = Addressables.LoadAssetsAsync<GameObject>("enemies", null);
        var enemies = await handle.Task;
        return enemies;
    }

    private void OnDestroy()
    {
        // CRITICAL: Release loaded assets
        if (_loadHandle.IsValid())
            Addressables.Release(_loadHandle);
    }
}
```

## 4. Memory Management (Reference Counting)

```csharp
// ✅ ALWAYS release Addressable handles when done
// Every LoadAssetAsync increments ref count
// Every Release decrements ref count
// At ref count 0, asset is unloaded from memory

public class SpriteLoader : MonoBehaviour
{
    private AsyncOperationHandle<Sprite> _currentHandle;

    public async void LoadSprite(string address)
    {
        // Release previous sprite
        if (_currentHandle.IsValid())
            Addressables.Release(_currentHandle);

        // Load new sprite
        _currentHandle = Addressables.LoadAssetAsync<Sprite>(address);
        _image.sprite = await _currentHandle.Task;
    }

    private void OnDestroy()
    {
        if (_currentHandle.IsValid())
            Addressables.Release(_currentHandle);
    }
}

// ❌ NEVER: Load without releasing → MEMORY LEAK
Addressables.LoadAssetAsync<Sprite>("icon"); // Handle lost, never released!
```

## 5. Remote Content Updates (DLC)

```csharp
// ✅ Check for and download remote content updates
public class ContentUpdater : MonoBehaviour
{
    public async Awaitable<bool> CheckForUpdates()
    {
        var checkHandle = Addressables.CheckForCatalogUpdates();
        var catalogs = await checkHandle.Task;
        Addressables.Release(checkHandle);

        if (catalogs.Count > 0)
        {
            var updateHandle = Addressables.UpdateCatalogs(catalogs);
            await updateHandle.Task;
            Addressables.Release(updateHandle);
            return true; // Content updated
        }
        return false;
    }

    // ✅ Pre-download content with progress
    public async Awaitable DownloadContent(string label, Action<float> onProgress)
    {
        var sizeHandle = Addressables.GetDownloadSizeAsync(label);
        long size = await sizeHandle.Task;
        Addressables.Release(sizeHandle);

        if (size > 0)
        {
            var downloadHandle = Addressables.DownloadDependenciesAsync(label);
            while (!downloadHandle.IsDone)
            {
                onProgress?.Invoke(downloadHandle.PercentComplete);
                await Awaitable.NextFrameAsync();
            }
            Addressables.Release(downloadHandle);
        }
    }
}
```

---

**Execution Protocol**
1. **No Resources.Load()**: NEVER use `Resources.Load()` in production. Migrate all dynamic loading to Addressables.
2. **Release Every Handle**: Every `LoadAssetAsync` MUST have a corresponding `Addressables.Release()` in `OnDestroy` or when the asset is no longer needed.
3. **AssetReference in Inspector**: Use `AssetReference` and `AssetReferenceT<T>` for Inspector-assignable Addressable references instead of string addresses.
4. **Group by Usage Pattern**: Group assets loaded together (level assets) into the same Addressable Group for efficient bundle loading.
5. **Remote for DLC**: Use Remote groups for downloadable content. Local groups for core assets that ship with the build.
