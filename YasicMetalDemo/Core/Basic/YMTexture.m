//
//  YMTexture.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/3.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMTexture.h"
#import "YMMetalContext.h"

@interface YMTexture()

@end

@implementation YMTexture

- (instancetype)initWithTexture:(id<MTLTexture>)texture
{
    self = [self init];
    if (self){
        self.texture = texture;
    }
    return self;
}

- (instancetype)initWithWidth:(NSUInteger)width height:(NSUInteger)height
{
    self = [self init];
    if (self) {
        MTLTextureDescriptor *textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
        textureDesc.usage = MTLTextureUsageRenderTarget|MTLTextureUsageShaderWrite|MTLTextureUsageShaderRead;
        self.texture = [[YMMetalContext shareContext].device newTextureWithDescriptor:textureDesc];
    }
    return self;
}

@end
