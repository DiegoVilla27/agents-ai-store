---
name: unity-mobile-optimization
description: Mobile-specific optimization for Unity including draw call budgets, texture atlasing, shader variant stripping, thermal throttling, battery management, and platform-specific tuning.
author: Diego Villanueva
trigger: When optimizing for mobile platforms (iOS/Android), managing draw calls, handling thermal throttling, or configuring mobile-specific build settings.
---

# Mobile Optimization

Mobile GPUs are 10-100x weaker than desktop GPUs. You have a strict power budget (battery), thermal limits, and fragmented hardware. Every draw call, every texture, every shader variant costs real battery life.

## 1. Mobile Performance Budgets

```text
Target: 60fps → 16.67ms per frame, 30fps → 33.33ms
Mobile Budget (60fps):
├── Draw Calls: < 100 (ideally < 50)
├── Triangles: < 100K per frame
├── Textures in memory: < 150MB
├── Shader variants: < 50
├── SetPass calls: < 30
├── Overdraw: < 2x average
├── Particle count: < 500 active
└── Audio sources: < 16 simultaneous
```

## 2. Draw Call Reduction

```csharp
// ✅ Texture Atlasing: Combine sprites into atlas
// Use Sprite Atlas (2D) or texture atlases (3D)
// Multiple objects sharing one atlas material = ONE draw call

// ✅ GPU Instancing for repeated objects
// Trees, grass, rocks, coins → same mesh, same material
// Enable "GPU Instancing" on material

// ✅ Mesh combining for static environments
using UnityEngine;

public class MeshCombiner : MonoBehaviour
{
    public void CombineStaticMeshes()
    {
        var filters = GetComponentsInChildren<MeshFilter>();
        var combines = new CombineInstance[filters.Length];

        for (int i = 0; i < filters.Length; i++)
        {
            combines[i].mesh = filters[i].sharedMesh;
            combines[i].transform = filters[i].transform.localToWorldMatrix;
        }

        var combined = new Mesh();
        combined.CombineMeshes(combines, true, true);
        GetComponent<MeshFilter>().mesh = combined;
    }
}
```

## 3. Shader Optimization

```text
✅ Mobile shader rules:
├── Use URP Lit/SimpleLit (optimized for mobile)
├── Avoid custom fragment shaders with loops
├── Limit texture samples to 3-4 per material
├── Use half precision (half, half4) instead of float where possible
├── Strip unused shader variants:
│   Edit → Project Settings → Graphics → Shader Stripping
│   - Strip unused lightmap modes
│   - Strip unused fog modes
│   - Strip debug shaders
└── Avoid alpha cutout (clip()) — use alpha blend or opaque only
```

## 4. Thermal Management

```csharp
// ✅ Monitor and respond to thermal throttling
public class ThermalManager : MonoBehaviour
{
    private void Update()
    {
        #if UNITY_ANDROID || UNITY_IOS
        float thermalLevel = SystemInfo.batteryLevel; // 0-1

        if (Application.isMobilePlatform)
        {
            // Adaptive quality: reduce when hot
            if (thermalLevel < 0.2f)
            {
                Application.targetFrameRate = 30; // Drop to 30fps
                QualitySettings.SetQualityLevel(0); // Lowest quality
            }
            else
            {
                Application.targetFrameRate = 60;
                QualitySettings.SetQualityLevel(1);
            }
        }
        #endif
    }
}

// ✅ Reduce render scale when thermal throttling is detected
// URP Asset → Render Scale: 0.75 (renders at 75% resolution)
```

## 5. Mobile Build Settings

```text
✅ Android:
├── Scripting Backend: IL2CPP (required for 64-bit, better performance)
├── API Compatibility: .NET Standard 2.1
├── Target Architectures: ARM64 only (drop ARMv7 in 2025+)
├── Minimum API Level: 26+ (Android 8.0)
├── Texture Compression: ASTC
├── Strip Engine Code: ✅
└── Managed Stripping Level: High

✅ iOS:
├── Scripting Backend: IL2CPP (mandatory)
├── Target SDK: Device SDK
├── Architecture: ARM64
├── Optimization Level: Master (release), Debug (development)
├── Strip Engine Code: ✅
└── Managed Stripping Level: High
```

## 6. Mobile-Specific UI

```text
✅ Mobile UI Guidelines:
├── Touch targets: Minimum 48x48dp (physical size)
├── Canvas Scaler: Scale With Screen Size (reference 1080x1920)
├── Avoid transparent full-screen overlays (overdraw killer)
├── Disable Raycast Target on non-interactive elements
├── Use Sprite Atlases for UI sprites
└── TextMeshPro over legacy Text (better rendering, less overdraw)
```

---

**Execution Protocol**
1. **Profile on Device**: ALWAYS profile on the actual target device, not in the Editor or on a desktop.
2. **< 100 Draw Calls**: Keep total draw calls under 100 on mobile. Use Frame Debugger to identify waste.
3. **ASTC Textures**: Use ASTC compression for all textures. Never ship uncompressed or RGBA32 to mobile.
4. **IL2CPP Always**: ALWAYS use IL2CPP scripting backend on mobile for performance and 64-bit support.
5. **Adaptive Quality**: Implement adaptive quality that reduces settings when battery is low or device is thermal throttling.
