//
//  YMTexture.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/3.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YMTexture : NSObject

@property (nonatomic, strong) id<MTLTexture> texture;

/**
 初始化方法

 @param texture 传入texture
 @return 返回实例
 */
- (instancetype)initWithTexture:(id<MTLTexture>)texture;

/**
 初始化一个空texture

 @param width texture 宽度
 @param height texture 高度
 @return 返回实例
 */
- (instancetype)initWithWidth:(NSUInteger)width height:(NSUInteger)height;

@end

NS_ASSUME_NONNULL_END
