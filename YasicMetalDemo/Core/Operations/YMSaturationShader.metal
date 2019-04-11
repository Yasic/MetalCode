//
//  YMSaturationShader.metal
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/11.
//  Copyright © 2019 yasic. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct YMStandardSingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};
constant half3 luminanceWeighting = half3(0.2125, 0.7154, 0.0721);

fragment half4 standardSaturationFragment(YMStandardSingleInputVertexIO fragmentInput [[stage_in]],
                                   texture2d<half> originalTexture [[texture(0)]],
                                   constant float &saturation [[buffer(0)]]
                                   )
{
    constexpr sampler quadSampler;
    half4 color = originalTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    // 获得当前点的亮度
    half luminance = dot(color.rgb, luminanceWeighting);
    // 进行亮度调节
    return half4(mix(half3(luminance), color.rgb, half(saturation)), color.a);
}
