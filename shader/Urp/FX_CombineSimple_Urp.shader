Shader "SURender/URP/FX/FX_CombineSimple"
{
    Properties
    {
        //主贴图
        [Header(Main)][Space(10)]
        _MainTex ("贴图", 2D) = "white" {}
        _Color ("颜色", Color) = (1, 1, 1, 1)
        _MainHDR ("亮度", Range(0, 10)) = 1

        [Space(10)]
        _MainSpeedU ("X方向速度", Float) = 0
        _MainSpeedV ("Y方向速度", Float) = 0

        [Space(10)]
        _MainDistortionX ("X方向扭曲", Range(-1, 1)) = 0
        _MainDistortionY ("Y方向扭曲", Range(-1, 1)) = 0

        //遮罩
        [Space(10)][Header(Mask)][Space(10)]
        _MaskTex ("贴图(R,A通道)", 2D) = "white" {}

        [Space(10)]
        _MaskSpeedU ("X方向速度", Float) = 0
        _MaskSpeedV ("Y方向速度", Float) = 0

        [Space(10)]
        _MaskDistortionX ("X方向扭曲", Range(-1, 1)) = 0
        _MaskDistortionY ("Y方向扭曲", Range(-1, 1)) = 0

        [Toggle(_MASK_AFFECT_DISSOLVE)] _MaskAffectDissolve ("转为溶解遮罩", Float) = 0

        //溶解
        [Space(10)][Header(Dissolve)][Space(10)]
        _DissolveTex ("贴图(R,A通道)", 2D) = "white" {}
        _DissolveEdgeColor ("边颜色", Color) = (1, 0, 0.25, 1)
        _DissolveEdgeHDR ("边亮度", Range(0, 10)) = 1
        [Enum(Alpha, 0, Add, 1)] _DissolveBlend ("边混合模式", Float) = 0

        [Space(10)]
        _DissolveRate ("溶解度", Range(-1, 1)) = -0.3
        _DissolveEdgeWidth ("边宽度", Range(0.01, 1)) = 0.5
        _DissolveEdgeSoft ("边软化", Range(0.01, 0.99)) = 0.999
        _DissolveEdgeOffset ("软化偏移", Range(0.01, 0.99)) = 0.5

        [Space(10)]
        _DissolveSpeedU ("X方向速度", Float) = 0
        _DissolveSpeedV ("Y方向速度", Float) = 0

        [Space(10)]
        _DissolveDistortionX ("X方向扭曲", Range(-1, 1)) = 0
        _DissolveDistortionY ("Y方向扭曲", Range(-1, 1)) = 0

        //扭曲
        [Space(10)][Header(Distortion)][Space(10)]
        _DistortionTex ("贴图(R,A通道)", 2D) = "black" {}
        _DistortionSpeedU ("X方向速度", Float) = 0
        _DistortionSpeedV ("Y方向速度", Float) = 0

        //渲染设置
        [Space(10)][Header(Render)][Space(10)]
        [Enum(Alpha, 10, Add, 1)] _DstBlend ("Blend Mode", Float) = 10
    }

    Category
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "PreviewType" = "Plane"
            "LightMode" = "SRPDefaultUnlit"
        }

        Blend SrcAlpha [_DstBlend]
        ZTest Lequal
        ZWrite Off
        Cull Off

        HLSLINCLUDE
        
        

        #pragma target 2.0
        #pragma fragmentoption ARB_precision_hint_fastest

        #pragma multi_compile_local __ _MASK_AFFECT_DISSOLVE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Assets/JPinRender/KingPinCore/FX.hlsl"
        
        #define SAMPLER_2D(tex) Texture2D tex; SamplerState sampler##tex
        #define TEX_2D(tex,coord) tex.Sample (sampler##tex,coord)
        #define MAX_1(input) min(input, 1)

        SAMPLER_2D(_MainTex);
        SAMPLER_2D(_DetailTex);
        SAMPLER_2D(_MaskTex);
        SAMPLER_2D(_DissolveTex);
        SAMPLER_2D(_DistortionTex);

        //主帖图
        float4 _MainTex_ST;
        half4 _Color;
        half _MainHDR;

        half _MainSpeedU;
        half _MainSpeedV;

        half _MainDistortionX;
        half _MainDistortionY;

        //遮罩
        float4 _MaskTex_ST;

        half _MaskSpeedU;
        half _MaskSpeedV;

        half _MaskDistortionX;
        half _MaskDistortionY;

        //溶解
        float4 _DissolveTex_ST;
        half4 _DissolveEdgeColor;
        half _DissolveEdgeHDR;
        half _DissolveBlend;

        half _DissolveRate;
        half _DissolveEdgeWidth;
        half _DissolveEdgeSoft;
        half _DissolveEdgeOffset;

        half _DissolveSpeedU;
        half _DissolveSpeedV;

        half _DissolveDistortionX;
        half _DissolveDistortionY;

        //扭曲
        float4 _DistortionTex_ST;

        half _DistortionSpeedU;
        half _DistortionSpeedV;
        
        struct Attributes
        {
            float4 positionOS : POSITION;
            float4 uv : TEXCOORD0;
            half4 vertexColor : COLOR;

            half3 custom1 : TEXCOORD1;
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float4 uv : TEXCOORD0;
            half4 vertexColor : COLOR;

            half3 custom1 : TEXCOORD1;
        };


        
        ENDHLSL

        SubShader
        {
            Pass
            {
                HLSLPROGRAM
                
                #pragma vertex vert
                #pragma fragment frag
                
                Varyings vert(Attributes input)
                {
                    Varyings output;
                    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                    output.vertexColor = input.vertexColor;
                    output.uv = input.uv;

                    output.custom1 = input.custom1; //w未使用

                    return output;
                }

                half4 frag(Varyings input) : SV_Target
                {
                    half4 output;
                    float2 uv;

                    //前期准备
                    half mask;
                    float time = frac(_Time.g * 0.01) * 100;

                    //扭曲
                    uv = OffsetUV(input.uv.xy, _DistortionSpeedU, _DistortionSpeedV, time) * _DistortionTex_ST.xy + _DistortionTex_ST.zw;
                    half4 distortionTex = TEX_2D(_DistortionTex, uv);
                    half distortion = min(distortionTex.r, distortionTex.a) - 0.5;

                    //主帖图
                    _MainTex_ST.zw += input.uv.zw;
                    OffsetUV(input.uv.xy, _MainSpeedU, _MainSpeedV, time) * _MainTex_ST.xy + _MainTex_ST.zw;
                    ComputeDistortionUV(uv, distortion, _MainDistortionX, _MainDistortionY);
                    output = TEX_2D(_MainTex, uv) * _Color;
                    output.rgb *= _MainHDR;

                    //遮罩
                    _MaskTex_ST.zw += input.custom1.xy;
                    uv = OffsetUV(input.uv.xy, _MaskSpeedU, _MaskSpeedV, time) * _MaskTex_ST.xy + _MaskTex_ST.zw;
                    ComputeDistortionUV(uv, distortion, _MaskDistortionX, _MaskDistortionY);
                    half4 maskTex = TEX_2D(_MaskTex, uv);
                    mask = min(maskTex.r, maskTex.a);

                    #ifndef _MASK_AFFECT_DISSOLVE
                    output.a *= mask;
                    #endif

                    //溶解
                    _DissolveRate += input.custom1.z;
                    uv = OffsetUV(input.uv.xy, _DissolveSpeedU, _DissolveSpeedV, time) * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
                    ComputeDistortionUV(uv, distortion, _DissolveDistortionX, _DissolveDistortionY);
                    half4 dissolveTex = TEX_2D(_DissolveTex, uv);

                    #if defined _MASK && _MASK_AFFECT_DISSOLVE
                    _DissolveRate = _DissolveRate * 1.5 - 0.5;
                    dissolveTex += mask;
                    #endif

                    ComputeDissolve(output, min(dissolveTex.r, dissolveTex.a), _DissolveEdgeColor, _DissolveEdgeHDR, _DissolveBlend, _DissolveRate, _DissolveEdgeWidth, _DissolveEdgeSoft, _DissolveEdgeOffset);

                    //输出
                    return half4(output.rgb, output.a);
                }
                ENDHLSL
            }
        }
    }
}