//
//  YMToonOperation.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/11.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMToonOperation.h"

@implementation YMToonOperation

- (instancetype)init
{
    self = [self initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"" maxInputCount:1];
    return self;
}

- (instancetype)initWithVertexFunction:(NSString *)vertexFunc fragmentFunction:(NSString *)fragmentFunc maxInputCount:(NSInteger)maxInputCount
{
    self = [super initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"standardToonFragment" maxInputCount:1];
    self.magTol = 1.0;
    self.quantize = 20.0;
    return self;
}

- (void)recieveTexture:(YMTexture *)texture atIndex:(NSInteger)index
{
    struct Constants{
        float magTol;
        float quantize;
    } c = {self.magTol, self.quantize};
    id<MTLBuffer> vertexBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:&c length:sizeof(c) options:0];
    self.inputFragmentBuffers = [@[vertexBuffer] mutableCopy];
    [super recieveTexture:texture atIndex:index];
}

@end
