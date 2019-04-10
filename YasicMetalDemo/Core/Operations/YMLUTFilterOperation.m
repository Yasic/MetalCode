//
//  YMLUTFilterOperation.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMLUTFilterOperation.h"
#import "YMConstants.h"

typedef struct {
    float intensity;
} Constants;

Constants constants = {
    .intensity = 0.0
};

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
    constants.intensity = intensity;
    id<MTLBuffer> vertexBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:&constants length:sizeof(constants) options:0];
    self.inputFragmentBuffers = [@[vertexBuffer] mutableCopy];
}

@end
