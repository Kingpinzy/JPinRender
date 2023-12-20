#ifndef URP_SHADER_INCLUDE_SHAPE_NOISE
#define URP_SHADER_INCLUDE_SHAPE_NOISE

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

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//---------------------------------------------------------------------------------
//计算灰度
//
//Params:  source - 源图像
//         contrast - 控制对比度强弱数值
//
//Returns: 返回计算过对比度的源图像数据
half3 CalculateGrayscale(half3 source){return source = 0.2125 * source.r + 0.7154 * source.g + 0.0721 * source.b;}
//---------------------------------------------------------------------------------
//对比度,通过调整contrast的值,计算源图像的对比度,指令数 3
//
//Params:  source - 源图像
//         contrast - 控制对比度强弱数值
//
//Returns: 返回计算过对比度的源图像数据
half3 GetContrast(half3 source, half contrast) {return lerp(0.5, source, contrast);}

//对比度,通过调整contrast的值,计算源图像的对比度,指令数 3
//
//Params:  source - 源图像
//         contrast - 控制对比度强弱数值
//
//Returns: 返回计算过对比度的源图像数据
float3 GetContrast(float3 source, float contrast) {return lerp(0.5, source, contrast);}
//---------------------------------------------------------------------------------
//饱和度,通过调整saturation的值,来计算源图像的饱和度,指令数 3
//
//Params:  source - 源图像
//         saturation - 控制饱和度强弱数值
//
//Returns: 返回计算过饱和度的源图像数据
half3 GetSaturation(half3 source, half saturation) {return lerp(CalculateGrayscale(source), source, saturation);}

//饱和度,通过调整saturation的值,来计算源图像的饱和度,指令数 3
//
//Params:  source - 源图像
//         saturationt - 控制饱和度强弱数值
//
//Returns: 返回计算过饱和度的源图像数据
float3 GetGetSaturation(float3 source, float saturation){return lerp(CalculateGrayscale(source), source, saturation);}

//---------------------------------------------------------------------------------------------------------------------
//灰度图转法线图,仅支持灰度图,指令数 19
//
//Params:  source - 灰度图
//         sampler_source 灰度图采样器
//         uv - 采样图的uv值
//         texelsize - 获取源图像中每个像素的大小
//         smoothness - 控制法线图光滑度
//         heightscale - 控制法线贴图的凹凸值,建议0.01或者-0.01
//
//Returns: 返回计算好的法线图
float3 GetNormalByGray(Texture2D source, SamplerState sampler_source, float2 uv, float4 texelsize, float smoothness, float heightscale)
{
    //在计算灰度图法线时,需要用到相邻像素之间的梯度信息
    float2 du = float2(texelsize.x * smoothness, 0); //计算x方向上的一个像素点
    float2 dv = float2(0, texelsize.y * smoothness); //计算y方向上的一个像素点
    float4 height = float4(
        SAMPLE_TEXTURE2D(source, sampler_source, uv - du).r, //x方向上向左偏移一个像素
        SAMPLE_TEXTURE2D(source, sampler_source, uv + du).r, //x方向上向左偏移一个像素
        SAMPLE_TEXTURE2D(source, sampler_source, uv - dv).r, //y方向上向下偏移一个像素
        SAMPLE_TEXTURE2D(source, sampler_source, uv + dv).r); //y方向上向上偏移一个像素

    float bumpU = height.y - height.x; //计算深度
    float bumpV = height.w - height.z; //计算深度
    float3 tangent_u = float3(du.x, 0, heightscale * bumpU); //x方向上的切线向量
    float3 tangent_v = float3(0, dv.y, heightscale * bumpV); //y方向上的切线向量
    float3 normal = normalize(cross(tangent_u, tangent_v)); //叉乘得到法线向量
    return normal;
}

//灰度图转法线图,仅支持灰度图,指令数 19
//
//Params:  source - 灰度图
//         sampler_source 灰度图采样器
//         uv - 采样图的uv值
//         texelsize - 获取源图像中每个像素的大小
//         smoothness - 控制法线图光滑度
//         heightscale - 控制法线贴图的凹凸值,建议0.01或者-0.01
//
//Returns: 返回计算好的法线图
half3 GetNormalByGray(Texture2D source, SamplerState sampler_source, half2 uv, half4 texelsize, half smoothness, half heightscale)
{
    //在计算灰度图法线时,需要用到相邻像素之间的梯度信息
    float2 du = float2(texelsize.x * smoothness, 0); //计算x方向上的一个像素点
    float2 dv = float2(0, texelsize.y * smoothness); //计算y方向上的一个像素点
    float4 height = float4(
        SAMPLE_TEXTURE2D(source, sampler_source, uv - du).r, //x方向上向左偏移一个像素
        SAMPLE_TEXTURE2D(source, sampler_source, uv + du).r, //x方向上向左偏移一个像素
        SAMPLE_TEXTURE2D(source, sampler_source, uv - dv).r, //y方向上向下偏移一个像素
        SAMPLE_TEXTURE2D(source, sampler_source, uv + dv).r); //y方向上向上偏移一个像素

    float bumpU = height.y - height.x; //计算深度
    float bumpV = height.w - height.z; //计算深度
    float3 tangent_u = float3(du.x, 0, heightscale * bumpU); //x方向上的切线向量
    float3 tangent_v = float3(0, dv.y, heightscale * bumpV); //y方向上的切线向量
    float3 normal = normalize(cross(tangent_u, tangent_v)); //叉乘得到法线向量
    return normal;
}

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//用于实现双重Kawase模糊效果,包含两个pass,该Pass"DownSample(下采样)"首先对输入的纹理进行了四次2x2的平均池化操作得到1/4大小的纹理后再次进行操作,得到1/16大小的纹理,这些纹理可以被用来接下来的"UpSample"上采样工作
//下采样的主要作用是将一张高分辨率的纹理图缩小到一个更低分辨率的图像,目的是为了减少图像的分辨率,出去高频的细节信息,达到一定的模糊效果,指令数 17
//
//Params:  source - 源图像
//         sampler_source 源图像采样器
//         uv - 源图像的uv值
//         uv01 - 记录该像素上方和右侧两个像素的纹理坐标
//         uv23 - 集路该像素左侧和下方两个像素的纹理坐标
//         texelsize - 获取源图像中每个像素的大小
//         offset - 控制采样过程中的偏移量
//
//Returns: 返回计算过后的下采样纹理数据
float4 GetDownSample(Texture2D source, SamplerState sampler_source, float4 texelsize, float2 uv, float4 uv01, float4 uv23, float offset)
{
    texelsize *= 0.5; //将图像缩小一倍

    //采样四个像素,计算周围相邻像素的纹理坐标
    uv01.xy = uv - texelsize.xy * float2(1 + offset, 1 + offset); //top right右上
    uv01.zw = uv + texelsize.xy * float2(1 + offset, 1 + offset); //bottom left左下
    uv23.xy = uv - float2(texelsize.x, -texelsize.y) * float2(1 + offset, 1 + offset); //top left 左上
    uv23.zw = uv + float2(texelsize.x, -texelsize.y) * float2(1 + offset, 1 + offset); //bottom right 右下

    //从主纹理中采样了当前像素周围四个像素的颜色值,并与初始值相加,得到最终颜色
    half4 sum = SAMPLE_TEXTURE2D(source, sampler_source, uv) * 4; //将1/16的纹理数据乘以四,以便在接下来的上采样中恢复其原始大小,得到正确的模糊效果
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv01.xy); //上方和右侧
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv01.zw); //左下方和右下方
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv23.xy); //左上方和左侧
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv23.zw); //右侧和右下方

    return sum * 0.125; //在池化操作后,当前像素周围2*2区域内每个相邻像素颜色*1/8才能得到正确的平均值.
}

//用于实现双重Kawase模糊效果,包含两个pass,该Pass"UpSample(上采样)"首先对"DownSample(下采样)"中得到的1/4大小的纹理进行了四次2*2的反池化操作,得到四个1*1大小的纹理,然后重复计算得到两个4*4大小的纹理,并与其他纹理进行加权平均,得到最终的模糊结果
//上采样的主要目的是为了恢复分辨率,从而使其更接近原始图像.可以有效消除上采样引入过程中图像的模糊和失真,并还原部分被删除的高频斜街信息,提高图像的质量和清晰度,指令数 36
//ps:其中下采样过程中1/16像素并没有直接被使用到,这些纹理信息在上采样pass中被恢复,逐渐放回原始大小并于其他纹理加权平均,虽然没有被直接使用,但任然承载对于模糊效果的贡献和影响.
//
//Params:  source - 源图像
//         sampler_source 源图像采样器
//         uv - 源图像的uv值
//         uv01 - 记录该像素上方和右侧两个像素的纹理坐标
//         uv23 - 记录该像素左侧和下方两个像素的纹理坐标
//         uv45 - 记录左上角和右下角两个像素的纹理坐标 
//         uv67 - 记录右上角和左下角两个像素的纹理坐标
//         texelsize - 获取源图像中每个像素的大小
//         offset - 控制采样过程中的偏移量
//
//Returns: 返回计算过后的上采样纹理数据
float4 GetUpSample(Texture2D source, SamplerState sampler_source, float4 texelsize, float2 uv, float4 uv01, float4 uv23, float4 uv45, float4 uv67, float offset)
{
    texelsize *= 0.5;
    float2 offset2 = float2(1 + offset, 1 + offset); //对采样位置进行偏移,为了像素点中心更好对准

    //计算八个偏移后的纹理坐标
    uv01.xy = uv + float2(-texelsize.x * 2, 0) * offset2;
    uv01.zw = uv + float2(-texelsize.x, texelsize.y) * offset2;
    uv23.xy = uv + float2(0, texelsize.y * 2) * offset2;
    uv23.zw = uv + texelsize.xy * offset2;
    uv45.xy = uv + float2(texelsize.x * 2, 0) * offset2;
    uv45.zw = uv + float2(texelsize.x, -texelsize.y) * offset2;
    uv67.xy = uv + float2(0, -texelsize.y * 2) * offset2;
    uv67.zw = uv - texelsize.xy * offset2;

    /*在双重模糊的下采样Pass中，每个像素的颜色值都被缩小为原来的1 / 4在这里的上采样Pass中，则需要使用多次反池化操作将缩小后的纹理逐渐放大回原始的大小，并与其他纹理进行加权平均
    首先初始化sum为0，然后分别从输入纹理 source中采样了当前像素周围八个像素的颜色值，并根据它们离当前像素的距离进行不同程度的加权平均，得到最终的颜色值
         - 第二行和第三行分别表示当前像素上方两个像素的颜色值，其中第三行乘以2的原因是因为该像素距离当前像素更远一些，对于模糊效果的贡献应该更小
         - 第四行和第五行分别表示当前像素左侧两个像素的颜色值，其中第五行同样乘以2
         - 第六行和第七行分别表示当前像素左上角和右下角两个像素的颜色值，同样乘以2
         - 第八行和第九行分别表示当前像素右上角和左下角两个像素的颜色值，同样乘以2
    在这里的加权平均中，不同像素的权重并不是相等的，而是根据其离当前像素的距离来计算的*/
    half4 sum = 0;
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv01.xy);
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv01.zw) * 2;
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv23.xy);
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv23.zw) * 2;
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv45.xy);
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv45.zw) * 2;
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv67.xy);
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv67.zw);
    return sum * 0.0833;
}

//用于实现双重Kawase模糊效果,包含两个pass,该Pass"DownSample(下采样)"首先对输入的纹理进行了四次2x2的平均池化操作得到1/4大小的纹理后再次进行操作,得到1/16大小的纹理,这些纹理可以被用来接下来的"UpSample"上的采样工作
//下采样的主要作用是将一张高分辨率的纹理图缩小到一个更低分辨率的图像,目的是为了减少图像的分辨率,出去高频的细节信息,达到一定的模糊效果,指令数 17
//
//Params:  source - 源图像
//         sampler_source 源图像采样器
//         uv - 源图像的uv值
//         uv01 - 记录该像素上方和右侧两个像素的纹理坐标
//         uv23 - 集路该像素左侧和下方两个像素的纹理坐标
//         texelsize - 获取源图像中每个像素的大小
//         offset - 控制采样过程中的偏移量
//
//Returns: 返回计算过后的下采样纹理数据
half4 GetDownSample(Texture2D source, SamplerState sampler_source, half4 texelsize, half2 uv, half4 uv01, half4 uv23, half offset)
{
    texelsize *= 0.5; //将图像缩小一倍

    //采样四个像素,计算周围相邻像素的纹理坐标
    uv01.xy = uv - texelsize.xy * float2(1 + offset, 1 + offset); //top right右上
    uv01.zw = uv + texelsize.xy * float2(1 + offset, 1 + offset); //bottom left左下
    uv23.xy = uv - float2(texelsize.x, -texelsize.y) * float2(1 + offset, 1 + offset); //top left 左上
    uv23.zw = uv + float2(texelsize.x, -texelsize.y) * float2(1 + offset, 1 + offset); //bottom right 右下

    //从主纹理中采样了当前像素周围四个像素的颜色值,并与初始值相加,得到最终颜色
    half4 sum = SAMPLE_TEXTURE2D(source, sampler_source, uv) * 4; //将1/16的纹理数据乘以四,以便在接下来的上采样中恢复其原始大小,得到正确的模糊效果
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv01.xy); //上方和右侧
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv01.zw); //左下方和右下方
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv23.xy); //左上方和左侧
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv23.zw); //右侧和右下方

    return sum * 0.125; //在池化操作后,当前像素周围2*2区域内每个相邻像素颜色*1/8才能得到正确的平均值.
}

//用于实现双重Kawase模糊效果,包含两个pass,该Pass"UpSample(上采样)"首先对"DownSample(下采样)"中得到的1/4大小的纹理进行了四次2*2的反池化操作,得到四个1*1大小的纹理,然后重复计算得到两个4*4大小的纹理,并与其他纹理进行加权平均,得到最终的模糊结果
//上采样的主要目的是为了恢复分辨率,从而使其更接近原始图像.可以有效消除上采样引入过程中图像的模糊和失真,并还原部分被删除的高频斜街信息,提高图像的质量和清晰度,指令数 36
//ps:其中下采样过程中1/16像素并没有直接被使用到,这些纹理信息在上采样pass中被恢复,逐渐放回原始大小并于其他纹理加权平均,虽然没有被直接使用,但任然承载对于模糊效果的贡献和影响.
//
//Params:  source - 源图像
//         sampler_source 源图像采样器
//         uv - 源图像的uv值
//         uv01 - 记录该像素上方和右侧两个像素的纹理坐标
//         uv23 - 集路该像素左侧和下方两个像素的纹理坐标
//         uv45 - 记录左上角和右下角两个像素的纹理坐标 
//         uv67 - 记录右上角和左下角两个像素的纹理坐标
//         texelsize - 获取源图像中每个像素的大小
//         offset - 控制采样过程中的偏移量
//
//Returns: 返回计算过后的上采样纹理数据
half4 GetUpSample(Texture2D source, SamplerState sampler_source, half4 texelsize, half2 uv, half4 uv01, half4 uv23, half4 uv45, half4 uv67, half offset)
{
    texelsize *= 0.5;
    float2 offset2 = float2(1 + offset, 1 + offset); //对采样位置进行偏移,为了像素点中心更好对准

    //计算八个偏移后的纹理坐标
    uv01.xy = uv + float2(-texelsize.x * 2, 0) * offset2;
    uv01.zw = uv + float2(-texelsize.x, texelsize.y) * offset2;
    uv23.xy = uv + float2(0, texelsize.y * 2) * offset2;
    uv23.zw = uv + texelsize.xy * offset2;
    uv45.xy = uv + float2(texelsize.x * 2, 0) * offset2;
    uv45.zw = uv + float2(texelsize.x, -texelsize.y) * offset2;
    uv67.xy = uv + float2(0, -texelsize.y * 2) * offset2;
    uv67.zw = uv - texelsize.xy * offset2;

    /*在双重模糊的下采样Pass中，每个像素的颜色值都被缩小为原来的1 / 4在这里的上采样Pass中，则需要使用多次反池化操作将缩小后的纹理逐渐放大回原始的大小，并与其他纹理进行加权平均
    首先初始化sum为0，然后分别从输入纹理 source 中采样了当前像素周围八个像素的颜色值，并根据它们离当前像素的距离进行不同程度的加权平均，得到最终的颜色值
        - 第二行和第三行分别表示当前像素上方两个像素的颜色值，其中第三行乘以2的原因是因为该像素距离当前像素更远一些，对于模糊效果的贡献应该更小
        - 第四行和第五行分别表示当前像素左侧两个像素的颜色值，其中第五行同样乘以2
        - 第六行和第七行分别表示当前像素左上角和右下角两个像素的颜色值，同样乘以2
        - 第八行和第九行分别表示当前像素右上角和左下角两个像素的颜色值，同样乘以2
    在这里的加权平均中，不同像素的权重并不是相等的，而是根据其离当前像素的距离来计算的*/
    half4 sum = 0;
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv01.xy);
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv01.zw) * 2;
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv23.xy);
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv23.zw) * 2;
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv45.xy);
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv45.zw) * 2;
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv67.xy);
    sum += SAMPLE_TEXTURE2D(source, sampler_source, uv67.zw);
    return sum * 0.0833;
}

//---------------------------------------------------------------------------------            
//位移矩阵函数,通过调整translational的值,实现x,y,z方向上的位移,指令数 5
//
//Params:  translational - 位移值
//
//Returns: 返回可以通过translational控制的位移矩阵,通过mul()将矩阵与顶点相乘,实现位移
float4x4 GetTranslational(float4 translational)
{
    return float4x4(1.0, 0.0, 0.0, translational.x,
                    0.0, 1.0, 0.0, translational.y,
                    0.0, 0.0, 1.0, translational.z,
                    0.0, 0.0, 0.0, 1.0);
}

//位移矩阵函数,通过调整translational的值,实现x,y,z方向上的位移,指令数 8
//
//Params:  translational - 位移值
//         positionos - 顶点数据
//
//Returns: 返回可以通过translational控制位移的顶点信息
float4 GetTranslational(float4 translational, float4 positionos)
{
    float4x4 t = float4x4(1.0, 0.0, 0.0, translational.x,
                          0.0, 1.0, 0.0, translational.y,
                          0.0, 0.0, 1.0, translational.z,
                          0.0, 0.0, 0.0, 1.0);
    return mul(t, positionos);
}

//位移矩阵函数,通过调整translational的值,实现x,y,z方向上的位移,指令数 5
//
//Params:  translational - 位移值
//
//Returns: 返回可以通过translational控制的位移矩阵,通过mul()将矩阵与顶点相乘,实现位移
half4x4 GetTranslational(half4 translational)
{
    return half4x4(1.0, 0.0, 0.0, translational.x,
                   0.0, 1.0, 0.0, translational.y,
                   0.0, 0.0, 1.0, translational.z,
                   0.0, 0.0, 0.0, 1.0);
}

//位移矩阵函数,通过调整translational的值,实现x,y,z方向上的位移,指令数 8
//
//Params:  translational - 位移值
//         positionos - 顶点数据
//
//Returns: 返回可以通过translational控制位移的顶点信息
half4 GetTranslational(half4 translational, float4 positionos)
{
    half4x4 t = half4x4(1.0, 0.0, 0.0, translational.x,
                        0.0, 1.0, 0.0, translational.y,
                        0.0, 0.0, 1.0, translational.z,
                        0.0, 0.0, 0.0, 1.0);
    return mul(t, positionos);
}

//---------------------------------------------------------------------------------            
//缩放矩阵函数,通过调整scal的值,实现缩放,指令数 1
//
//Params:  scal - 缩放值
//
//Returns: 返回可以通过scal控制的缩放矩阵,通过mul()将矩阵与顶点相乘,实现缩放
float4x4 GetScale(float4 scal)
{
    return float4x4(scal.x, 0.0, 0.0, 0.0,
                    0.0, scal.y, 0.0, 0.0,
                    0.0, 0.0, scal.z, 0.0,
                    0.0, 0.0, 0.0, 1.0);
}

//缩放矩阵函数,通过调整scal的值,实现缩放,指令数 1
//
//Params:  scal - 缩放值
//         positionOS - 顶点数据
//
//Returns: 返回可以通过scal控制缩放的顶点信息
float4 GetScale(float4 scal, float4 positionos)
{
    float4x4 s = float4x4(scal.x, 0.0, 0.0, 0.0,
                          0.0, scal.y, 0.0, 0.0,
                          0.0, 0.0, scal.z, 0.0,
                          0.0, 0.0, 0.0, 1.0);
    return mul(s, positionos);
}

//缩放矩阵函数,通过调整scal的值,实现缩放,指令数 1
//
//Params:  scal - 缩放值
//
//Returns: 返回可以通过scal控制的缩放矩阵,通过mul()将矩阵与顶点相乘,实现缩放
half4x4 GetScale(half4 scal)
{
    return half4x4(scal.x, 0.0, 0.0, 0.0,
                   0.0, scal.y, 0.0, 0.0,
                   0.0, 0.0, scal.z, 0.0,
                   0.0, 0.0, 0.0, 1.0);
}

//缩放矩阵函数,通过调整scal的值,实现缩放,指令数 1
//
//Params:  scal - 缩放值
//         positionOS - 顶点数据
//
//Returns: 返回可以通过scal控制缩放的顶点信息
half4 GetScale(half4 scal, float4 positionos)
{
    half4x4 s = half4x4(scal.x, 0.0, 0.0, 0.0,
                        0.0, scal.y, 0.0, 0.0,
                        0.0, 0.0, scal.z, 0.0,
                        0.0, 0.0, 0.0, 1.0);

    return mul(s, positionos);
}

//---------------------------------------------------------------------------------            
//旋转矩阵,通过rotation旋转值来控制顶点的旋转变化,指令数 21
//
//Params:  rotation - 旋转值
//
//Returns: 返回通过rotation控制旋转矩阵
float4x4 GetRotation(float4 rotation)
{
    float radX = radians(rotation.x); //欧拉角转换为弧度值
    float radY = radians(rotation.y);
    float radZ = radians(rotation.z);
    float sinX = sin(radX);
    float cosX = cos(radX);
    float sinY = sin(radY);
    float cosY = cos(radY);
    float sinZ = sin(radZ);
    float cosZ = cos(radZ);

    return float4x4(cosY * cosZ, -cosY * sinZ, sinY, 0.0,
                    cosX * sinZ + sinX * sinY * cosZ, cosX * cosZ - sinX * sinY * sinZ, -sinX * cosY, 0.0,
                    sinX * sinZ - cosX * sinY * cosZ, sinX * cosZ + cosX * sinY * sinZ, cosX * cosY, 0.0,
                    0.0, 0.0, 0.0, 1.0);
}

//旋转矩阵,通过rotation旋转值来控制顶点的旋转变化,指令数 18
//
//Params:  rotation - 旋转值
//         positionos - 顶点数据
//
//Returns: 返回通过rotation控制旋转的顶点信息
float4 GetRotation(float4 rotation, float4 positionos)
{
    float radX = radians(rotation.x); //欧拉角转换为弧度值
    float radY = radians(rotation.y);
    float radZ = radians(rotation.z);
    float sinX = sin(radX);
    float cosX = cos(radX);
    float sinY = sin(radY);
    float cosY = cos(radY);
    float sinZ = sin(radZ);
    float cosZ = cos(radZ);

    float4x4 r = float4x4(cosY * cosZ, -cosY * sinZ, sinY, 0.0,
                          cosX * sinZ + sinX * sinY * cosZ, cosX * cosZ - sinX * sinY * sinZ, -sinX * cosY, 0.0,
                          sinX * sinZ - cosX * sinY * cosZ, sinX * cosZ + cosX * sinY * sinZ, cosX * cosY, 0.0,
                          0.0, 0.0, 0.0, 1.0);

    return mul(r, positionos);
}

//旋转矩阵,通过rotation旋转值来控制顶点的旋转变化,指令数 21
//
//Params:  rotation - 旋转值
//
//Returns: 返回通过rotation控制旋转矩阵
half4x4 GetRotation(half4 rotation)
{
    float radX = radians(rotation.x); //欧拉角转换为弧度值
    float radY = radians(rotation.y);
    float radZ = radians(rotation.z);
    float sinX = sin(radX);
    float cosX = cos(radX);
    float sinY = sin(radY);
    float cosY = cos(radY);
    float sinZ = sin(radZ);
    float cosZ = cos(radZ);

    return half4x4(cosY * cosZ, -cosY * sinZ, sinY, 0.0,
                   cosX * sinZ + sinX * sinY * cosZ, cosX * cosZ - sinX * sinY * sinZ, -sinX * cosY, 0.0,
                   sinX * sinZ - cosX * sinY * cosZ, sinX * cosZ + cosX * sinY * sinZ, cosX * cosY, 0.0,
                   0.0, 0.0, 0.0, 1.0);
}

//旋转矩阵,通过rotation旋转值来控制顶点的旋转变化,指令数 18
//
//Params:  rotation - 旋转值
//         positionos - 顶点数据
//
//Returns: 返回通过rotation控制旋转的顶点信息
float4 GetRotation(half4 rotation, float4 positionos)
{
    float radX = radians(rotation.x); //欧拉角转换为弧度值
    float radY = radians(rotation.y);
    float radZ = radians(rotation.z);
    float sinX = sin(radX);
    float cosX = cos(radX);
    float sinY = sin(radY);
    float cosY = cos(radY);
    float sinZ = sin(radZ);
    float cosZ = cos(radZ);

    half4x4 r = half4x4(cosY * cosZ, -cosY * sinZ, sinY, 0.0,
                        cosX * sinZ + sinX * sinY * cosZ, cosX * cosZ - sinX * sinY * sinZ, -sinX * cosY, 0.0,
                        sinX * sinZ - cosX * sinY * cosZ, sinX * cosZ + cosX * sinY * sinZ, cosX * cosY, 0.0,
                        0.0, 0.0, 0.0, 1.0);

    return mul(r, positionos);
}

//---------------------------------------------------------------------------------
//TRS矩阵函数,由平移,旋转,缩放矩阵相乘得到,指令数 25
//
//Params:  scal - 缩放值
//         translational - 位移值
//         rotation - 旋转值
//
//Returns: 返回TRS矩阵
half4x4 GetTRS(half4 scal, half4 translational, half4 rotation)
{
    float radX = radians(rotation.x);
    float radY = radians(rotation.y);
    float radZ = radians(rotation.z);
    float sinX = sin(radX);
    float cosX = cos(radX);
    float sinY = sin(radY);
    float cosY = cos(radY);
    float sinZ = sin(radZ);
    float cosZ = cos(radZ);
    half4x4 trs = half4x4((cosY * cosZ) * scal.x, (-cosY * sinZ) * scal.y, sinY * scal.z, translational.x,
                                   (cosX * sinZ + sinX * sinY * cosZ) * scal.x, (cosX * cosZ - sinX * sinY * sinZ) * scal.y, (-sinX * cosY ) * scal.z, translational.y,
                                   (sinX * sinZ - cosX * sinY * cosZ) * scal.x, (sinX * cosZ + cosX * sinY * sinZ) * scal.y, (cosX * cosY) * scal.z, translational.z,
                                   0,0,0,1);


    return trs;
}

//TRS矩阵函数,由平移,旋转,缩放矩阵相乘得到,指令数 25
//
//Params:  scal - 缩放值
//         translational - 位移值
//         rotation - 旋转值
//
//Returns: 返回TRS矩阵
float4x4 GetTRS(float4 scal, float4 translational, float4 rotation)
{
    float radX = radians(rotation.x);
    float radY = radians(rotation.y);
    float radZ = radians(rotation.z);
    float sinX = sin(radX);
    float cosX = cos(radX);
    float sinY = sin(radY);
    float cosY = cos(radY);
    float sinZ = sin(radZ);
    float cosZ = cos(radZ);
    float4x4 trs = float4x4((cosY * cosZ) * scal.x, (-cosY * sinZ) * scal.y, sinY * scal.z, translational.x,
                                    (cosX * sinZ + sinX * sinY * cosZ) * scal.x, (cosX * cosZ - sinX * sinY * sinZ) * scal.y, (-sinX * cosY ) * scal.z, translational.y,
                                    (sinX * sinZ - cosX * sinY * cosZ) * scal.x, (sinX * cosZ + cosX * sinY * sinZ) * scal.y, (cosX * cosY) * scal.z, translational.z,
                                    0,0,0,1);

    return trs;
}


//TRS矩阵函数,由平移,旋转,缩放矩阵相乘得到,指令数 28
//
//Params:  scal - 缩放值
//         translational - 位移值
//         rotation - 旋转值
//         positionos - 顶点信息
//
//Returns: 返回经过TRS矩阵计算的顶点信息
half4 GetTRS(half4 scal, half4 translational, half4 rotation, half4 positionos)
{
    half radX = radians(rotation.x);
    half radY = radians(rotation.y);
    half radZ = radians(rotation.z);
    half sinX = sin(radX);
    half cosX = cos(radX);
    half sinY = sin(radY);
    half cosY = cos(radY);
    half sinZ = sin(radZ);
    half cosZ = cos(radZ);
    half4x4 trs = half4x4((cosY * cosZ) * scal.x, (-cosY * sinZ) * scal.y, sinY * scal.z, translational.x,
                                    (cosX * sinZ + sinX * sinY * cosZ) * scal.x, (cosX * cosZ - sinX * sinY * sinZ) * scal.y, (-sinX * cosY ) * scal.z, translational.y,
                                    (sinX * sinZ - cosX * sinY * cosZ) * scal.x, (sinX * cosZ + cosX * sinY * sinZ) * scal.y, (cosX * cosY) * scal.z, translational.z,
                                    0,0,0,1);

    return mul(trs, positionos);
}

//TRS矩阵函数,由平移,旋转,缩放矩阵相乘得到,指令数 28
//
//Params:  scal - 缩放值
//         translational - 位移值
//         rotation - 旋转值
//         positionos - 顶点信息
//
//Returns: 返回经过TRS矩阵计算的顶点信息
float4 GetTRS(float4 scal, float4 translational, float4 rotation, float4 positionos)
{
    float radX = radians(rotation.x);
    float radY = radians(rotation.y);
    float radZ = radians(rotation.z);
    float sinX = sin(radX);
    float cosX = cos(radX);
    float sinY = sin(radY);
    float cosY = cos(radY);
    float sinZ = sin(radZ);
    float cosZ = cos(radZ);
    float4x4 trs = float4x4((cosY * cosZ) * scal.x, (-cosY * sinZ) * scal.y, sinY * scal.z, translational.x,
                                    (cosX * sinZ + sinX * sinY * cosZ) * scal.x, (cosX * cosZ - sinX * sinY * sinZ) * scal.y, (-sinX * cosY ) * scal.z, translational.y,
                                    (sinX * sinZ - cosX * sinY * cosZ) * scal.x, (sinX * cosZ + cosX * sinY * sinZ) * scal.y, (cosX * cosY) * scal.z, translational.z,
                                    0,0,0,1);
    

    return mul(trs, positionos);
}

#endif
