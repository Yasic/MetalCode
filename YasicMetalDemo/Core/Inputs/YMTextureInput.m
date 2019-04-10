//
//  YMTextureInput.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMTextureInput.h"
#import "YMMetalContext.h"
#import <MetalKit/MetalKit.h>

@interface YMTextureInput()

@property (nonatomic, assign) CGImageRef cgImage;
@property (nonatomic, strong) YMTexture *inputTexture;

@end

@implementation YMTextureInput

- (instancetype)initWithUIImage:(UIImage *)image
{
    self = [self initWithCGImage:image.CGImage];
    return self;
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage
{
    self = [super init];
    if (self){
        self.cgImage = cgImage;
    }
    return self;
}

- (void)updateUIImage:(UIImage *)image
{
    [self updateCGImage:image.CGImage];
}

- (void)updateCGImage:(CGImageRef)cgImage
{
    self.cgImage = cgImage;
    self.inputTexture = nil;
    [self processTexture];
}

- (void)processTexture
{
    if (self.inputTexture) {
        [self updateOutputWithTexture:self.inputTexture];
        return;
    }
    NSError* err = nil;
    id<MTLTexture> texture = [[YMMetalContext shareContext].textureLoader newTextureWithCGImage:self.cgImage options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:&err];
    self.inputTexture = [[YMTexture alloc] initWithTexture:texture];
    [self updateOutputWithTexture:self.inputTexture];
}

- (void)updateOutputWithTexture:(YMTexture *)texture
{
    if (!self.imageOutput) {
        return;
    }
    [self.imageOutput recieveTexture:texture atIndex:0];
}

@end
