Shader "KPinURP/UrpLit"
{
    Properties
    {
        _Color("Main Color",color) = (1,1,1,1)
        _MainTex("Main Texture",2D) = "white"{}
    }
 
    SubShader
    {
        Tags { 
                "Queue"="Geometry" 
                "RenderType" = "Opaque"
                "IgnoreProjector" = "True"
                "shaderModel" = "2.0"
                
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
            Blend One Zero
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0
            #pragma fragmentoption ARB_Precision_hint_fastest
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _MainTex_ST;
            TEXTURE2D (_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_END
 
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
 
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normal);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return output;
            }
 
            half4 frag(Varyings input) : SV_Target
            {
                Light mainLight = GetMainLight();//获取主光源
                float3 normal = normalize(input.normalWS);//模型的世界空间法线

                float nl = saturate(dot(mainLight.direction,normal));

                half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half4 diffuse = baseMap * _Color;//计算颜色
                
                half4 output;

                output.rgb = diffuse.rgb * nl * mainLight.color;//最终输出淹死，乘以主光源颜色
                output.a = diffuse.a;//给a
                
                return output;
            }
            ENDHLSL
        }
    }
}