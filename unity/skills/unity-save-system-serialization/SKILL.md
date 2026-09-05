---
name: unity-save-system-serialization
description: Save system architecture for Unity including JSON/Binary serialization, AES encryption, PlayerPrefs alternatives, cloud saves, save slots, and auto-save systems.
author: Diego Villanueva
trigger: When implementing save/load functionality, data persistence, save file encryption, cloud saves, or serialization systems.
---

# Save System & Serialization

Every game needs persistent data. A professional save system uses structured serialization, encryption for sensitive data, multiple save slots, and cloud backup. NEVER use `PlayerPrefs` for game state.

## 1. Save Data Architecture

```csharp
// ✅ Structured save data model
[System.Serializable]
public class SaveData
{
    public string version = "1.0.0";
    public long timestamp;
    public PlayerSaveData player;
    public WorldSaveData world;
    public SettingsSaveData settings;
}

[System.Serializable]
public class PlayerSaveData
{
    public Vector3Serializable position;
    public int health;
    public int maxHealth;
    public int experience;
    public int level;
    public List<string> inventoryItemIds;
    public List<string> completedQuestIds;
}

[System.Serializable]
public class WorldSaveData
{
    public string currentScene;
    public List<EnemySpawnData> defeatedEnemies;
    public List<ChestData> openedChests;
    public float playTime;
}

// Unity's Vector3 is not serializable by default
[System.Serializable]
public struct Vector3Serializable
{
    public float x, y, z;

    public Vector3Serializable(Vector3 v) { x = v.x; y = v.y; z = v.z; }
    public Vector3 ToVector3() => new(x, y, z);

    public static implicit operator Vector3Serializable(Vector3 v) => new(v);
    public static implicit operator Vector3(Vector3Serializable v) => v.ToVector3();
}
```

## 2. JSON Serialization

```csharp
// ✅ JSON save/load service
public class SaveService
{
    private readonly string _savePath;

    public SaveService()
    {
        _savePath = Path.Combine(Application.persistentDataPath, "Saves");
        Directory.CreateDirectory(_savePath);
    }

    public void Save(SaveData data, int slot = 0)
    {
        data.timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        string json = JsonUtility.ToJson(data, prettyPrint: true);
        string path = GetSlotPath(slot);

        File.WriteAllText(path, json);
        Debug.Log($"Game saved to slot {slot}: {path}");
    }

    public SaveData Load(int slot = 0)
    {
        string path = GetSlotPath(slot);
        if (!File.Exists(path))
        {
            Debug.LogWarning($"No save file found at slot {slot}");
            return null;
        }

        string json = File.ReadAllText(path);
        return JsonUtility.FromJson<SaveData>(json);
    }

    public bool SaveExists(int slot = 0) => File.Exists(GetSlotPath(slot));

    public void Delete(int slot = 0)
    {
        string path = GetSlotPath(slot);
        if (File.Exists(path)) File.Delete(path);
    }

    private string GetSlotPath(int slot) =>
        Path.Combine(_savePath, $"save_slot_{slot}.json");
}
```

## 3. Encrypted Saves (AES)

```csharp
// ✅ AES encryption for save files (prevent tampering)
using System.Security.Cryptography;

public class EncryptedSaveService
{
    private readonly byte[] _key; // 32 bytes for AES-256
    private readonly byte[] _iv;  // 16 bytes

    public EncryptedSaveService(string password)
    {
        using var deriveBytes = new Rfc2898DeriveBytes(password, 16, 100000, HashAlgorithmName.SHA256);
        _key = deriveBytes.GetBytes(32);
        _iv = deriveBytes.GetBytes(16);
    }

    public void SaveEncrypted(SaveData data, string path)
    {
        string json = JsonUtility.ToJson(data);
        byte[] encrypted = Encrypt(System.Text.Encoding.UTF8.GetBytes(json));
        File.WriteAllBytes(path, encrypted);
    }

    public SaveData LoadEncrypted(string path)
    {
        byte[] encrypted = File.ReadAllBytes(path);
        byte[] decrypted = Decrypt(encrypted);
        string json = System.Text.Encoding.UTF8.GetString(decrypted);
        return JsonUtility.FromJson<SaveData>(json);
    }

    private byte[] Encrypt(byte[] data)
    {
        using var aes = Aes.Create();
        aes.Key = _key;
        aes.IV = _iv;
        using var encryptor = aes.CreateEncryptor();
        return encryptor.TransformFinalBlock(data, 0, data.Length);
    }

    private byte[] Decrypt(byte[] data)
    {
        using var aes = Aes.Create();
        aes.Key = _key;
        aes.IV = _iv;
        using var decryptor = aes.CreateDecryptor();
        return decryptor.TransformFinalBlock(data, 0, data.Length);
    }
}
```

## 4. Auto-Save System

```csharp
// ✅ Auto-save with configurable interval
public class AutoSaveManager : MonoBehaviour
{
    [SerializeField] private float _autoSaveInterval = 300f; // 5 minutes
    [SerializeField] private IntEventChannel _onAutoSave; // Notify UI

    private float _timer;
    private SaveService _saveService;

    private void Update()
    {
        _timer += Time.unscaledDeltaTime;
        if (_timer >= _autoSaveInterval)
        {
            _timer = 0f;
            PerformAutoSave();
        }
    }

    private void PerformAutoSave()
    {
        var data = GatherSaveData();
        _saveService.Save(data, slot: 99); // Dedicated auto-save slot
        _onAutoSave?.Raise(0); // Notify UI to show "Auto-saved" toast
    }

    // Also auto-save on specific events
    public void OnCheckpointReached() => PerformAutoSave();
    public void OnApplicationPause(bool paused) { if (paused) PerformAutoSave(); }
}
```

## 5. Save Slot UI Data

```csharp
// ✅ Save slot metadata for UI display
[System.Serializable]
public class SaveSlotInfo
{
    public int slotIndex;
    public bool isEmpty;
    public string playerName;
    public int playerLevel;
    public string sceneName;
    public float playTimeHours;
    public string lastSaved; // Formatted date string
    public Sprite screenshot;  // Thumbnail
}

public SaveSlotInfo[] GetAllSlotInfos()
{
    var infos = new SaveSlotInfo[3]; // 3 save slots
    for (int i = 0; i < 3; i++)
    {
        if (_saveService.SaveExists(i))
        {
            var data = _saveService.Load(i);
            infos[i] = new SaveSlotInfo
            {
                slotIndex = i,
                isEmpty = false,
                playerLevel = data.player.level,
                sceneName = data.world.currentScene,
                playTimeHours = data.world.playTime / 3600f,
                lastSaved = DateTimeOffset.FromUnixTimeSeconds(data.timestamp)
                    .LocalDateTime.ToString("yyyy-MM-dd HH:mm")
            };
        }
        else
        {
            infos[i] = new SaveSlotInfo { slotIndex = i, isEmpty = true };
        }
    }
    return infos;
}
```

---

**Execution Protocol**
1. **Never PlayerPrefs for Game State**: `PlayerPrefs` is for user preferences ONLY (volume, language). Game state goes in structured save files.
2. **Application.persistentDataPath**: ALWAYS save to `Application.persistentDataPath`. It persists across app updates and is platform-appropriate.
3. **Version Your Save Data**: Include a `version` field in save data. Use it to migrate old saves when the schema changes.
4. **Encrypt Competitive Saves**: For competitive or economy-sensitive games, encrypt save files to prevent tampering.
5. **Auto-Save on Pause**: ALWAYS auto-save when the app is paused/backgrounded (mobile) to prevent data loss.
