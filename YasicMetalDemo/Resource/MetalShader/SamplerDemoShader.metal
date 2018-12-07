//
//  SamplerDemoShader.metal
//  YasicMetalDemo
//
//  Created by yasic on 2018/12/7.
//  Copyright © 2018年 yasic. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SDVertex {
    float4 position[[attribute(0)]]; // 不需要与 CPU 侧定义一致，Metal 自动转换
    float2 texture[[attribute(1)]];
};

struct SDTextureVertex
{
    float4 position [[position]]; // 告诉光栅器此数据为坐标信息
    float2 texture;
};

vertex SDTextureVertex sd_vertex_func(const SDVertex vertexIn[[stage_in]]) {
    SDTextureVertex out;
    out.position = vertexIn.position;
    out.texture = vertexIn.texture;
    return out;
}

fragment half4 sd_fragment_func(SDTextureVertex vertexIn[[stage_in]],
                                sampler sampler2d [[sampler(0)]],
                                texture2d<float> texture [[texture(0)]]) {
    float4 color = texture.sample(sampler2d, vertexIn.texture);
    return half4(color.r, color.g, color.b, 1);
}
