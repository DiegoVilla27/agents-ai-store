---
name: unity-input-system
description: Complete mastery of Unity's New Input System including Input Actions, bindings, PlayerInput component, control schemes, composite inputs, rebinding UI, and touch/gamepad support.
author: Diego Villanueva
trigger: When implementing player input, control schemes, input remapping, gamepad/keyboard/touch support, or input buffering systems.
---

# Unity New Input System

The legacy `Input.GetAxis()` / `Input.GetButton()` API is device-specific and non-rebindable. The New Input System provides device-agnostic actions, runtime rebinding, multiplayer input, and composite inputs out of the box.

## 1. Input Actions Asset (The Single Source of Truth)

```text
✅ Create an InputActions asset (Player.inputactions):
├── Action Map: "Player"
│   ├── Action: "Move" (Value, Vector2)
│   │   ├── Binding: WASD (2D Composite)
│   │   ├── Binding: Left Stick [Gamepad]
│   │   └── Binding: Touch Drag [Touchscreen]
│   ├── Action: "Jump" (Button)
│   │   ├── Binding: Space [Keyboard]
│   │   └── Binding: Button South [Gamepad]
│   ├── Action: "Attack" (Button)
│   │   ├── Binding: Left Mouse Button
│   │   └── Binding: Right Trigger [Gamepad]
│   └── Action: "Look" (Value, Vector2)
│       ├── Binding: Mouse Delta
│       └── Binding: Right Stick [Gamepad]
└── Action Map: "UI"
    ├── Action: "Navigate"
    ├── Action: "Submit"
    └── Action: "Cancel"
```

## 2. Reading Input (C# Generated Class)

```csharp
// ✅ ALWAYS: Generate C# class from .inputactions asset
// Enable "Generate C# Class" in the asset inspector
public class PlayerInputHandler : MonoBehaviour
{
    private PlayerInputActions _inputActions;

    private void Awake()
    {
        _inputActions = new PlayerInputActions();
    }

    private void OnEnable()
    {
        _inputActions.Player.Enable();

        // Subscribe to button events
        _inputActions.Player.Jump.performed += OnJump;
        _inputActions.Player.Attack.performed += OnAttack;
    }

    private void OnDisable()
    {
        _inputActions.Player.Jump.performed -= OnJump;
        _inputActions.Player.Attack.performed -= OnAttack;

        _inputActions.Player.Disable();
    }

    private void Update()
    {
        // Read continuous value actions every frame
        Vector2 moveInput = _inputActions.Player.Move.ReadValue<Vector2>();
        Vector2 lookInput = _inputActions.Player.Look.ReadValue<Vector2>();

        _playerController.SetMoveInput(moveInput);
        _cameraController.SetLookInput(lookInput);
    }

    private void OnJump(InputAction.CallbackContext ctx) => _playerController.Jump();
    private void OnAttack(InputAction.CallbackContext ctx) => _combatController.Attack();
}
```

```csharp
// ❌ NEVER: Legacy Input API (not rebindable, device-specific)
float h = Input.GetAxis("Horizontal");  // Hardcoded to keyboard/joystick
if (Input.GetKeyDown(KeyCode.Space)) { } // Hardcoded to keyboard
```

## 3. Input Buffering (Responsive Controls)

```csharp
// ✅ Input buffer: remembers inputs for a short window
public class InputBuffer
{
    private float _bufferDuration;
    private float _bufferTimer;
    private bool _bufferedInput;

    public InputBuffer(float duration) => _bufferDuration = duration;

    public void BufferInput()
    {
        _bufferedInput = true;
        _bufferTimer = _bufferDuration;
    }

    public bool ConsumeBuffer()
    {
        if (!_bufferedInput) return false;
        _bufferedInput = false;
        return true;
    }

    public void Update(float deltaTime)
    {
        if (!_bufferedInput) return;
        _bufferTimer -= deltaTime;
        if (_bufferTimer <= 0f) _bufferedInput = false;
    }
}

// Usage in PlayerController:
private InputBuffer _jumpBuffer = new(0.15f);

private void OnJumpInput() => _jumpBuffer.BufferInput();

private void FixedUpdate()
{
    _jumpBuffer.Update(Time.fixedDeltaTime);
    if (_jumpBuffer.ConsumeBuffer() && IsGrounded())
        PerformJump();
}
```

## 4. Control Schemes (Device Groups)

```text
Control Scheme: "Keyboard&Mouse"
  Required Devices: Keyboard, Mouse

Control Scheme: "Gamepad"
  Required Devices: Gamepad

Control Scheme: "Touch"
  Required Devices: Touchscreen
```

```csharp
// ✅ Auto-switch control scheme and update UI prompts
public class ControlSchemeDetector : MonoBehaviour
{
    [SerializeField] private PlayerInput _playerInput;

    public event Action<string> OnSchemeChanged;

    private void OnEnable()
    {
        _playerInput.onControlsChanged += OnControlsChanged;
    }

    private void OnControlsChanged(PlayerInput input)
    {
        string scheme = input.currentControlScheme;
        OnSchemeChanged?.Invoke(scheme); // "Keyboard&Mouse" or "Gamepad"
        UpdateButtonPrompts(scheme);
    }

    private void UpdateButtonPrompts(string scheme)
    {
        // Swap "Press SPACE" → "Press A" when gamepad is detected
        _jumpPrompt.sprite = scheme == "Gamepad" ? _gamepadAIcon : _keyboardSpaceIcon;
    }
}
```

## 5. Runtime Rebinding

```csharp
// ✅ Allow players to rebind controls at runtime
public class RebindUI : MonoBehaviour
{
    [SerializeField] private InputActionReference _actionToRebind;
    [SerializeField] private TMP_Text _bindingText;
    [SerializeField] private GameObject _rebindOverlay;

    private InputActionRebindingExtensions.RebindingOperation _rebindOp;

    public void StartRebind()
    {
        _actionToRebind.action.Disable();
        _rebindOverlay.SetActive(true);

        _rebindOp = _actionToRebind.action.PerformInteractiveRebinding()
            .WithControlsExcluding("Mouse")  // Exclude mouse movement
            .WithCancelingThrough("<Keyboard>/escape")
            .OnMatchWaitForAnother(0.1f)
            .OnComplete(op => CompleteRebind())
            .OnCancel(op => CancelRebind())
            .Start();
    }

    private void CompleteRebind()
    {
        _rebindOp?.Dispose();
        _rebindOverlay.SetActive(false);
        _actionToRebind.action.Enable();

        // Update UI to show new binding
        _bindingText.text = InputControlPath.ToHumanReadableString(
            _actionToRebind.action.bindings[0].effectivePath,
            InputControlPath.HumanReadableStringOptions.OmitDevice);

        // Save bindings to PlayerPrefs
        SaveBindings();
    }

    private void SaveBindings()
    {
        string rebinds = _actionToRebind.action.actionMap.asset.SaveBindingOverridesAsJson();
        PlayerPrefs.SetString("InputBindings", rebinds);
    }

    public void LoadBindings()
    {
        string rebinds = PlayerPrefs.GetString("InputBindings", string.Empty);
        if (!string.IsNullOrEmpty(rebinds))
            _actionToRebind.action.actionMap.asset.LoadBindingOverridesFromJson(rebinds);
    }
}
```

## 6. Multiplayer Input (Split Screen)

```csharp
// ✅ PlayerInputManager handles local multiplayer
// Add PlayerInputManager component to a manager GameObject:
// - Join Behavior: Join Players When Button Is Pressed
// - Player Prefab: reference to player prefab with PlayerInput component
// - Max Player Count: 4
// - Split Screen: Enable (divides camera viewports automatically)
```

---

**Execution Protocol**
1. **InputActions Asset is Mandatory**: Never use `Input.GetKey()` or `Input.GetAxis()`. All input must flow through an `.inputactions` asset.
2. **Generate C# Class**: Always check "Generate C# Class" on the InputActions asset for type-safe access.
3. **Enable/Disable Symmetry**: Enable actions in `OnEnable`, disable in `OnDisable`. Forgetting this causes input leaks across scenes.
4. **Button Callbacks for One-Shot Actions**: Use `performed` callback for buttons (Jump, Attack). Use `ReadValue<>()` in `Update` for continuous values (Move, Look).
5. **Buffer Inputs**: Always buffer jump, attack, and dash inputs (0.1–0.2s) to make controls feel responsive.
