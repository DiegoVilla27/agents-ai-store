---
name: unity-shader-graph
description: Shader Graph mastery for Unity URP/HDRP including PBR materials, toon/cel shading, dissolve effects, water shaders, holograms, force fields, and vertex displacement.
author: Diego Villanueva
trigger: When creating visual effects using Shader Graph, designing custom materials, implementing toon shading, dissolve effects, water rendering, or any node-based shader work.
---

# Shader Graph

Shader Graph is Unity's node-based visual shader editor for URP and HDRP. It generates optimized HLSL code without manual shader programming, making it accessible for artists while maintaining performance.

## 1. Shader Graph Architecture

```text
Graph Types:
├── Lit Shader Graph       → PBR materials (metallic/specular workflow)
├── Unlit Shader Graph     → No lighting (UI, particles, stylized)
├── Sprite Lit/Unlit       → 2D sprite shaders
├── Canvas Shader Graph    → UI Toolkit shaders
├── Decal Shader Graph     → Projected decals (bullet holes, blood)
└── Fullscreen Shader Graph→ Post-processing effects

Key Concepts:
- Master Stack: Final output (Base Color, Normal, Metallic, Emission, Alpha)
- Sub Graphs: Reusable shader modules (noise generators, UV utilities)
- Keywords: Shader variants (toggle features on/off per material)
- Custom Function Nodes: Inject custom HLSL into Shader Graph
```

## 2. Dissolve Effect

```text
Node Setup:
1. Sample Texture 2D (Noise texture) → grayscale output
2. Step node: Step(noiseValue, _DissolveAmount)
   - _DissolveAmount: Float property (0 = fully visible, 1 = fully dissolved)
3. Output Step result to Alpha Clip Threshold
4. Edge glow: Subtract step - smoothstep for edge detection → Emission

Properties:
- _DissolveAmount (Float, Slider 0-1)
- _EdgeColor (Color, HDR)
- _EdgeWidth (Float, 0.05)
- _NoiseTexture (Texture2D)
```

```csharp
// ✅ Control dissolve from C#
public class DissolveEffect : MonoBehaviour
{
    [SerializeField] private Material _dissolveMaterial;
    private static readonly int DissolveAmount = Shader.PropertyToID("_DissolveAmount");

    public async Awaitable Dissolve(float duration)
    {
        float elapsed = 0f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            _dissolveMaterial.SetFloat(DissolveAmount, elapsed / duration);
            await Awaitable.NextFrameAsync();
        }
    }
}
```

## 3. Toon/Cel Shading

```text
Approach:
1. Custom Lighting: Use Custom Function node to access light data
2. Ramp Texture: Sample a 1D gradient texture with NdotL
   - Sharp gradient → hard cel edges (2-3 bands)
   - Smooth gradient → soft toon shading
3. Rim Lighting: Fresnel Effect node → power → multiply with rim color
4. Outline: Either:
   a. Inverted hull method (second pass, vertex extrusion along normals)
   b. Post-processing edge detection

Custom Function (HLSL):
void MainLight_float(float3 WorldPos, out float3 Direction, out float3 Color, out float Attenuation)
{
    #ifdef SHADERGRAPH_PREVIEW
        Direction = float3(0.5, 0.5, 0);
        Color = 1;
        Attenuation = 1;
    #else
        Light mainLight = GetMainLight(TransformWorldToShadowCoord(WorldPos));
        Direction = mainLight.direction;
        Color = mainLight.color;
        Attenuation = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
    #endif
}
```

## 4. Water Shader

```text
Components:
1. Vertex Displacement:
   - Gerstner waves (sum of sine waves with direction)
   - Time node → multiply → sin(UV + time) → vertex offset Y
2. Surface:
   - Normal Map from Voronoi/Noise animated over time
   - Two scrolling normal maps blended (detail)
3. Color:
   - Depth-based color gradient (shallow = light blue, deep = dark)
   - Scene Color node for refraction (grab pass)
4. Foam:
   - Depth difference at edges → foam texture mask
5. Transparency:
   - Depth fade for soft intersection with geometry
```

## 5. Hologram Effect

```text
Nodes:
1. Fresnel Effect → rim glow (edge highlighting)
2. Scanlines: UV.y → multiply by frequency → frac → step → multiply with color
3. Glitch: Random noise on vertex position (small offset)
4. Alpha: Combine fresnel + scanlines → alpha
5. Emission: HDR color * scanline mask

Properties:
- _HoloColor (Color HDR, cyan)
- _ScanlineSpeed (Float, 2.0)
- _ScanlineFrequency (Float, 100)
- _GlitchIntensity (Float, 0.01)
- _FresnelPower (Float, 3.0)
```

## 6. Force Field / Shield Effect

```text
Components:
1. Intersection Highlighting:
   - Scene Depth node - Fragment Depth → depth difference
   - Smoothstep near zero → bright edge where shield meets geometry
2. Fresnel rim glow (edge of sphere)
3. Hexagonal pattern:
   - UV → hex grid function (Custom Function node)
   - Animate pattern on impact
4. Impact ripple:
   - Pass impact point as Vector3 property
   - Distance from impact → ripple wave (sin of distance - time)
5. Alpha: Combine intersection + fresnel + pattern
6. Emission: HDR color * combined mask
```

## 7. Sub Graphs (Reusable Modules)

```text
✅ Create Sub Graphs for commonly used patterns:
├── SG_Noise (Perlin, Voronoi, Simplex with scale/offset/speed)
├── SG_UVScroll (scroll UVs with speed and direction)
├── SG_Fresnel (configurable fresnel with power and color)
├── SG_DepthFade (soft intersection with scene depth)
├── SG_Triplanar (triplanar mapping with blend sharpness)
└── SG_WorldSpaceTiling (tile textures in world space, not UV)
```

## 8. Shader Variants & Keywords

```csharp
// ✅ Use Keywords to create shader variants
// In Shader Graph: Add Keyword (Boolean, Enum, or Built-in)
// Example: _EMISSION_ON keyword toggles emission calculation

// Enable/disable keyword from C#
material.EnableKeyword("_EMISSION_ON");
material.DisableKeyword("_EMISSION_ON");

// ⚠️ WARNING: Every keyword DOUBLES the number of shader variants
// Keep keywords to a minimum (< 5 per shader)
// Use "Shader Variants" strip settings to remove unused variants from builds
```

---

**Execution Protocol**
1. **Sub Graphs for Reuse**: Any node pattern used in more than one shader MUST be extracted into a Sub Graph.
2. **Property Naming Convention**: Use `_PascalCase` for shader properties (`_BaseColor`, `_DissolveAmount`, `_EmissionStrength`).
3. **Minimize Keywords**: Each keyword multiplies shader variants. Strip unused variants in Player Settings → Graphics → Shader Stripping.
4. **Custom Functions for Lighting**: Access Unity's lighting data via Custom Function nodes with HLSL, not by recreating lighting math.
5. **HDR Colors for Emission**: ALWAYS use HDR color properties for emission to enable bloom post-processing.
