//
//  VertexDescriptor.metal
//  YasicMetalDemo
//
//  Created by yasic on 2018/12/6.
//  Copyright © 2018年 yasic. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VDVertex {
    float4 position[[attribute(0)]]; // 不需要与 CPU 侧定义一致，Metal 自动转换
    float4 color[[attribute(1)]];
};

struct VDColoredVertex
{
    float4 position [[position]]; // 告诉光栅器此数据为坐标信息
    float4 color;
};

vertex VDColoredVertex vd_vertex_func(const VDVertex vertexIn[[stage_in]]) {
    VDColoredVertex out;
    out.position = vertexIn.position;
    out.color = vertexIn.color;
    return out;
}

fragment half4 vd_fragment_func(VDColoredVertex vertIn [[stage_in]]) {
    return half4(vertIn.color);
}
