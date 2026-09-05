---
name: unity-localization-i18n
description: Unity Localization package mastery including string tables, asset tables, RTL support, plural rules, font fallbacks, and locale-specific formatting.
author: Diego Villanueva
trigger: When implementing multi-language support, localization, string tables, RTL text, or locale-specific content in Unity.
---

# Localization & Internationalization

The Unity Localization package (com.unity.localization) provides a complete i18n solution with string tables, asset tables, smart strings, and locale management.

## 1. Setup

```text
✅ Install: com.unity.localization (Package Manager)

Configuration:
1. Edit → Project Settings → Localization
2. Create Locale assets (English, Spanish, Japanese, Arabic, etc.)
3. Set default locale
4. Create String Table Collection ("GameText")
5. Create Asset Table Collection ("GameAssets") for locale-specific sprites/audio
```

## 2. String Tables

```csharp
// ✅ Localized string reference
using UnityEngine.Localization;
using UnityEngine.Localization.Components;

public class LocalizedUI : MonoBehaviour
{
    // Drag localized string reference in Inspector
    [SerializeField] private LocalizedString _welcomeMessage;
    [SerializeField] private TMP_Text _label;

    private void OnEnable()
    {
        _welcomeMessage.StringChanged += OnStringChanged;
    }

    private void OnDisable()
    {
        _welcomeMessage.StringChanged -= OnStringChanged;
    }

    private void OnStringChanged(string value)
    {
        _label.text = value;
    }
}

// ✅ Smart Strings with variables
// String Table Entry: "welcome_player"
// English: "Welcome, {player-name}! You have {coins} coins."
// Spanish: "¡Bienvenido, {player-name}! Tienes {coins} monedas."

public void UpdateWelcome(string playerName, int coins)
{
    _welcomeMessage.Arguments = new object[] {
        new Dictionary<string, object> {
            { "player-name", playerName },
            { "coins", coins }
        }
    };
}
```

## 3. Locale Switching

```csharp
// ✅ Change language at runtime
using UnityEngine.Localization.Settings;

public class LanguageSelector : MonoBehaviour
{
    public async void SetLanguage(string localeCode)
    {
        var locale = LocalizationSettings.AvailableLocales.Locales
            .Find(l => l.Identifier.Code == localeCode);

        if (locale != null)
        {
            LocalizationSettings.SelectedLocale = locale;
            // All LocalizedString references update automatically!
        }
    }

    public List<string> GetAvailableLanguages()
    {
        return LocalizationSettings.AvailableLocales.Locales
            .Select(l => l.Identifier.Code)
            .ToList();
    }
}
```

## 4. Asset Tables (Locale-Specific Assets)

```text
✅ Asset Tables for locale-specific content:
- Different flag icons per locale
- Different audio files (voiceover per language)
- Different textures (culturally appropriate imagery)
- Different fonts (CJK requires different font assets)

Setup:
1. Create Asset Table Collection ("LocalizedAssets")
2. Add entries with locale-specific asset references
3. Use LocalizedAsset<T> in scripts
```

## 5. RTL (Right-to-Left) Support

```text
✅ RTL Languages (Arabic, Hebrew, Farsi):
1. Enable RTL in TextMeshPro (Right To Left: ✅)
2. Mirror UI layout (use LayoutGroup with ReverseArrangement)
3. Use EdgeInsetsDirectional instead of hardcoded left/right
4. Test with actual RTL text (not just placeholder)
5. Consider bidirectional text (mixed LTR + RTL)
```

## 6. Plural Rules

```text
✅ Smart Strings handle pluralization:
English: "{coins:plural:one{1 coin}other{# coins}}"
Russian: "{coins:plural:one{# монета}few{# монеты}many{# монет}other{# монет}}"

// Unicode CLDR plural categories:
// zero, one, two, few, many, other
// Each language has different rules!
```

---

**Execution Protocol**
1. **No Hardcoded Strings**: EVERY user-visible string MUST go through the Localization system. Zero hardcoded text.
2. **String Tables from Day 1**: Set up localization at project start, not as an afterthought.
3. **Test with Long Languages**: German and Finnish produce much longer strings. Test UI with these locales to catch overflow.
4. **Font Fallbacks**: Configure TMP font fallback chains for CJK characters and special symbols.
5. **RTL Testing**: If supporting Arabic/Hebrew, test the ENTIRE UI flow in RTL mode, not just individual labels.
