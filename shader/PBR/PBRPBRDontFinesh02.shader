Shader "Shader/Role" 
{
    Properties 
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _ColorIntenstity ("ColorIntensity", Range(0,2)) = 1
        _MetallicTex ("MetallicTex", 2D) = "white" {}
        _MetallicIntensity ("MetallicIntensity", Range(0, 1)) = 0
        _RoughnessTex ("RoughnessTex", 2D) = "white" {}
        _RoughnessIntensity ("Roughness", Range(0, 1)) = 0.7
        _AOTex ("AOTex", 2D) = "white" {}
        _AOIntensity ("AOIntensity", Range(0, 1)) = 0
        _NormalTex ("NormalTex", 2D) = "bump" {}
        _EmissionTex ("EmissionTex", 2D) = "black" {}
        [HDR]_EmissionColor ("EmissionColor", Color) = (1,1,1,1)
        _EmissionColorIntensity ("EmissionColorIntensity", Range(0,2)) = 1
    }
    SubShader 
    {
        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            Cull Back
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float4 _Color;
            uniform float _ColorIntenstity;
            uniform sampler2D _MetallicTex; 
            uniform float _MetallicIntensity;
            uniform sampler2D _RoughnessTex; 
            uniform float _RoughnessIntensity;
            uniform sampler2D _AOTex; 
            uniform float _AOIntensity;
            uniform sampler2D _NormalTex;
            uniform sampler2D _EmissionTex;
            uniform float4 _EmissionColor;
            uniform float _EmissionColorIntensity;
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float4 worldPos : TEXCOORD3;
                float3 normalDir : TEXCOORD4;
                float3 tangentDir : TEXCOORD5;
                float3 bitangentDir : TEXCOORD6;
                LIGHTING_COORDS(7,8)
                UNITY_FOG_COORDS(9)
                #if defined(LIGHTMAP_ON) || defined(UNITY_SHOULD_SAMPLE_SH)
                    float4 ambientOrLightmapUV : TEXCOORD10;
                #endif
            };
            float3 DirectDiffuse(float NdotV,float NdotL,float LdotH,float gloss,float3 attenColor)
            {
                float3 result;
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotL);
                float nvPow5 = Pow5(1-NdotV);
                result = ((1 / UNITY_PI) * ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5)) * NdotL) * attenColor;
                return result;
            }
            float3 DirectSpecular(float NdotV,float NdotL,float NdotH,float LdotH,float metallic,float roughness,float attenColor)
            {
                float3 result;
                float D = GGXTerm(NdotH, roughness);
                float V = SmithJointGGXVisibilityTerm( NdotL, NdotV, roughness);
                float specularPBL = (D * V) * UNITY_PI;
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularPBL = sqrt(max(1e-4h, specularPBL));
                #endif
                specularPBL = max(0, specularPBL * NdotL);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularPBL = 0.0;
                #endif
                specularPBL *= any(metallic) ? 1.0 : 0.0;
                float3 DVF = attenColor * specularPBL * FresnelTerm(metallic, LdotH);
                result = DVF;
                return result;
            }
            v2f vert (a2v v)
            {
                v2f o = (v2f)0;
                o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
                o.uv1 = v.uv1;
                o.uv2 = v.uv2;
                #ifdef LIGHTMAP_ON
                    o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                    o.ambientOrLightmapUV.zw = 0;
                #endif
                #ifdef DYNAMICLIGHTMAP_ON
                    o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            half4 frag(v2f i) : COLOR
            {
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 normalTex = UnpackNormal(tex2D(_NormalTex,i.uv0));
                float3 normalDir = normalize(mul( normalTex, tangentTransform )); 
                float3 viewReflectDir = reflect( -viewDir, normalDir );
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 halfDir = normalize(viewDir + lightDir);
                float3 lightColor = _LightColor0.rgb;
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
                float4 mainTex = tex2D(_MainTex,i.uv0) * _Color * _ColorIntenstity;
                float3 metallicTex = tex2D(_MetallicTex,i.uv0) * _MetallicIntensity;
                float4 roughnessTex = tex2D(_RoughnessTex,i.uv0) * _RoughnessIntensity;
                float4 aoTex = tex2D(_AOTex,i.uv0) * _AOIntensity;
                float gloss = 1.0 - roughnessTex.r;
                float perceptualRoughness = roughnessTex.r;
                float roughness = perceptualRoughness * perceptualRoughness;
                float specPow = exp2( gloss * 10.0 + 1.0 );
                UnityLight light;
                #ifdef LIGHTMAP_OFF
                    light.color = lightColor;
                    light.dir = lightDir;
                    light.ndotl = LambertTerm (normalDir, light.dir);
                #else
                    light.color = half3(0.f, 0.f, 0.f);
                    light.ndotl = 0.0f;
                    light.dir = half3(0.f, 0.f, 0.f);
                #endif
                UnityGIInput d;
                d.light = light;
                d.worldPos = i.worldPos.xyz;
                d.worldViewDir = viewDir;
                d.atten = attenuation;
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                    d.ambient = 0;
                    d.lightmapUV = i.ambientOrLightmapUV;
                #else
                    d.ambient = i.ambientOrLightmapUV;
                #endif
                #if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
                    d.boxMin[0] = unity_SpecCube0_BoxMin;
                    d.boxMin[1] = unity_SpecCube1_BoxMin;
                #endif
                #if UNITY_SPECCUBE_BOX_PROJECTION
                    d.boxMax[0] = unity_SpecCube0_BoxMax;
                    d.boxMax[1] = unity_SpecCube1_BoxMax;
                    d.probePosition[0] = unity_SpecCube0_ProbePosition;
                    d.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif
                d.probeHDR[0] = unity_SpecCube0_HDR;
                d.probeHDR[1] = unity_SpecCube1_HDR;
                Unity_GlossyEnvironmentData g;
                g.roughness = 1.0 - gloss;
                g.reflUVW = viewReflectDir;
                UnityGI gi = UnityGlobalIllumination(d,aoTex,normalDir,g);
                lightDir = gi.light.dir;
                lightColor = gi.light.color;
                float NdotL = saturate(dot(normalDir, lightDir));
                float LdotH = saturate(dot(lightDir, halfDir));
                float specularMonochrome;
                float3 diffuseColor = mainTex.rgb; 
                diffuseColor = DiffuseAndSpecularFromMetallic(diffuseColor,metallicTex,metallicTex,specularMonochrome );
                specularMonochrome = 1.0 - specularMonochrome;
                float NdotV = abs(dot(normalDir,viewDir));
                float NdotH = saturate(dot(normalDir,halfDir));
                float VdotH = saturate(dot(viewDir,halfDir));
                float3 directSpecular = DirectSpecular(NdotV,NdotL,NdotH,LdotH,metallicTex,roughness,attenColor);
                half grazingTerm = saturate(gloss + specularMonochrome);
                half surfaceReduction;
                #ifdef UNITY_COLORSPACE_GAMMA
                    surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;
                #else
                    surfaceReduction = 1.0 / (roughness*roughness + 1.0);
                #endif
                float3 indirectSpecular = gi.indirect.specular * FresnelLerp (metallicTex, grazingTerm, NdotV) * surfaceReduction;
                float3 specular = (directSpecular + indirectSpecular);
                NdotL = max(0.0,dot(normalDir,lightDir));
                float3 directDiffuse = DirectDiffuse(NdotV,NdotL,LdotH,gloss,attenColor);
                float3 indirectDiffuse = gi.indirect.diffuse;
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
                float4 col;
                col.rgb = diffuse + specular * 0.5;
                col.rgb += tex2D(_EmissionTex,i.uv0).rgb * _EmissionColor.rgb * _EmissionColorIntensity;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}