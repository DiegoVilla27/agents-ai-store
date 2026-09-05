---
name: unity-ui-toolkit
description: Complete UI mastery for Unity including UI Toolkit (USS, UXML, data binding, custom controls), uGUI Canvas system, responsive layouts, and runtime UI architecture.
author: Diego Villanueva
trigger: When building game UI, menus, HUDs, inventories, settings screens, or implementing responsive UI layouts using UI Toolkit or uGUI.
---

# UI Toolkit & uGUI

Unity has two UI systems: **UI Toolkit** (modern, CSS-like, recommended for new projects) and **uGUI** (legacy Canvas-based, still required for world-space UI). Use UI Toolkit for screen-space UI and uGUI for world-space elements.

## 1. UI Toolkit Architecture

```text
UI Toolkit Stack:
├── UXML (.uxml)  → Structure (like HTML)
├── USS (.uss)     → Styling (like CSS)
├── C# Script      → Logic & data binding
└── UI Document    → MonoBehaviour bridge to scene

File Organization:
Assets/_Project/UI/
├── Styles/
│   ├── Variables.uss       # Shared CSS custom properties
│   ├── Common.uss          # Base element styles
│   └── Theme.tss           # Theme Style Sheet
├── Templates/
│   ├── MainMenu.uxml
│   ├── HUD.uxml
│   ├── InventorySlot.uxml  # Reusable component template
│   └── SettingsPanel.uxml
└── Scripts/
    ├── MainMenuUI.cs
    ├── HUDUI.cs
    └── InventoryUI.cs
```

## 2. UXML Templates

```xml
<!-- ✅ MainMenu.uxml -->
<ui:UXML xmlns:ui="UnityEngine.UIElements">
    <ui:Style src="project://database/Assets/_Project/UI/Styles/Common.uss" />
    
    <ui:VisualElement name="root" class="menu-root">
        <ui:Label text="Game Title" class="title" />
        
        <ui:VisualElement class="button-container">
            <ui:Button name="btn-play" text="Play" class="menu-button primary" />
            <ui:Button name="btn-settings" text="Settings" class="menu-button" />
            <ui:Button name="btn-quit" text="Quit" class="menu-button danger" />
        </ui:VisualElement>
        
        <ui:Label name="version-label" class="version" />
    </ui:VisualElement>
</ui:UXML>
```

## 3. USS Styling

```css
/* ✅ Common.uss */
:root {
    --color-primary: #4A90D9;
    --color-danger: #D94A4A;
    --color-bg: rgba(0, 0, 0, 0.85);
    --font-size-title: 48px;
    --font-size-button: 24px;
    --border-radius: 8px;
    --transition-duration: 200ms;
}

.menu-root {
    flex-grow: 1;
    justify-content: center;
    align-items: center;
    background-color: var(--color-bg);
}

.title {
    font-size: var(--font-size-title);
    color: white;
    margin-bottom: 40px;
    -unity-font-style: bold;
}

.menu-button {
    width: 300px;
    height: 60px;
    font-size: var(--font-size-button);
    margin: 8px;
    border-radius: var(--border-radius);
    background-color: #333;
    color: white;
    border-width: 2px;
    border-color: #555;
    transition: background-color var(--transition-duration),
                scale var(--transition-duration);
}

.menu-button:hover {
    background-color: #444;
    scale: 1.05;
}

.menu-button:active {
    scale: 0.95;
}

.menu-button.primary {
    background-color: var(--color-primary);
    border-color: var(--color-primary);
}

.menu-button.danger:hover {
    background-color: var(--color-danger);
}
```

## 4. C# Controller

```csharp
// ✅ UI Toolkit controller
[RequireComponent(typeof(UIDocument))]
public class MainMenuUI : MonoBehaviour
{
    private UIDocument _doc;
    private Button _playButton;
    private Button _settingsButton;
    private Button _quitButton;

    private void Awake()
    {
        _doc = GetComponent<UIDocument>();
        var root = _doc.rootVisualElement;

        _playButton = root.Q<Button>("btn-play");
        _settingsButton = root.Q<Button>("btn-settings");
        _quitButton = root.Q<Button>("btn-quit");

        root.Q<Label>("version-label").text = $"v{Application.version}";
    }

    private void OnEnable()
    {
        _playButton.clicked += OnPlayClicked;
        _settingsButton.clicked += OnSettingsClicked;
        _quitButton.clicked += OnQuitClicked;
    }

    private void OnDisable()
    {
        _playButton.clicked -= OnPlayClicked;
        _settingsButton.clicked -= OnSettingsClicked;
        _quitButton.clicked -= OnQuitClicked;
    }

    private void OnPlayClicked() => SceneManager.LoadScene("Gameplay");
    private void OnSettingsClicked() => _settingsPanel.Show();
    private void OnQuitClicked() => Application.Quit();
}
```

## 5. Data Binding (UI Toolkit)

```csharp
// ✅ Runtime data binding (Unity 6+)
using UnityEngine.UIElements;

[UxmlElement]
public partial class HealthBar : VisualElement
{
    private readonly VisualElement _fill;
    private readonly Label _label;

    public HealthBar()
    {
        _fill = new VisualElement { name = "fill" };
        _fill.style.backgroundColor = Color.green;
        _fill.style.height = new Length(100, LengthUnit.Percent);
        Add(_fill);

        _label = new Label();
        Add(_label);
    }

    public void SetHealth(int current, int max)
    {
        float pct = (float)current / max;
        _fill.style.width = new Length(pct * 100, LengthUnit.Percent);
        _fill.style.backgroundColor = Color.Lerp(Color.red, Color.green, pct);
        _label.text = $"{current}/{max}";
    }
}
```

## 6. uGUI (Canvas System) — When Still Needed

```csharp
// ✅ uGUI still required for:
// - World-space UI (health bars above enemies, floating damage numbers)
// - TextMeshPro integration (legacy projects)
// - Complex layout groups with dynamic content

// ✅ World-space health bar
public class WorldSpaceHealthBar : MonoBehaviour
{
    [SerializeField] private Canvas _canvas;
    [SerializeField] private Image _fillImage;
    private Camera _mainCamera;

    private void Awake()
    {
        _mainCamera = Camera.main;
        _canvas.worldCamera = _mainCamera;
    }

    private void LateUpdate()
    {
        // Billboard: face camera
        transform.forward = _mainCamera.transform.forward;
    }

    public void SetHealth(float normalized)
    {
        _fillImage.fillAmount = normalized;
        _fillImage.color = Color.Lerp(Color.red, Color.green, normalized);
    }
}
```

## 7. Responsive UI

```css
/* ✅ USS media-query-like responsive design using class toggles */
.panel-wide {
    flex-direction: row;
    width: 80%;
}

.panel-narrow {
    flex-direction: column;
    width: 95%;
}
```

```csharp
// ✅ Responsive layout based on screen size
private void UpdateLayout()
{
    bool isWide = Screen.width > 1200;
    _panel.EnableInClassList("panel-wide", isWide);
    _panel.EnableInClassList("panel-narrow", !isWide);
}
```

---

**Execution Protocol**
1. **UI Toolkit for Screen-Space**: ALL new screen-space UI (menus, HUD, settings) MUST use UI Toolkit.
2. **uGUI for World-Space**: World-space UI (health bars, damage numbers) still requires uGUI Canvas.
3. **USS Variables**: Use CSS custom properties (`--var-name`) for theming. Never hardcode colors or sizes.
4. **Q<T> for Queries**: Use `rootVisualElement.Q<Button>("name")` to query elements. Cache references in `Awake`.
5. **Event Symmetry**: Subscribe to UI events in `OnEnable`, unsubscribe in `OnDisable`.
