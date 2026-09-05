---
name: unity-rpg-systems
description: RPG system architecture for Unity including inventory management, stats/attributes, quest systems, dialogue trees, skill trees, loot tables, and crafting systems.
author: Diego Villanueva
trigger: When building RPG game systems like inventory, character stats, quests, dialogue, skill trees, loot drops, or crafting mechanics.
---

# RPG Game Systems

RPG systems are the most data-heavy and interconnected systems in game development. Every system (stats, inventory, quests, skills, loot) must be data-driven via ScriptableObjects and loosely coupled through event channels.

## 1. Stats & Attributes System

```csharp
// ✅ Flexible stat system with modifiers
[System.Serializable]
public class Stat
{
    [SerializeField] private float _baseValue;
    private readonly List<StatModifier> _modifiers = new();

    public float Value => CalculateFinalValue();

    public void AddModifier(StatModifier mod)
    {
        _modifiers.Add(mod);
        _modifiers.Sort((a, b) => a.Order.CompareTo(b.Order));
    }

    public void RemoveModifier(StatModifier mod) => _modifiers.Remove(mod);
    public void RemoveAllFromSource(object source) =>
        _modifiers.RemoveAll(m => m.Source == source);

    private float CalculateFinalValue()
    {
        float value = _baseValue;
        float sumPercentAdd = 0;

        foreach (var mod in _modifiers)
        {
            switch (mod.Type)
            {
                case StatModType.Flat:
                    value += mod.Value;
                    break;
                case StatModType.PercentAdd:
                    sumPercentAdd += mod.Value;
                    break;
                case StatModType.PercentMult:
                    value *= 1 + mod.Value;
                    break;
            }

            if (mod.Type == StatModType.PercentAdd)
            {
                // Apply accumulated percentage at the boundary
                var nextMod = _modifiers.IndexOf(mod) + 1;
                if (nextMod >= _modifiers.Count || _modifiers[nextMod].Type != StatModType.PercentAdd)
                {
                    value *= 1 + sumPercentAdd;
                    sumPercentAdd = 0;
                }
            }
        }

        return Mathf.Max(0, (float)Math.Round(value, 4));
    }
}

public enum StatModType { Flat = 100, PercentAdd = 200, PercentMult = 300 }

public class StatModifier
{
    public float Value;
    public StatModType Type;
    public int Order => (int)Type;
    public object Source;

    public StatModifier(float value, StatModType type, object source = null)
    {
        Value = value; Type = type; Source = source;
    }
}

// Character stats
public class CharacterStats : MonoBehaviour
{
    public Stat Strength = new();
    public Stat Dexterity = new();
    public Stat Intelligence = new();
    public Stat MaxHealth = new();
    public Stat AttackPower = new();
    public Stat Defense = new();
    public Stat CritChance = new();
    public Stat MoveSpeed = new();
}
```

## 2. Inventory System

```csharp
// ✅ Slot-based inventory
[CreateAssetMenu(menuName = "Data/Item")]
public class ItemData : ScriptableObject
{
    public string itemName;
    public Sprite icon;
    public string description;
    public ItemType type;
    public int maxStack = 1;
    public int buyPrice;
    public int sellPrice;
    public StatModifier[] statModifiers; // For equipment
}

public class Inventory
{
    private readonly InventorySlot[] _slots;

    public event Action<int> OnSlotChanged;

    public Inventory(int size) => _slots = new InventorySlot[size];

    public bool TryAdd(ItemData item, int amount = 1)
    {
        // Try stacking first
        for (int i = 0; i < _slots.Length; i++)
        {
            if (_slots[i].Item == item && _slots[i].Amount < item.maxStack)
            {
                int canAdd = Mathf.Min(amount, item.maxStack - _slots[i].Amount);
                _slots[i].Amount += canAdd;
                amount -= canAdd;
                OnSlotChanged?.Invoke(i);
                if (amount == 0) return true;
            }
        }

        // Find empty slots
        for (int i = 0; i < _slots.Length && amount > 0; i++)
        {
            if (_slots[i].IsEmpty)
            {
                int canAdd = Mathf.Min(amount, item.maxStack);
                _slots[i] = new InventorySlot(item, canAdd);
                amount -= canAdd;
                OnSlotChanged?.Invoke(i);
            }
        }

        return amount == 0;
    }

    public bool TryRemove(ItemData item, int amount = 1)
    {
        int remaining = amount;
        for (int i = _slots.Length - 1; i >= 0 && remaining > 0; i--)
        {
            if (_slots[i].Item == item)
            {
                int canRemove = Mathf.Min(remaining, _slots[i].Amount);
                _slots[i].Amount -= canRemove;
                remaining -= canRemove;
                if (_slots[i].Amount == 0) _slots[i] = InventorySlot.Empty;
                OnSlotChanged?.Invoke(i);
            }
        }
        return remaining == 0;
    }
}

public struct InventorySlot
{
    public ItemData Item;
    public int Amount;
    public bool IsEmpty => Item == null || Amount <= 0;

    public InventorySlot(ItemData item, int amount) { Item = item; Amount = amount; }
    public static InventorySlot Empty => new(null, 0);
}
```

## 3. Quest System

```csharp
// ✅ Data-driven quest system
[CreateAssetMenu(menuName = "Quests/Quest")]
public class QuestData : ScriptableObject
{
    public string questName;
    [TextArea] public string description;
    public QuestObjective[] objectives;
    public ItemReward[] rewards;
    public int experienceReward;
    public QuestData[] prerequisites;
}

[System.Serializable]
public class QuestObjective
{
    public string description;
    public ObjectiveType type;
    public string targetId;
    public int requiredAmount;
}

public class QuestTracker
{
    private readonly Dictionary<QuestData, QuestProgress> _activeQuests = new();

    public void StartQuest(QuestData quest)
    {
        if (_activeQuests.ContainsKey(quest)) return;
        _activeQuests[quest] = new QuestProgress(quest);
    }

    public void UpdateObjective(string targetId, ObjectiveType type, int amount = 1)
    {
        foreach (var (quest, progress) in _activeQuests)
        {
            progress.UpdateObjective(targetId, type, amount);
            if (progress.IsComplete)
                CompleteQuest(quest);
        }
    }
}
```

## 4. Loot Table

```csharp
// ✅ Weighted random loot table
[CreateAssetMenu(menuName = "Data/Loot Table")]
public class LootTable : ScriptableObject
{
    [SerializeField] private LootEntry[] _entries;

    public List<ItemDrop> Roll(int rolls = 1)
    {
        var drops = new List<ItemDrop>();
        float totalWeight = _entries.Sum(e => e.weight);

        for (int r = 0; r < rolls; r++)
        {
            float roll = Random.Range(0f, totalWeight);
            float cumulative = 0f;

            foreach (var entry in _entries)
            {
                cumulative += entry.weight;
                if (roll <= cumulative)
                {
                    if (Random.value <= entry.dropChance)
                    {
                        int amount = Random.Range(entry.minAmount, entry.maxAmount + 1);
                        drops.Add(new ItemDrop(entry.item, amount));
                    }
                    break;
                }
            }
        }
        return drops;
    }
}

[System.Serializable]
public struct LootEntry
{
    public ItemData item;
    public float weight;
    [Range(0f, 1f)] public float dropChance;
    public int minAmount;
    public int maxAmount;
}
```

## 5. Dialogue System

```csharp
// ✅ Node-based dialogue with choices
[CreateAssetMenu(menuName = "Dialogue/Conversation")]
public class DialogueData : ScriptableObject
{
    public DialogueNode[] nodes;
}

[System.Serializable]
public class DialogueNode
{
    public string speakerName;
    public Sprite speakerPortrait;
    [TextArea(3, 5)] public string text;
    public DialogueChoice[] choices;
    public int nextNodeIndex = -1; // -1 = end dialogue
    public string triggerEvent;
}

[System.Serializable]
public class DialogueChoice
{
    public string choiceText;
    public int targetNodeIndex;
    public string requiredQuestId; // Only show if quest active
    public int requiredStatValue;  // Skill check
}
```

---

**Execution Protocol**
1. **ScriptableObject for ALL Data**: Items, quests, loot tables, dialogue, and skill trees MUST be ScriptableObject assets.
2. **Stat Modifiers with Source**: ALWAYS track the source of stat modifiers so equipment removal correctly reverses effects.
3. **Event-Driven Updates**: Inventory and quest changes MUST fire events for UI to react. Never poll.
4. **Weighted Loot Tables**: Use weighted random selection for loot drops. Never use flat `Random.Range(0, items.Length)`.
5. **Dialogue as Data**: Dialogue trees MUST be data-driven (ScriptableObject or JSON). Never hardcode dialogue in scripts.
