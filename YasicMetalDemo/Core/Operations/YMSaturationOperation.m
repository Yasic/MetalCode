//
//  YMSaturationOperation.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/11.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMSaturationOperation.h"
#import "YMMetalContext.h"

@implementation YMSaturationOperation

- (instancetype)init
{
    self = [self initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"standardSaturationFragment" maxInputCount:1];
    return self;
}

- (instancetype)initWithVertexFunction:(NSString *)vertexFunc fragmentFunction:(NSString *)fragmentFunc maxInputCount:(NSInteger)maxInputCount
{
    self = [super initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"standardSaturationFragment" maxInputCount:1];
    self.saturation = 1.0;
    return self;
}

- (void)setSaturation:(float)saturation
{
    saturation = saturation < 0 ? 0 : saturation;
    saturation = saturation > 2 ? 2 : saturation;
    _saturation = saturation;
    id<MTLBuffer> vertexBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:&saturation length:sizeof(float) options:0];
    self.inputFragmentBuffers = [@[vertexBuffer] mutableCopy];
}

@end
