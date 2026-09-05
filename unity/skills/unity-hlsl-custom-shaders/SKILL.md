---
name: unity-hlsl-custom-shaders
description: Custom HLSL and ShaderLab shader programming for Unity including render passes, compute shaders, GPU instancing, SRP Batcher compatibility, and stencil operations.
author: Diego Villanueva
trigger: When writing custom HLSL shaders, compute shaders, custom render passes, GPU instancing, or advanced rendering techniques beyond Shader Graph capabilities.
---

# Custom HLSL & ShaderLab Shaders

When Shader Graph's node-based system is insufficient — custom render passes, compute shaders, GPU instancing, or advanced stencil operations — you write raw HLSL within Unity's ShaderLab framework.

## 1. ShaderLab Structure (URP Compatible)

```hlsl
// ✅ URP-compatible custom shader template
Shader "Custom/URPLitExample"
{
    Properties
    {
        _BaseMap ("Base Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [Normal] _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", Range(0, 2)) = 1.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // SRP Batcher compatibility: all material properties in CBUFFER
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
                half _Smoothness;
                half _NormalStrength;
            CBUFFER_END

            TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
            TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float4 tangentWS : TEXCOORD3;
                float fogFactor : TEXCOORD4;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = posInputs.positionCS;
                output.positionWS = posInputs.positionWS;
                output.normalWS = normInputs.normalWS;
                output.tangentWS = float4(normInputs.tangentWS, input.tangentOS.w);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.fogFactor = ComputeFogFactor(posInputs.positionCS.z);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                half4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;

                // Normal mapping
                half3 normalTS = UnpackNormalScale(
                    SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv), _NormalStrength);
                float sgn = input.tangentWS.w;
                float3 bitangent = sgn * cross(input.normalWS, input.tangentWS.xyz);
                float3x3 TBN = float3x3(input.tangentWS.xyz, bitangent, input.normalWS);
                float3 normalWS = normalize(mul(normalTS, TBN));

                // Lighting
                InputData inputData = (InputData)0;
                inputData.positionWS = input.positionWS;
                inputData.normalWS = normalWS;
                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                inputData.fogCoord = input.fogFactor;

                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = baseColor.rgb;
                surfaceData.alpha = baseColor.a;
                surfaceData.smoothness = _Smoothness;
                surfaceData.metallic = 0;

                half4 color = UniversalFragmentPBR(inputData, surfaceData);
                color.rgb = MixFog(color.rgb, input.fogFactor);
                return color;
            }
            ENDHLSL
        }

        // Shadow pass
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        UsePass "Universal Render Pipeline/Lit/DepthOnly"
    }
}
```

## 2. Compute Shaders

```hlsl
// ✅ Compute shader for GPU-parallel work
// GrassCompute.compute
#pragma kernel CSMain

struct GrassData
{
    float3 position;
    float height;
    float4 color;
};

RWStructuredBuffer<GrassData> _GrassBuffer;
float _Time;
float _WindStrength;
float3 _WindDirection;

[numthreads(256, 1, 1)]
void CSMain(uint3 id : SV_DispatchThreadID)
{
    GrassData grass = _GrassBuffer[id.x];

    // Animate grass with wind
    float windOffset = sin(_Time * 2.0 + grass.position.x * 0.5 + grass.position.z * 0.3);
    grass.position.x += _WindDirection.x * windOffset * _WindStrength * grass.height;
    grass.position.z += _WindDirection.z * windOffset * _WindStrength * grass.height;

    _GrassBuffer[id.x] = grass;
}
```

```csharp
// ✅ Dispatch compute shader from C#
public class GrassRenderer : MonoBehaviour
{
    [SerializeField] private ComputeShader _computeShader;
    private ComputeBuffer _grassBuffer;
    private int _kernelIndex;

    private void Awake()
    {
        _kernelIndex = _computeShader.FindKernel("CSMain");
        _grassBuffer = new ComputeBuffer(_grassCount, sizeof(float) * 8);
        _grassBuffer.SetData(_grassData);
    }

    private void Update()
    {
        _computeShader.SetBuffer(_kernelIndex, "_GrassBuffer", _grassBuffer);
        _computeShader.SetFloat("_Time", Time.time);
        _computeShader.SetFloat("_WindStrength", _windStrength);
        _computeShader.SetVector("_WindDirection", _windDirection);

        int threadGroups = Mathf.CeilToInt(_grassCount / 256f);
        _computeShader.Dispatch(_kernelIndex, threadGroups, 1, 1);
    }

    private void OnDestroy() => _grassBuffer?.Release();
}
```

## 3. GPU Instancing

```hlsl
// ✅ Enable GPU Instancing for per-instance properties
#pragma multi_compile_instancing

UNITY_INSTANCING_BUFFER_START(Props)
    UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
    UNITY_DEFINE_INSTANCED_PROP(half, _Dissolve)
UNITY_INSTANCING_BUFFER_END(Props)

// Access in fragment shader:
half4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _BaseColor);
```

```csharp
// ✅ Set per-instance properties via MaterialPropertyBlock
private MaterialPropertyBlock _mpb;

private void Awake() => _mpb = new MaterialPropertyBlock();

public void SetInstanceColor(Renderer renderer, Color color)
{
    renderer.GetPropertyBlock(_mpb);
    _mpb.SetColor("_BaseColor", color);
    renderer.SetPropertyBlock(_mpb);
}
```

## 4. Stencil Operations

```hlsl
// ✅ Stencil for X-ray / see-through-walls effect
// Pass 1: Write stencil value for characters behind walls
Stencil
{
    Ref 1
    Comp Always
    Pass Replace
    ZFail Replace  // Write stencil even when behind geometry
}
ZWrite Off
ZTest Greater  // Only render when BEHIND geometry

// Pass 2: Outline/silhouette shader reads stencil
Stencil
{
    Ref 1
    Comp Equal     // Only render where stencil == 1
}
// Render solid color silhouette
```

## 5. SRP Batcher Compatibility

```text
Rules for SRP Batcher compatibility:
1. ALL material properties must be inside CBUFFER_START(UnityPerMaterial)
2. ALL built-in engine properties (matrices, time) use unity_* or UNITY_MATRIX_*
3. Do NOT use MaterialPropertyBlock (breaks SRP Batcher)
4. Use TEXTURE2D and SAMPLER macros instead of sampler2D

Verify: Window → Analysis → Frame Debugger → check "SRP Batcher" batching
```

---

**Execution Protocol**
1. **SRP Batcher First**: ALL custom shaders MUST be SRP Batcher compatible. Put material properties in `CBUFFER_START(UnityPerMaterial)`.
2. **URP Include Paths**: Always include from `Packages/com.unity.render-pipelines.universal/ShaderLibrary/`, never from legacy CG paths.
3. **Compute for Parallel Work**: Use compute shaders for grass, crowds, fluid simulation — anything processing thousands of elements per frame.
4. **Release Buffers**: ALWAYS call `ComputeBuffer.Release()` in `OnDestroy` or `OnDisable`.
5. **Minimize Variants**: Use `#pragma shader_feature` (stripped when unused) instead of `#pragma multi_compile` (always compiled) for optional features.
