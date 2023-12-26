Shader "KPinURP/PBR"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1,1,1,1)
        _DiffuseTex("Texture", 2D) = "white" {}
//        _MetallicTex("_Metallic", 2D) = "white" {}
//        _AoTex("_AO", 2D) = "white" {}
//        _RoughnessTex("_RoughnessTex", 2D) = "white" {}
        [Normal]_NormalTex("_NormalTex", 2D) = "Bump" {}
        _NormalScale("_NormalScale",Range(0,1)) = 1
        [Toggle]_NormalInvertG ("_NormalInvertG", Int) = 0
        _MaskTex ("M = R R = G AO = B E = Alpha",2D) = "white" {}
        _Metallic("_Metallic", Range(0,1)) = 1
        _Roughness("_Roughness", Range(0,1)) = 1
        [Toggle]_RoughnessInvert ("_RoughnessInvert", Int) = 0
        _AO ("AO", Range(0, 1)) = 1
        _EmissivInt("_EmissivInt", Float) = 1
        _EmissivColor("_EmissivColor", Color) = (0,0,0,1)

        [Toggle(_ADDITIONALLIGHTS)] _AddLights("_AddLights", Float) = 1
        _LightInt("_LightInt", Range(0,1)) = 0.3
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Assets/JPinRender/KingPinCore/PbrData.hlsl"
        

        #pragma shader_feature _ADDITIONALLIGHTS
        // 接收阴影所需关键字
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS//接受阴影
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE//产生阴影
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS//额外光源阴影
        #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS//开启额外其它光源计算
        #pragma multi_compile _ _SHADOWS_SOFT//软阴影

        //C缓存区
        CBUFFER_START(UnityPerMaterial)
        float4 _DiffuseTex_ST;
        float4 _BaseColor;
        float4 _EmissivColor;
        float _NormalScale;
        float _Metallic;
        float _Roughness;
        float _EmissivInt;
        float _LightInt;
        float _NormalInvertG,_RoughnessInvert,_AO;
        CBUFFER_END

        struct Attributes
        {
            float4 positionOS : POSITION;//输入顶点
            float4 normalOS : NORMAL;//输入法线
            float2 texcoord : TEXCOORD0;//输入uv信息
            float4 tangentOS : TANGENT;//输入切线
        };

        struct Varyings
        {
            float2 uv : TEXCOORD0;//输出uv
            float4 positionCS : SV_POSITION;//齐次位置
            float3 positionWS : TEXCOORD1;//世界空间下顶点位置信息
            float3 normalWS : NORMAL;//世界空间下法线信息
            float3 tangentWS : TANGENT;//世界空间下切线信息
            float3 BtangentWS : TEXCOORD2;//世界空间下副切线信息
            float3 viewDirWS : TEXCOORD3;//世界空间下观察视角
        };

        TEXTURE2D(_DiffuseTex);
        SAMPLER(sampler_DiffuseTex);
        TEXTURE2D(_NormalTex);
        SAMPLER(sampler_NormalTex);
        TEXTURE2D(_MaskTex);
        SAMPLER(sampler_MaskTex);
        TEXTURE2D(_MetallicTex);
        SAMPLER(sampler_MetallicTex);
        TEXTURE2D(_AoTex);
        SAMPLER(sampler_AoTex);
        TEXTURE2D(_RoughnessTex);
        SAMPLER(sampler_RoughnessTex);


        ENDHLSL

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }


            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.uv = TRANSFORM_TEX(input.texcoord, _DiffuseTex);
                VertexPositionInputs  PositionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = PositionInputs.positionCS;//获取齐次空间位置
                output.positionWS = PositionInputs.positionWS;//获取世界空间位置信息

                VertexNormalInputs NormalInputs = GetVertexNormalInputs(input.normalOS.xyz,input.tangentOS);
                output.normalWS.xyz = NormalInputs.normalWS;//  获取世界空间下法线信息
                output.tangentWS.xyz = NormalInputs.tangentWS;//  获取世界空间下切线信息
                output.BtangentWS.xyz = NormalInputs.bitangentWS;//  获取世界空间下副切线信息

                // output.viewDirWS = GetCameraPositionWS() - PositionInputs.positionWS;//  相机世界位置 - 世界空间顶点位置
                output.viewDirWS = _WorldSpaceCameraPos - PositionInputs.positionWS;// 相机世界位置 - 世界空间顶点位置
                return output;
            }


            half4 frag(Varyings input) : SV_Target
            {
                // ============================================================================================================================================================
                half4 albedo = SAMPLE_TEXTURE2D(_DiffuseTex,sampler_DiffuseTex,input.uv);
                half4 normal = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,input.uv);
                normal.g = lerp(normal.g,1-normal.g,_NormalInvertG);// 切换不同平台法线
                half4 mask = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,input.uv);
                mask.g = lerp(mask.g, 1 - mask.g , _RoughnessInvert);// 粗糙度翻转

                half metallic = _Metallic * mask.r;
                half smoothness = _Roughness * mask.g;
                half ao = lerp(1,mask.b,_AO);
                half3 emissive = mask.a * _EmissivColor.rgb * _EmissivInt;
                half roughness = pow((1 - _Roughness),2);
                // ============================================================================================================================================================
                float3x3 TBN = {input.tangentWS.xyz, input.BtangentWS.xyz, input.normalWS.xyz}; // 矩阵
                TBN = transpose(TBN);
                float3 norTS = UnpackNormalScale(normal, _NormalScale);// 使用变量控制法线的强度
                norTS.z = sqrt(1 - saturate(dot(norTS.xy, norTS.xy))); // 规范化法线

                half3 N = NormalizeNormalPerPixel(mul(TBN, norTS));// 顶点法线和法线贴图融合 = 输出世界空间法线信息
                // ============================================================================================================================================================

                half3 PBRcolor = PBR(input.viewDirWS,N,input.positionWS,albedo.rgb,roughness,metallic,ao,smoothness,emissive);

			#ifdef _ADDITIONALLIGHTS
                int pixelLightCount = GetAdditionalLightsCount();
                for(int index = 0; index < pixelLightCount; index++)
                {
                
                    Light light = GetAdditionalLight(index,input.positionWS);
                    PBRcolor += PBRDirectLightResult(light,input.viewDirWS,N,albedo.rgb,roughness,metallic) * _LightInt;          // 多光源计算
                
                }

            #endif

                return half4(PBRcolor.rgb,1);

            }
            ENDHLSL
        }

        Pass
        {
		    Tags{ "LightMode" = "ShadowCaster" }
		    HLSLPROGRAM
		    #pragma vertex vertshadow
		    #pragma fragment fragshadow



		    Varyings vertshadow(Attributes v)
		    {
		        Varyings output;
                float3 posWS = TransformObjectToWorld(v.positionOS.xyz);//世界空间下顶点位置
                float3 norWS = TransformObjectToWorldNormal(v.normalOS.xyz);//世界空间下顶点位置
                Light MainLight = GetMainLight();//获取灯光

                output.positionCS = TransformWorldToHClip(ApplyShadowBias(posWS,norWS,MainLight.direction));//这里是公共结构体里调用就可以
                #if UNITY_REVERSED_Z
                output.positionCS.z - min(output.positionCS.z,output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                o.positionCS.z - max(o.positionCS.z,o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

		        return output;
		    }
		    float4 fragshadow(Varyings input) : SV_Target
		    {
		        float4 color;
		        color.xyz = float3(0.0, 0.0, 0.0);
		        return color;
		    }
		    ENDHLSL
		}
    }
}