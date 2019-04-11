//
//  YMBrightnessShader.metal
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

fragment half4 standardBrightnessFragment(YMStandardSingleInputVertexIO fragmentInput [[stage_in]],
                                          texture2d<half> originalTexture [[texture(0)]],
                                          constant float &brightness [[buffer(0)]]
                                          )
{
    constexpr sampler quadSampler;
    half4 color = originalTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    return half4(color.rgb + brightness, color.a);
}

