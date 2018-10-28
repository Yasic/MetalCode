//
//  LightKernel.metal
//  YasicMetalDemo
//
//  Created by yasic on 2018/10/28.
//  Copyright © 2018年 yasic. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// e1 最小值，e2 最大值
float lightkernel_smootherstep(float e1, float e2, float x)
{
    // 归一化到 0 到 1 之间
    x = clamp((x - e1) / (e2 - e1), 0.0, 1.0);
    // 进行埃尔米特三阶插值
    return x * x * x * (x * (x * 6 - 15) + 10);
}

float lightkernel_dist(float2 point, float2 center, float radius)
{
    // 计算到圆心的距离，并与半径相减
    return length(point - center) - radius;
}

kernel void LightKernelFunc(texture2d<float, access::write> output[[texture(0)]], constant float &timer [[buffer(0)]], uint2 gid [[thread_position_in_grid]])
{
    int width = output.get_width();
    int height = output.get_height();
    float2 uv = float2(gid) / float2(width, height);
    // 从 （0，1）转化到（-1，1）内
    uv = uv * 2.0 - 1.0;
    // 行星半径
    float planetRadius = 0.5;
    // 黑色背景
    float4 blackground = float4(0);
    
    float planetZ = float(sqrt(planetRadius * planetRadius - uv.x * uv.x - uv.y * uv.y));
    planetZ /= planetRadius;
    // 归一化当前像素的法向量与光源法向量
    float3 normal = normalize(float3(uv.x, uv.y, planetZ));
    float3 source = normalize(float3(cos(timer), 0, sin(timer)));
    // 变量点积
    float light = dot(normal, source);
    // 行星色值
    float4 planetColor = float4(float3(light), 1);
    
    // 根据像素点到图形中心距离获取 m，小于半径 0.005 则为 0，大于半径 0.005 则为 1。得到 m 值在下一步 mix 操作作为阈值判决值，进行线性插值
    float m = lightkernel_smootherstep(planetRadius - 0.005, planetRadius + 0.005, length(uv - float2(0)));
    float4 pixel = mix(planetColor, blackground, m);
    output.write(pixel, gid);
}
