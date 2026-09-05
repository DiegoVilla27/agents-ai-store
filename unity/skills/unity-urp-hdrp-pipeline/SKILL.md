---
name: unity-urp-hdrp-pipeline
description: Universal and High Definition Render Pipeline configuration for Unity including Renderer Features, custom render passes, RenderGraph API, and pipeline selection.
author: Diego Villanueva
trigger: When configuring URP or HDRP, creating custom Renderer Features, implementing custom render passes, or choosing between render pipelines.
---

# URP & HDRP Render Pipelines

Unity provides two Scriptable Render Pipelines: **URP** (Universal) for cross-platform and **HDRP** (High Definition) for high-fidelity PC/console. The choice is permanent for a project — migration between pipelines is extremely costly.

## 1. Pipeline Selection

```text
URP (Universal Render Pipeline):
✅ Use for: Mobile, WebGL, Nintendo Switch, indie games, stylized art
- Single pass forward rendering
- Light-weight, 60fps on mobile
- 2D Renderer for pure 2D games
- Shader Graph + custom HLSL
- Max 8 per-pixel lights (configurable)
- Screen-space ambient occlusion, bloom, DOF

HDRP (High Definition Render Pipeline):
✅ Use for: PC, PS5, Xbox Series, AAA-quality, photorealism
- Deferred + Forward rendering
- Volumetric fog, clouds, lighting
- Ray tracing support (RTX)
- Sub-surface scattering (skin, wax, marble)
- Area lights, screen-space reflections
- Extremely GPU-heavy
```

## 2. URP Asset Configuration

```text
✅ URP Asset (UniversalRenderPipelineAsset):
├── Rendering
│   ├── Renderer: Forward / Forward+
│   ├── Depth Texture: ✅ (required for depth-based effects)
│   ├── Opaque Texture: ✅ (required for glass/water refraction)
│   └── HDR: ✅ (required for bloom)
├── Quality
│   ├── Anti-Aliasing: MSAA 4x (PC) / FXAA (mobile)
│   ├── Render Scale: 1.0 (PC) / 0.75 (mobile for performance)
│   └── Upscaling Filter: FSR (AMD FidelityFX)
├── Lighting
│   ├── Main Light: Per Pixel
│   ├── Additional Lights: Per Pixel, limit 4-8
│   ├── Reflection Probes: Blended
│   └── Mixed Lighting: Subtractive or Shadow Mask
├── Shadows
│   ├── Max Distance: 50-150m
│   ├── Cascade Count: 2 (mobile) / 4 (PC)
│   └── Shadow Resolution: 1024-2048
└── Post-Processing
    └── Grading Mode: HDR
```

## 3. Renderer Features (URP)

```csharp
// ✅ Custom Renderer Feature for outline/effect passes
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class OutlineRendererFeature : ScriptableRendererFeature
{
    [SerializeField] private Material _outlineMaterial;
    [SerializeField] private RenderPassEvent _renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

    private OutlineRenderPass _pass;

    public override void Create()
    {
        _pass = new OutlineRenderPass(_outlineMaterial)
        {
            renderPassEvent = _renderPassEvent
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (_outlineMaterial != null)
            renderer.EnqueuePass(_pass);
    }
}

public class OutlineRenderPass : ScriptableRenderPass
{
    private readonly Material _material;
    private readonly List<ShaderTagId> _shaderTags = new() { new ShaderTagId("UniversalForward") };

    public OutlineRenderPass(Material material) => _material = material;

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get("OutlinePass");

        // Custom rendering logic here
        var drawingSettings = CreateDrawingSettings(_shaderTags, ref renderingData,
            SortingCriteria.CommonOpaque);
        drawingSettings.overrideMaterial = _material;
        drawingSettings.overrideMaterialPassIndex = 0;

        var filterSettings = new FilteringSettings(RenderQueueRange.opaque);

        context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filterSettings);
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}
```

## 4. Multiple URP Assets (Quality Tiers)

```text
✅ Create multiple URP Assets for quality settings:
├── URP_Low.asset     → Mobile/Low-end: MSAA off, shadow res 512, 2 cascades
├── URP_Medium.asset  → Console: MSAA 2x, shadow res 1024, 3 cascades
├── URP_High.asset    → PC: MSAA 4x, shadow res 2048, 4 cascades
└── URP_Ultra.asset   → High-end PC: MSAA 8x, shadow res 4096, 4 cascades

Assign in: Project Settings → Quality → Rendering → Render Pipeline Asset
```

```csharp
// ✅ Switch quality tier at runtime
using UnityEngine.Rendering;

public void SetQualityLevel(int level)
{
    QualitySettings.SetQualityLevel(level, applyExpensiveChanges: true);
    // Each quality level can reference a different URP Asset
}
```

## 5. HDRP Specific Features

```text
HDRP Exclusive Features:
├── Volumetric Fog: Density Volume component with noise
├── Volumetric Clouds: Procedural cloud layers
├── Screen-Space GI: Dynamic indirect lighting
├── Ray Tracing: Reflections, shadows, GI, AO
├── Sub-Surface Scattering: Profile for skin, wax, leaves
├── Area Lights: Rectangle/Disc lights with physical falloff
├── Decal Projectors: High-quality projected decals
├── Custom Pass Volume: Insert custom rendering at specific injection points
└── Physical Camera: Aperture, ISO, Shutter Speed for exposure
```

## 6. 2D Renderer (URP)

```text
✅ URP 2D Renderer for pure 2D games:
- 2D Lights: Point Light 2D, Global Light 2D, Sprite Light 2D, Freeform Light 2D
- Normal Maps on sprites for 2D lighting response
- Shadow Caster 2D for sprite shadows
- Sorting Layers for depth ordering
- Separate Renderer Asset for 2D projects
```

---

**Execution Protocol**
1. **Choose Pipeline FIRST**: Select URP or HDRP before creating any assets. Migration is prohibitively expensive.
2. **Quality Tiers**: Create separate URP Assets for Low/Medium/High quality, not runtime parameter changes.
3. **Depth + Opaque Textures**: Enable Depth Texture and Opaque Texture in URP Asset if using water, glass, or depth-based effects.
4. **Renderer Features for Passes**: ALL custom rendering (outlines, X-ray, blur zones) MUST be implemented as Renderer Features, not camera scripts.
5. **HDR + Bloom**: ALWAYS enable HDR rendering when using Bloom post-processing. Without HDR, bloom has no dynamic range to work with.
