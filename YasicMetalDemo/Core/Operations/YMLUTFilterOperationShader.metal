//
//  YMLUTFilterOperationShader.metal
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/10.
//  Copyright © 2019 yasic. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct YMStandardSingleInputVertexIO
{
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

typedef struct
{
    float intensity;
} Constants;

fragment half4 standardLUTFragment(YMStandardSingleInputVertexIO fragmentInput [[stage_in]],
                                   texture2d<half> originalTexture [[texture(0)]],
                                   texture2d<half> lutTexture [[texture(1)]],
                                   constant Constants &constants [[buffer(0)]]
                                   )
{
    float width = originalTexture.get_width();
    float height = originalTexture.get_height();
    uint2 gridPos = uint2(fragmentInput.textureCoordinate.x * width ,fragmentInput.textureCoordinate.y * height);
    
    half4 color = originalTexture.read(gridPos);
    
    float blueColor = color.b * 63.0;
    
    int2 quad1;
    quad1.y = floor(floor(blueColor) / 8.0);
    quad1.x = floor(blueColor) - (quad1.y * 8.0);
    
    int2 quad2;
    quad2.y = floor(ceil(blueColor) / 8.0);
    quad2.x = ceil(blueColor) - (quad2.y * 8.0);
    
    half2 texPos1;
    texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.r);
    texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.g);
    
    half2 texPos2;
    texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.r);
    texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * color.g);
    
    half4 newColor1 = lutTexture.read(uint2(texPos1.x * 512,texPos1.y * 512));
    half4 newColor2 = lutTexture.read(uint2(texPos2.x * 512,texPos2.y * 512));
    
    half4 newColor = mix(newColor1, newColor2, half(fract(blueColor)));
    half4 finalColor = mix(color, half4(newColor.rgb, 1.0), half(constants.intensity));

    return finalColor;
}
