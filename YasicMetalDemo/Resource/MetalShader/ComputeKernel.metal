//
//  ComputeKernel.metal
//  YasicMetalDemo
//
//  Created by yasic on 2018/10/26.
//  Copyright © 2018年 yasic. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// e1 最小值，e2 最大值
float smootherstep(float e1, float e2, float x)
{
    // 归一化到 0 到 1 之间
    x = clamp((x - e1) / (e2 - e1), 0.0, 1.0);
    // 进行埃尔米特三阶插值
    return x * x * x * (x * (x * 6 - 15) + 10);
}

float dist(float2 point, float2 center, float radius)
{
    // 计算到圆心的距离，并与半径相减
    return length(point - center) - radius;
}

kernel void kernelComputeFunc(texture2d<float, access::write> output[[texture(0)]], uint2 gid [[thread_position_in_grid]])
{
    /** 埃尔米特插值抗锯齿 **/
    int width = output.get_width();
    int height = output.get_height();
    float2 uv = float2(gid) / float2(width, height);
    // 从 （0，1）转化到（-1，1）内
    uv = uv * 2.0 - 1.0;
    // 行星半径
    float planetRadius = 0.5;
    // 计算到图形中心距离是否小于 0.5
    float distance = dist(uv, float2(0), planetRadius);
    // 太阳光递减色值
    float4 sunColor = float4(1, 0.7, 0, 1) * (1 - distance);
    // 行星色值
    float4 planetColor = float4(0);
    // 根据像素点到图形中心距离获取 m，小于半径 0.005 则为 0，大于半径 0.005 则为 1。得到 m 值在下一步 mix 操作作为阈值判决值，进行线性插值
    float m = smootherstep(planetRadius - 0.005, planetRadius + 0.005, length(uv - float2(0)));
    float4 pixel = mix(planetColor, sunColor, m);
    output.write(pixel, gid);
    
    /** 普通颜色绘制，存在锯齿 **/
//    int width = output.get_width();
//    int height = output.get_height();
//    float2 uv = float2(gid) / float2(width, height);
//    // 从 （0，1）转化到（-1，1）内
//    uv = uv * 2.0 - 1.0;
//    float distToCircle = dist(uv, float2(0), 0.5);
//    bool inside = distToCircle < 0;
//    output.write(inside ? float4(0) : float4(1, 0.7, 0, 1) * (1 - distToCircle), gid);
}
