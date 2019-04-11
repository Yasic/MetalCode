//
//  YMStandardShaderFunctions.metal
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/4.
//  Copyright © 2019 yasic. All rights reserved.
//

#include <metal_stdlib>
#import "YMMetalDefine.h"
using namespace metal;

vertex YMStandardSingleInputVertexIO standardSingleInputVertex(device packed_float4 *position [[buffer(0)]],
device packed_float2 *texturecoord [[buffer(1)]], uint vid [[vertex_id]])
{
    YMStandardSingleInputVertexIO output;
    output.position = float4(position[vid]);
    output.textureCoordinate = texturecoord[vid];
    return output;
}

fragment half4 standardFragment(YMStandardSingleInputVertexIO fragmentInput [[stage_in]],
                                   texture2d<half> inputTexture [[texture(0)]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    return color;
}
