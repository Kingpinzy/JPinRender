Shader "FX/FxShader"
{
   Properties
    {
        _MainTex("主帖图", 2D) = "white" {}
        _MainColor("颜色", Color) = (1,1,1,1)
        
    }
 
    SubShader
    {
        Tags { 
            
            "Queue"="Geometry"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
            
        }
        LOD 100
 
        Pass
        {
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Assets/JPinRender/KingPinCore/FX.hlsl"

            #define SAMPLER_2D(tex) Texture2D tex; SamplerState sampler##tex

            
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainColor;
            CBUFFER_END
 
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
             
            Varyings vert(Attributes input)
            {
                Varyings output;
 
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                return output;
            }
 
            half4 frag(Varyings input) : SV_Target
            {
                half4 output;
                float2 uv;
                output = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * _MainColor;

                //--------------主帖图----------------
                
                
                
                return output ;
            }
            ENDHLSL
        }
    }
}
