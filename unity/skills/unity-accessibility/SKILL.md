---
name: unity-accessibility
description: Game accessibility standards for Unity including colorblind modes, configurable subtitles, input remapping, screen readers, font scaling, and difficulty options.
author: Diego Villanueva
trigger: When implementing accessibility features, colorblind support, subtitle systems, input remapping, or making games playable for people with disabilities.
---

# Game Accessibility

Accessibility is not optional — it expands your audience by 15-20% and is increasingly required by platform certification (Xbox, PlayStation). Implement these features from the start, not as a post-launch patch.

## 1. Visual Accessibility

```csharp
// ✅ Colorblind mode via post-processing
[CreateAssetMenu(menuName = "Accessibility/Colorblind Profile")]
public class ColorblindProfile : ScriptableObject
{
    public string profileName;
    public Matrix4x4 colorMatrix; // Color transformation matrix
}

// Deuteranopia (red-green, most common ~8% of men)
// Protanopia (red-green)
// Tritanopia (blue-yellow, rare)

public class ColorblindFilter : MonoBehaviour
{
    [SerializeField] private Material _colorblindMaterial;
    [SerializeField] private ColorblindProfile[] _profiles;

    public void SetProfile(int index)
    {
        if (index < 0)
        {
            // Normal vision
            _colorblindMaterial.SetInt("_Enabled", 0);
        }
        else
        {
            _colorblindMaterial.SetInt("_Enabled", 1);
            _colorblindMaterial.SetMatrix("_ColorMatrix", _profiles[index].colorMatrix);
        }
    }
}

// ✅ Never rely on color alone
// ❌ "Red enemies are dangerous, green are friendly"
// ✅ "Enemies have skull icon + red, friendlies have shield icon + green"
// Use shape, icon, pattern, AND color together
```

## 2. Subtitle System

```csharp
// ✅ Configurable subtitle system
[System.Serializable]
public class SubtitleSettings
{
    public bool enabled = true;
    public float fontSize = 24f;
    public Color textColor = Color.white;
    public Color backgroundColor = new(0, 0, 0, 0.7f);
    public bool showSpeakerName = true;
    public bool showSoundEffects = true; // [EXPLOSION], [FOOTSTEPS]
    public SubtitlePosition position = SubtitlePosition.Bottom;
}

public class SubtitleManager : MonoBehaviour
{
    [SerializeField] private SubtitleSettings _settings;
    [SerializeField] private TMP_Text _subtitleLabel;
    [SerializeField] private Image _background;

    public void ShowSubtitle(string speaker, string text, float duration)
    {
        if (!_settings.enabled) return;

        _subtitleLabel.fontSize = _settings.fontSize;
        _subtitleLabel.color = _settings.textColor;
        _background.color = _settings.backgroundColor;

        string display = _settings.showSpeakerName
            ? $"<b>{speaker}:</b> {text}"
            : text;

        _subtitleLabel.text = display;
        CancelInvoke(nameof(HideSubtitle));
        Invoke(nameof(HideSubtitle), duration);
    }

    public void ShowSoundEffect(string description)
    {
        if (!_settings.showSoundEffects) return;
        ShowSubtitle("", $"[{description.ToUpper()}]", 2f);
    }
}
```

## 3. Input Accessibility

```text
✅ Input Accessibility Checklist:
├── Full input remapping (New Input System supports this natively)
├── Toggle vs Hold option for sprint, aim, crouch
├── Adjustable stick dead zones
├── One-handed control schemes
├── Adjustable camera sensitivity (separate X/Y)
├── Auto-aim / aim assist (configurable strength)
├── Button hold time adjustment (for QTEs)
└── Disable button mashing (replace with hold)
```

## 4. Difficulty & Game Feel

```text
✅ Granular Difficulty Options (not just Easy/Medium/Hard):
├── Enemy damage multiplier (50% → 200%)
├── Player damage multiplier (50% → 200%)
├── Enemy health multiplier
├── Aim assist strength (0% → 100%)
├── Invincibility mode (story mode)
├── Skip combat option
├── Puzzle hints (off / subtle / explicit / skip)
├── Timer adjustments (more time or disable timers)
├── QTE difficulty (more time, fewer buttons, auto-complete)
└── Navigation assistance (waypoints, compass, minimap)
```

## 5. Screen Reader & Text-to-Speech

```csharp
// ✅ Announce UI elements for screen readers
public class AccessibleUIElement : MonoBehaviour
{
    [SerializeField] private string _accessibleLabel;
    [SerializeField] private string _accessibleHint;

    public void OnFocused()
    {
        // Platform-specific TTS
        #if UNITY_IOS
        // iOS VoiceOver integration
        #elif UNITY_ANDROID
        // Android TalkBack integration
        #else
        // Custom TTS or UI audio description
        AccessibilityManager.Speak($"{_accessibleLabel}. {_accessibleHint}");
        #endif
    }
}
```

## 6. Motion Sensitivity

```text
✅ Motion Sensitivity Options:
├── Camera shake intensity slider (0% → 100%, default 100%)
├── Screen flash reduction (reduce or disable flashing effects)
├── Motion blur toggle (off by default for accessibility)
├── Head bobbing intensity slider
├── Reduced camera movement option
└── Photosensitivity mode (reduces all rapid visual changes)
```

---

**Execution Protocol**
1. **Never Color Alone**: ALWAYS use shape + icon + color for critical information (health, status, team identity).
2. **Subtitles by Default**: Subtitles MUST be ON by default with customizable size, color, and background.
3. **Remappable Controls**: ALL controls MUST be remappable. Use New Input System's rebinding feature.
4. **Granular Difficulty**: Provide individual sliders, not just preset difficulty levels.
5. **Test with Players**: Invite players with disabilities to playtest during development, not just before launch.
