/*--------------------------------------------SRC hlsl Include功能提交-------------------------------------------------
 * 灰度函数
 * 对比度函数
 * 饱和度函数
 * 灰度图转法线
 * 双重模糊函数
 * 计算缩放矩阵
 * 计算位移矩阵
 * 计算旋转矩阵
 * TRS矩阵
 --------------------------------------------------------------------------------------------------------------------*/
#define MAX_1(input) min(input, 1)
//---------------------------------------------------------------------------------
//计算扭曲
//
//Params:  source - 源图像
//
//Returns: 计算扭曲后的uv
void ComputeDistortionUV(inout float2 sourceUV, float distortionMap, float distortionX, float distortionY)
{
    sourceUV += distortionMap * float2(distortionX, distortionY);
}

float2 OffsetUV(float2 uv, float us, float vs, float time)
{
    return uv + float2(us, vs) * time;
}

//---------------------------------------------------------------------------------
//溶解
//
//Params:  source - 源图像
//
//Returns: 溶解
half ComputeDissolve(inout half4 source, half dissolveMask, half4 edgeColor, half edgeHDR, half blendMode, half rate, half edgeWidth, half soft, half offset)
{
    dissolveMask += rate;

    half alphaMask = saturate(dissolveMask / edgeWidth);
    half colorMask = 1 - alphaMask;

    half2 mask = half2(alphaMask, colorMask * edgeColor.a);
    mask /= half2(offset, 1 - offset);
    mask = MAX_1(mask / soft);

    source.rgb *= MAX_1(1 + blendMode - mask.y);
    source.rgb += edgeColor.rgb * edgeHDR * mask.y;

    source.a *= mask.x;

    return mask.x;
}
