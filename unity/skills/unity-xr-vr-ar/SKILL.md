---
name: unity-xr-vr-ar
description: XR development mastery for Unity including XR Interaction Toolkit, OpenXR, hand tracking, AR Foundation, plane detection, passthrough, and locomotion systems.
author: Diego Villanueva
trigger: When developing VR or AR applications, implementing XR interactions, hand tracking, AR plane detection, or configuring OpenXR for headsets.
---

# XR (VR & AR) Development

Unity's XR ecosystem provides cross-platform VR/AR development via OpenXR and XR Interaction Toolkit. AR Foundation unifies ARKit (iOS) and ARCore (Android) behind a single API.

## 1. XR Architecture

```text
XR Stack:
├── XR Interaction Toolkit (XRIT) → Interaction layer (grab, poke, teleport)
├── XR Hands                       → Hand tracking
├── OpenXR Plugin                  → Cross-headset VR (Meta Quest, SteamVR, PSVR2)
├── AR Foundation                  → Cross-platform AR (ARKit + ARCore)
└── XR Core Utilities              → Shared XR utilities

Supported Platforms:
├── VR: Meta Quest 2/3/Pro, SteamVR (Valve Index, HTC Vive), PSVR2
├── AR: iOS (ARKit), Android (ARCore)
└── MR: Meta Quest 3 (passthrough), Apple Vision Pro
```

## 2. XR Rig Setup

```text
✅ XR Origin (Camera Floor Offset Object):
├── Camera Offset
│   ├── Main Camera (TrackedPoseDriver)
│   ├── Left Controller (XR Controller, XR Ray Interactor)
│   │   └── Line Visual (for teleport/UI ray)
│   └── Right Controller (XR Controller, XR Direct Interactor)
│       └── Attach Transform (grab point)
├── Locomotion System
│   ├── Teleportation Provider
│   ├── Continuous Move Provider
│   ├── Continuous Turn Provider
│   └── Snap Turn Provider
└── Input Action Manager (XR Default Input Actions)
```

## 3. Interactions

```csharp
// ✅ Grabbable object setup
// On the grabbable GameObject:
// 1. Rigidbody (Use Gravity, not Kinematic)
// 2. Collider (BoxCollider, etc.)
// 3. XR Grab Interactable
//    - Movement Type: Velocity Tracking (physics-based)
//    - Throw On Detach: ✅
//    - Attach Transform: child transform at grab point

// ✅ Custom interaction events
using UnityEngine.XR.Interaction.Toolkit;

public class GrabbableWeapon : MonoBehaviour
{
    private XRGrabInteractable _interactable;

    private void Awake()
    {
        _interactable = GetComponent<XRGrabInteractable>();
        _interactable.selectEntered.AddListener(OnGrab);
        _interactable.selectExited.AddListener(OnRelease);
        _interactable.activated.AddListener(OnTriggerPull);
    }

    private void OnGrab(SelectEnterEventArgs args)
    {
        // Player picked up the weapon
        _audioSource.PlayOneShot(_grabSound);
    }

    private void OnRelease(SelectExitEventArgs args)
    {
        // Player dropped the weapon
    }

    private void OnTriggerPull(ActivateEventArgs args)
    {
        // Player pulled trigger while holding weapon
        Fire();
    }
}
```

## 4. Hand Tracking

```csharp
// ✅ Hand tracking with XR Hands package
using UnityEngine.XR.Hands;

public class HandGestureDetector : MonoBehaviour
{
    [SerializeField] private XRHandTrackingEvents _handEvents;

    private void OnEnable()
    {
        _handEvents.jointsUpdated.AddListener(OnJointsUpdated);
    }

    private void OnJointsUpdated(XRHandJointsUpdatedEventArgs args)
    {
        // Check pinch gesture
        if (args.hand.GetJoint(XRHandJointID.ThumbTip).TryGetPose(out var thumbPose) &&
            args.hand.GetJoint(XRHandJointID.IndexTip).TryGetPose(out var indexPose))
        {
            float pinchDistance = Vector3.Distance(thumbPose.position, indexPose.position);
            bool isPinching = pinchDistance < 0.02f; // 2cm threshold

            if (isPinching) OnPinchDetected();
        }
    }
}
```

## 5. AR Foundation (Mobile AR)

```csharp
// ✅ AR plane detection and object placement
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

public class ARPlacement : MonoBehaviour
{
    [SerializeField] private ARRaycastManager _raycastManager;
    [SerializeField] private ARPlaneManager _planeManager;
    [SerializeField] private GameObject _placementPrefab;

    private static readonly List<ARRaycastHit> _hits = new();

    private void Update()
    {
        if (Input.touchCount == 0) return;
        var touch = Input.GetTouch(0);
        if (touch.phase != TouchPhase.Began) return;

        if (_raycastManager.Raycast(touch.position, _hits, TrackableType.PlaneWithinPolygon))
        {
            var hitPose = _hits[0].pose;
            Instantiate(_placementPrefab, hitPose.position, hitPose.rotation);

            // Disable plane visualization after placement
            _planeManager.enabled = false;
            foreach (var plane in _planeManager.trackables)
                plane.gameObject.SetActive(false);
        }
    }
}
```

## 6. VR Comfort & Best Practices

```text
✅ VR Comfort Guidelines:
├── Target 72-90 FPS minimum (Quest: 72/90/120hz)
├── NEVER move the camera without player input (motion sickness)
├── Use teleportation as default locomotion (comfortable)
├── Continuous movement: add vignette during motion
├── Snap turn (45°) is more comfortable than smooth turn
├── Keep UI at 1-2m distance from player (comfortable reading)
├── Avoid small text (minimum 24pt at 1m)
├── Fixed reference frame (cockpit, visible floor) reduces nausea
└── NEVER take camera control away from the player
```

---

**Execution Protocol**
1. **OpenXR for Cross-Platform**: ALWAYS use OpenXR plugin instead of platform-specific SDKs (Oculus SDK, SteamVR SDK).
2. **XR Interaction Toolkit**: Use XRIT for all interactions (grab, poke, teleport). Don't write custom ray/grab systems.
3. **Performance is Critical**: VR MUST maintain 72+ FPS on Quest, 90+ on PC VR. Frame drops cause motion sickness.
4. **Comfort First**: Default to teleportation locomotion. Offer smooth locomotion as an option, never as the only choice.
5. **Test on Device**: VR/AR MUST be tested on the actual headset. Editor simulation is insufficient for comfort validation.
