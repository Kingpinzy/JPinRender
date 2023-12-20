Shader "KPinURP/Blinn-Phong"
{
    Properties
    {
        _MainColor("Main Color",color) = (1,1,1,1)
        _MainTex("Main Texture",2D) = "white"{}
        _ambient("环境颜色", color) = (1,1,1,1)
        _SpecularColor("Specular", Color) = (1,1,1,1)
        _Gloss("_Gloss", Range(0,50)) = 0
        
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
            half4 _MainColor;
            half _Gloss;
            half4 _SpecularColor;
            float4 _MainTex_ST;
            TEXTURE2D (_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _ambient;
            

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
                float3 normalWS : NORMAL;
                float3 positionWS : TEXCOORD2;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
 
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = TransformObjectToWorldNormal(input.normal);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                return output;
            }
 
            half4 frag(Varyings input) : SV_Target
            {
                float3 ambient = _ambient;
                
                float3 normal = normalize(input.normalWS);//法线
                
                Light mainLight = GetMainLight();

                float nl = saturate(dot(normal, mainLight.direction));//计算nl
                
                half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);//采样贴图
               
                half3 gi = SampleSH(input.normalWS);
                half3 diffuse =  mainLight.color * baseMap * _MainColor * nl;//计算漫反射颜色
                
                //---开始计算反射
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);//视线方向
                float3 H = normalize(mainLight.direction + viewDir);//半角向量
                float hn = saturate(dot(H,normal)) ;
                float3 specular =  _SpecularColor * pow(hn, _Gloss);//镜面反射
                //---加在一起
                half4 output;
                float3 finaColor = diffuse + specular ;
                
                output.rgb = finaColor;
                output.a = 1;
                
                
                return output;
                
            }
            ENDHLSL
        }
    }
}
               