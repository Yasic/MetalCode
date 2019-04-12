//
//  YMMetalContext.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/3.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import "YMConstants.h"
#import "YMTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMMetalContext : NSObject

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> defaultLibrary;
@property (nonatomic, strong) MTKTextureLoader *textureLoader;

/**
 推荐使用

 @return 返回全局的 Metal 上下文
 */
+ (YMMetalContext *)shareContext;

@end

NS_ASSUME_NONNULL_END
