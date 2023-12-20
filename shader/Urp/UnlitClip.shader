Shader "UnlitClip"
{
    Properties{
        
        [HDR]_BaseColor("Main Color",color) = (1,1,1,1)
        _BaseMap("Main Tex",2D) = "white"{}
        _alphaClip("AlphaClip",Range(0,1)) = 0
    }
    
    SubShader
    {
        Tags { 
            
            "Queue"="Geometry"
            "RenderType" = "Opaque"
        }
        LOD 100
        HLSLINCLUDE
        
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            float _alphaClip;
            float _range;
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);
            CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Blend One Zero
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
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
                output.uv = TRANSFORM_TEX( input.uv , _BaseMap);
                return output;
            }
 
            half4 frag(Varyings input) : SV_Target
            {
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                clip(baseMap - _alphaClip);
                return baseMap * _BaseColor ;
            }
            ENDHLSL
        }
    }
}