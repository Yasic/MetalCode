//
//  YMBasicTool.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YMTexture.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YMBasicToolFillMode) {
    YMBasicToolFillModeDefault, // 默认模式，拉伸铺满
    YMBasicToolFillModeAspectFit, // 等比例完全展示
    YMBasicToolFillModeAspectFill, // 等比例铺满
};

@interface YMBasicTool : NSObject

+ (CGImageRef)transformTextureToImage:(id<MTLTexture>)targetTexture;

/**
 将图片转化成特定尺寸

 @param targetSize 目标尺寸
 @param fillMode 展示模式，fit or fill
 @return 返回转化后的图片
 */
+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)targetSize scalingMode:(YMBasicToolFillMode)fillMode;

/**
 将CGImage转化为CVPixelBuffer

 @param image 图片对象
 @param bufferSize 转化尺寸
 @return 返回CVPixelBuffer
 */
+ (CVPixelBufferRef)pixelBufferWithImage:(CGImageRef)image size:(CGSize)bufferSize;

/**
 由CVPixelBuffer获得CGImage

 @param pixelBuffer CVPixelBuffer 对象
 @return cgimage 对象
 */
+ (CGImageRef)imageFromCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
