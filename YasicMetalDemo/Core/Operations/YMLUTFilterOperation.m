//
//  YMLUTFilterOperation.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMLUTFilterOperation.h"

@interface YMLUTFilterOperation()

@property (nonatomic, strong) id<MTLTexture> lutTexture;

@end

@implementation YMLUTFilterOperation

- (instancetype)initWithLUTImage:(UIImage *)lutImage
{
    self = [self initWithVertexFunction:standardSingleInputVertex fragmentFunction:@"standardLUTFragment" maxInputCount:2];
    self.intensity = 0.0;
    [self loadLUTTexture:lutImage.CGImage];
    return self;
}

- (void)loadLUTTexture:(CGImageRef )lutImage
{
    NSError* err = nil;
    self.lutTexture = [[YMMetalContext shareContext].textureLoader newTextureWithCGImage:lutImage options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:&err];
    YMTexture *texture = [[YMTexture alloc] initWithTexture:self.lutTexture];
    [self recieveTexture:texture atIndex:1];
}

- (void)setIntensity:(float)intensity
{
    intensity = intensity < 0 ? 0 : intensity;
    intensity = intensity > 1.0 ? 1.0 : intensity;
    _intensity = intensity;
    id<MTLBuffer> vertexBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:&intensity length:sizeof(float) options:0];
    self.inputFragmentBuffers = [@[vertexBuffer] mutableCopy];
}

@end
