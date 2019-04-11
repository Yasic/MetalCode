//
//  YMZoomBlurOperation.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/11.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMZoomBlurOperation.h"

@implementation YMZoomBlurOperation

- (instancetype)init
{
    self = [self initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"" maxInputCount:1];
    return self;
}

- (instancetype)initWithVertexFunction:(NSString *)vertexFunc fragmentFunction:(NSString *)fragmentFunc maxInputCount:(NSInteger)maxInputCount
{
    self = [super initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"standardZoomBlurFragment" maxInputCount:1];
    self.blurSize = 0.0;
    return self;
}

- (void)setBlurSize:(float)blurSize
{
    blurSize = blurSize < 0 ? 0 : blurSize;
    blurSize = blurSize > 5 ? 5 : blurSize;
    _blurSize = blurSize;
    id<MTLBuffer> vertexBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:&blurSize length:sizeof(float) options:0];
    self.inputFragmentBuffers = [@[vertexBuffer] mutableCopy];
}

@end
