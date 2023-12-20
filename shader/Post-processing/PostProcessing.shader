Shader "Post-processing/PostProcessing"
{
  Properties
    {
        _BaseColor("Main Color",color) = (1,1,1,1)
        _BaseMap("Main Tex",2D) = "white" {}
        _Value("对比度", Range(0, 1)) = 0.0
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
            #include "Assets/KingPinCore/Effect.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            float _Value;
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);
            //float = 32//坐标点
            //half = 16 大部分UV，向量
            //fixed = 8 颜色
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
                output.uv = TRANSFORM_TEX( input.uv , _BaseMap);
                return output;
            }
 
            half4 frag(Varyings input) : SV_Target
            {
                half4 col;
                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);

                half3 Gay = GetSaturation(baseMap,_Value);
                col.rgb = Gay;
                col.a = Gay.r;
                
               
                
                return col ;
            }
            ENDHLSL
        }
    }
}
