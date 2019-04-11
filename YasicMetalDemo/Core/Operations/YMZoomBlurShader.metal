//
//  YMZoomBlurShader.metal
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

fragment half4 standardZoomBlurFragment(YMStandardSingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]],
                                constant float &blurSize [[ buffer(0) ]])
{
    constexpr sampler quadSampler;
    
    // 纹理中心
    float2 blurCenter = float2(0.5, 0.5);
    float2 texCoord = fragmentInput.textureCoordinate;
    // 采样偏移值，根据blurSize变化
    float2 samplingOffset = 1.0 / 100.0 * (blurCenter - texCoord) * blurSize;
    // 权重采样求色值
    half4 fragmentColor = inputTexture.sample(quadSampler, texCoord) * 0.18;
    fragmentColor += inputTexture.sample(quadSampler, texCoord + samplingOffset) * 0.15;
    fragmentColor += inputTexture.sample(quadSampler, texCoord + (2.0 * samplingOffset)) *  0.12;
    fragmentColor += inputTexture.sample(quadSampler, texCoord + (3.0 * samplingOffset)) * 0.09;
    fragmentColor += inputTexture.sample(quadSampler, texCoord + (4.0 * samplingOffset)) * 0.05;
    fragmentColor += inputTexture.sample(quadSampler, texCoord - samplingOffset) * 0.15;
    fragmentColor += inputTexture.sample(quadSampler, texCoord - (2.0 * samplingOffset)) *  0.12;
    fragmentColor += inputTexture.sample(quadSampler, texCoord - (3.0 * samplingOffset)) * 0.09;
    fragmentColor += inputTexture.sample(quadSampler, texCoord - (4.0 * samplingOffset)) * 0.05;
    
    return fragmentColor;
}
