//
//  DepthStencilShader.metal
//  YasicMetalDemo
//
//  Created by yasic on 2018/12/8.
//  Copyright © 2018年 yasic. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct DSVertex {
    float4 position[[attribute(0)]];
    float4 color[[attribute(1)]];
};

struct DSTextureVertex
{
    float4 position [[position]]; // 告诉光栅器此数据为坐标信息
    float4 color;
};

struct UniformData
{
    float4x4 matrix;
};

vertex DSTextureVertex ds_vertex_func(const DSVertex vertexIn[[stage_in]], const device UniformData &udata [[buffer(1)]]) {
    DSTextureVertex out;
    float4x4 matrix = udata.matrix;
    out.position = matrix * vertexIn.position;
    out.color = vertexIn.color;
    return out;
}

fragment half4 ds_fragment_func(DSTextureVertex vertexIn[[stage_in]]) {
    return half4(vertexIn.color);
}
