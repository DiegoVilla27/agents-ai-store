---
name: unity-lighting-rendering
description: Complete lighting and rendering mastery for Unity including baked vs realtime lighting, lightmaps, light probes, reflection probes, global illumination, and post-processing.
author: Diego Villanueva
trigger: When setting up scene lighting, configuring lightmaps, placing light/reflection probes, implementing global illumination, or adding post-processing effects.
---

# Lighting & Rendering

Lighting defines the visual quality and mood of a game. Unity supports baked, realtime, and mixed lighting pipelines. Understanding when to use each is critical for both visual fidelity and performance.

## 1. Lighting Modes

```text
Realtime Lighting:
- Computed every frame on the GPU
- Supports dynamic shadows, moving lights
- Performance cost: HIGH (shadow maps, per-pixel lighting)
- Use for: Sun, player flashlight, explosions, dynamic gameplay lights

Baked Lighting (Lightmaps):
- Pre-computed and stored as textures (lightmaps)
- Zero runtime cost for indirect lighting
- Cannot move or change at runtime
- Use for: Static environments, architectural visualization, ambient light

Mixed Lighting:
- Direct light is realtime, indirect is baked
- Best of both worlds for static environments with dynamic objects
- Use for: Most production games
```

## 2. Lightmap Settings

```text
✅ Optimal Lightmap Settings (Window → Rendering → Lighting):
├── Lightmapper: Progressive GPU (fastest bake)
├── Lightmap Resolution: 20-40 texels/unit (balance quality/size)
├── Lightmap Size: 1024 or 2048 (avoid 4096 on mobile)
├── Compress Lightmaps: ✅ (reduces memory)
├── Ambient Occlusion: ✅ (adds depth to indirect lighting)
│   ├── Max Distance: 1-3
│   └── Indirect/Direct Contribution: 1.0/0.0
├── Directional Mode: Directional (for normal-mapped surfaces)
└── Indirect Intensity: 1.0-2.0 (boost for darker scenes)

Marking objects as static:
- Contribute GI: ✅ (this object EMITS light into lightmaps)
- Receive GI: Lightmaps (this object RECEIVES baked light)
```

## 3. Light Probes (Dynamic Objects in Baked Scenes)

```text
Problem: Baked lighting only affects static geometry.
         Dynamic objects (characters, items) appear unlit.

Solution: Light Probes sample baked lighting at probe positions
          and interpolate for dynamic objects.

✅ Light Probe Placement:
- Place densely where lighting CHANGES (doorways, shadows, color transitions)
- Place sparsely in uniform areas (open fields, uniformly lit rooms)
- Create Light Probe Group → Edit → Place probes in 3D grid
- Minimum: 4 probes around any dynamic object path
```

## 4. Reflection Probes

```text
Types:
├── Baked: Pre-rendered cubemap (static reflections)
├── Realtime: Re-rendered every frame (expensive, use sparingly)
└── Custom: Assign a pre-made cubemap texture

✅ Placement Rules:
- One probe per distinct reflection environment (rooms, corridors)
- Box Projection: ✅ (for interior spaces — corrects parallax)
- Set Box Size to match room dimensions exactly
- Importance: Higher values take priority in overlapping regions
- Resolution: 128 or 256 (enough for most reflections)
```

## 5. Post-Processing (URP Volume System)

```csharp
// ✅ Post-processing via URP Volume system
// 1. Create GameObject → Volume (Global)
// 2. Create Volume Profile asset
// 3. Add overrides:

// Setup in scene:
// Global Volume (affects entire camera)
//   ├── Bloom (Threshold: 1.0, Intensity: 0.5)
//   ├── Color Adjustments (Post Exposure, Contrast, Saturation)
//   ├── Tonemapping (Mode: ACES)
//   ├── Vignette (Intensity: 0.3)
//   ├── Film Grain (Intensity: 0.1)
//   └── Chromatic Aberration (Intensity: 0.05)

// Local Volume (trigger zones — underwater, damage, etc.)
//   ├── BoxCollider (Is Trigger)
//   ├── Volume (Is Global: false)
//   ├── Color Adjustments (blue tint for underwater)
//   └── Depth of Field (blur underwater)
```

```csharp
// ✅ Modify post-processing at runtime
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostProcessController : MonoBehaviour
{
    [SerializeField] private Volume _volume;
    private Vignette _vignette;
    private ChromaticAberration _chromatic;

    private void Awake()
    {
        _volume.profile.TryGet(out _vignette);
        _volume.profile.TryGet(out _chromatic);
    }

    public void OnPlayerDamaged()
    {
        _vignette.intensity.value = 0.6f;   // Red vignette flash
        _vignette.color.value = Color.red;
        _chromatic.intensity.value = 0.5f;    // Chromatic aberration on hit
    }

    public void ResetEffects()
    {
        _vignette.intensity.value = 0.2f;
        _vignette.color.value = Color.black;
        _chromatic.intensity.value = 0f;
    }
}
```

## 6. Shadows Configuration

```text
✅ Shadow Settings (URP Asset):
├── Shadow Distance: 50-150m (game dependent)
├── Shadow Cascades: 4 (for open world), 2 (for indoor/mobile)
├── Shadow Resolution: 2048 (PC), 1024 (mobile)
├── Soft Shadows: ✅ (visual quality, slight GPU cost)
└── Shadow Depth Bias / Normal Bias: Adjust to eliminate shadow acne

Per-Light Settings:
├── Shadow Type: Soft Shadows
├── Shadow Resolution: Use Pipeline Settings (or override)
└── Shadow Near Plane: Keep close to light to maximize shadow map precision
```

---

**Execution Protocol**
1. **Bake Everything Static**: Mark all non-moving geometry as `Static` → `Contribute GI` + `Receive GI: Lightmaps`.
2. **Light Probes for Dynamic Objects**: EVERY scene with baked lighting MUST have Light Probes for characters and moving objects.
3. **One Directional Light**: Use ONE Directional Light (the "sun") with realtime shadows. Additional lights should be baked or mixed.
4. **Post-Processing via Volumes**: NEVER modify camera post-processing directly. Use Volume components with profiles.
5. **Shadow Cascade Tuning**: Reduce shadow cascades and distance on mobile. Use `Shadow Distance` to match the game's view range.
