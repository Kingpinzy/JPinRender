Shader "UnlitTransparent"
{
    Properties
    {
        [HDR]_BaseColor("Main Color",color) = (1,1,1,1)
        _BaseMap("Main Tex",2D) = "gray"
    }
 
    SubShader
    {
        Tags { 
            
            "Queue"="Transparent"
            "RenderType" = "Transparent"
        }
        LOD 100
 
        Pass
        {
            Name "Main"
             Tags
            {
                "RenderPipeline" = "UniversalPipeline" 
                "LightMode" = "UniversalForward"
            }
            
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Back
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);
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
                output.uv = TRANSFORM_TEX(input.uv , _BaseMap);
                return output;
            }
 
            half4 frag(Varyings input) : SV_Target
            {
                half4 col;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                col.rgb = baseMap.rgb * _BaseColor.rgb;
                col.a = baseMap.a * _BaseColor.a;
                return col;
            }
            ENDHLSL
        }
    }
}