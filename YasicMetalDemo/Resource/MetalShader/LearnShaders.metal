//
//  LearnShaders.metal
//  YasicMetalDemo
//
//  Created by yasic on 2018/10/24.
//  Copyright © 2018年 yasic. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    packed_float4 position;
    packed_float2 coords;
};

struct ColoredVertex
{
    float4 position [[position]];
    float2 coords;
};

struct Uniforms{
    float4x4 modelMatrix;
};

vertex ColoredVertex cube_image_vertex_func(constant Vertex *vertices [[buffer(0)]], const device Uniforms &uniforms [[buffer(1)]], uint vid [[vertex_id]]) {
    float4x4 mv_Matrix = uniforms.modelMatrix;
    Vertex VertexIn = vertices[vid];
    ColoredVertex temp;
    temp.position = VertexIn.position;
    temp.coords = VertexIn.coords;
    ColoredVertex VertexOut;
    VertexOut.position = mv_Matrix * temp.position;
    VertexOut.coords = temp.coords;
    return VertexOut;
}

fragment half4 cube_image_fragment_func(ColoredVertex vert [[stage_in]], texture2d<half> originalTexture [[texture(0)]]) {
    float width = originalTexture.get_width();
    float height = originalTexture.get_height();
    uint2 gridPos = uint2(vert.coords.x * width, vert.coords.y * height);
    half4 color = originalTexture.read(gridPos);
    return color;
}
