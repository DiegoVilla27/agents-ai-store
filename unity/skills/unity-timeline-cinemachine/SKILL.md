---
name: unity-timeline-cinemachine
description: Complete mastery of Unity Timeline and Cinemachine for cinematic sequences, virtual cameras, camera blending, dolly tracks, noise profiles, and dynamic camera systems.
author: Diego Villanueva
trigger: When implementing cinematic cutscenes, dynamic camera systems, virtual cameras, dolly tracks, screen shake, or Timeline-driven sequences.
---

# Timeline & Cinemachine

Timeline provides a director-driven sequencing system for cutscenes, cinematics, and scripted events. Cinemachine provides a suite of intelligent virtual cameras that handle blending, tracking, and composition automatically.

## 1. Cinemachine Virtual Cameras

```csharp
// ✅ Cinemachine replaces manual camera scripting
// Install: com.unity.cinemachine (v3+)

// Setup hierarchy:
// Main Camera (CinemachineBrain)  → Manages all virtual cameras
//   No scripts needed on Main Camera!
//
// VCam_Follow (CinemachineCamera)  → Follow player, Priority 10
// VCam_Aim (CinemachineCamera)     → Aim mode, Priority 0
// VCam_Cutscene (CinemachineCamera) → Cutscene shot, Priority 0

// The CinemachineBrain on Main Camera automatically activates
// the virtual camera with the highest Priority
```

```csharp
// ✅ Switch cameras by changing priority
using Unity.Cinemachine;

public class CameraManager : MonoBehaviour
{
    [SerializeField] private CinemachineCamera _followCam;
    [SerializeField] private CinemachineCamera _aimCam;
    [SerializeField] private CinemachineCamera _dialogueCam;

    public void EnterAimMode()
    {
        _aimCam.Priority = 20;     // Highest → Brain switches to this
        _followCam.Priority = 10;
    }

    public void ExitAimMode()
    {
        _followCam.Priority = 20;
        _aimCam.Priority = 10;
    }

    public void StartDialogue(Transform speaker)
    {
        _dialogueCam.Follow = speaker;
        _dialogueCam.LookAt = speaker;
        _dialogueCam.Priority = 30;
    }
}
```

## 2. Camera Follow & Framing

```text
Body Components (How the camera follows):
├── Cinemachine Follow         → Third-person follow with damping
├── Cinemachine Position Composer → Frame target with screen offsets
├── Cinemachine Orbital Follow → Orbit around target (player-controlled)
├── Cinemachine Tracked Dolly  → Follow a spline path
└── Cinemachine Hard Lock      → Lock position to target exactly

Aim Components (Where the camera looks):
├── Cinemachine Rotation Composer → Look at target with damping/deadzone
├── Cinemachine Hard Look At      → Snap look at target
├── Cinemachine Pan Tilt          → Manual pan/tilt control
└── Cinemachine Same As Follow    → Look in movement direction
```

## 3. Screen Shake (Cinemachine Impulse)

```csharp
// ✅ Camera shake via Cinemachine Impulse
using Unity.Cinemachine;

public class ScreenShake : MonoBehaviour
{
    [SerializeField] private CinemachineImpulseSource _impulseSource;

    // Call this on explosions, big hits, landing
    public void Shake(float force = 1f)
    {
        _impulseSource.GenerateImpulse(force);
    }

    // Custom directional shake
    public void DirectionalShake(Vector3 direction, float force)
    {
        _impulseSource.GenerateImpulse(direction.normalized * force);
    }
}

// On the virtual camera, add CinemachineImpulseListener
// to receive shake signals from any ImpulseSource in the scene
```

## 4. Dolly Tracks & Spline Paths

```text
Setup:
1. Create GameObject → CinemachineSplineDolly
2. Draw spline path in Scene view (add waypoints)
3. Create CinemachineCamera → Body: Cinemachine Tracked Dolly
4. Assign spline to the Tracked Dolly component
5. Control position on spline via script or Timeline
```

```csharp
// ✅ Animate camera along dolly track
public class DollyCameraController : MonoBehaviour
{
    [SerializeField] private CinemachineSplineDolly _dolly;

    public void SetPathPosition(float t)
    {
        _dolly.CameraPosition = t; // 0 = start, 1 = end of spline
    }

    public async Awaitable AnimateAlongPath(float duration)
    {
        float elapsed = 0f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            _dolly.CameraPosition = elapsed / duration;
            await Awaitable.NextFrameAsync();
        }
    }
}
```

## 5. Timeline (Cinematic Sequences)

```text
Timeline Tracks:
├── Activation Track    → Enable/disable GameObjects at specific times
├── Animation Track     → Play animation clips on Animators
├── Audio Track         → Play audio clips with fading
├── Cinemachine Track   → Switch between virtual cameras
├── Signal Track        → Fire events at specific frames
├── Control Track       → Control particle systems, sub-timelines
└── Custom Playable     → Your own scripted behavior
```

```csharp
// ✅ Trigger Timeline playback from script
using UnityEngine.Playables;

public class CutsceneTrigger : MonoBehaviour
{
    [SerializeField] private PlayableDirector _director;

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            _director.Play();
            DisablePlayerInput();
        }
    }

    private void OnEnable()
    {
        _director.stopped += OnCutsceneEnd;
    }

    private void OnDisable()
    {
        _director.stopped -= OnCutsceneEnd;
    }

    private void OnCutsceneEnd(PlayableDirector director)
    {
        EnablePlayerInput();
    }
}
```

## 6. Timeline Signals (Event System)

```csharp
// ✅ Fire gameplay events from Timeline without code coupling
// 1. Create SignalAsset: "DialogueStart.signal"
// 2. Add Signal Track to Timeline
// 3. Place Signal Emitter at desired frame
// 4. Add SignalReceiver component to target GameObject

public class CutsceneSignalHandler : MonoBehaviour, INotificationReceiver
{
    public void OnNotify(Playable origin, INotification notification, object context)
    {
        // React to any signal
        Debug.Log($"Signal received: {notification}");
    }

    // Or use SignalReceiver component with UnityEvents in Inspector
    // for designer-friendly event wiring
}
```

## 7. Cinemachine Confiner (Camera Bounds)

```csharp
// ✅ Confine camera to level boundaries
// 2D: Add CinemachineConfiner2D to virtual camera
//     Create PolygonCollider2D on a "CameraBounds" GameObject
//     Assign as Bounding Shape

// 3D: Add CinemachineConfiner to virtual camera
//     Create BoxCollider (Is Trigger) as bounding volume
//     Assign as Bounding Volume
```

---

**Execution Protocol**
1. **Never Script Camera Directly**: ALL camera behavior goes through Cinemachine virtual cameras. Never write `camera.transform.position = ...`.
2. **Priority-Based Switching**: Switch cameras by changing `Priority`, not by enabling/disabling GameObjects.
3. **Impulse for Shake**: NEVER use coroutines to shake the camera. Use `CinemachineImpulseSource.GenerateImpulse()`.
4. **Timeline for Cutscenes**: Use Timeline for any non-interactive sequence. Use Signals to trigger gameplay events at specific frames.
5. **Blend Settings**: Configure blend times in CinemachineBrain or via custom blend assets for smooth camera transitions.
