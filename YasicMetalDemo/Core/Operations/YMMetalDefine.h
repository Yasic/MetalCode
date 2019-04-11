//
//  YMMetalDefine.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/11.
//  Copyright © 2019 yasic. All rights reserved.
//

#ifndef YMMetalDefine_h
#define YMMetalDefine_h

using namespace metal;

struct YMStandardSingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

constant half3 luminanceWeighting = half3(0.2125, 0.7154, 0.0721);

#endif /* YMMetalDefine_h */
