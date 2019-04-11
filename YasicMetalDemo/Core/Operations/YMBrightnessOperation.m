//
//  YMBrightnessOperation.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/11.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMBrightnessOperation.h"

@implementation YMBrightnessOperation

- (instancetype)init
{
    self = [self initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"" maxInputCount:1];
    return self;
}

- (instancetype)initWithVertexFunction:(NSString *)vertexFunc fragmentFunction:(NSString *)fragmentFunc maxInputCount:(NSInteger)maxInputCount
{
    self = [super initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"standardBrightnessFragment" maxInputCount:1];
    self.brightness = 0.0;
    return self;
}

- (void)setBrightness:(float)brightness
{
    brightness = brightness < -1 ? -1 : brightness;
    brightness = brightness > 1 ? 1 : brightness;
    _brightness = brightness;
    id<MTLBuffer> vertexBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:&brightness length:sizeof(float) options:0];
    self.inputFragmentBuffers = [@[vertexBuffer] mutableCopy];
}

@end
