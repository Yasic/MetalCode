//
//  YMBasicTool.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMBasicTool.h"

@implementation YMBasicTool

+ (float *)transformVertices:(float[])vertices inputSize:(CGSize *)inputSize viewport:(CGSize)viewport
{
    
    return NULL;
}

+ (CGImageRef)transformTextureToImage:(id<MTLTexture>)targetTexture
{
    if (!targetTexture) {
        return nil;
    }
    NSInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = targetTexture.width * bytesPerPixel;
    unsigned char *imageBytes = malloc(targetTexture.width * targetTexture.height * bytesPerPixel);
    MTLRegion region = MTLRegionMake2D(0, 0, targetTexture.width, targetTexture.height);
    [targetTexture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    NSInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(imageBytes, targetTexture.width, targetTexture.height, bitsPerComponent, bytesPerRow, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipFirst);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return image;
}

+ (CGFloat)aspectRatioWithOriginalSize:(CGSize)originalSize scaleSize:(CGSize)scaleSize scalingMode:(YMBasicToolFillMode)fillMode
{
    CGFloat aspectWidth = scaleSize.width/originalSize.width;
    CGFloat aspectHeight = scaleSize.height/originalSize.height;
    CGFloat aspectRatio = 1.0;
    if (fillMode == YMBasicToolFillModeAspectFit) {
        // aspectFit 需要返回较小比例
        aspectRatio = MIN(aspectWidth, aspectHeight);
    } else {
        // aspectFill 需要返回较大比例
        aspectRatio = MAX(aspectWidth, aspectHeight);
    }
    return aspectRatio;
}

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)targetSize scalingMode:(YMBasicToolFillMode)fillMode
{
    CGSize originalSize = image.size;
    CGFloat aspectRatio = [YMBasicTool aspectRatioWithOriginalSize:originalSize scaleSize:targetSize scalingMode:fillMode];
    CGRect imageRect = CGRectZero;
    imageRect.size.width = originalSize.width * aspectRatio;
    imageRect.size.height = originalSize.height * aspectRatio;
    imageRect.origin.x = (targetSize.width - imageRect.size.width)/2.0;
    imageRect.origin.y = (targetSize.height - imageRect.size.height)/2.0;
    UIGraphicsBeginImageContext(targetSize);
    [image drawInRect:imageRect];
    UIImage *resImage = UIGraphicsGetImageFromCurrentImageContext();
    return resImage;
}

+ (CVPixelBufferRef)pixelBufferWithImage:(CGImageRef)image size:(CGSize)bufferSize
{
    CVPixelBufferRef buffer = nil;
    CVReturn res = CVPixelBufferCreate(kCFAllocatorDefault, bufferSize.width, bufferSize.height, kCVPixelFormatType_32BGRA, nil, &buffer);
    if (res != kCVReturnSuccess) {
        NSAssert(NO, @"创建pixelbuffer失败");
    }
    CVPixelBufferLockBaseAddress(buffer, 0);
    void *data = CVPixelBufferGetBaseAddress(buffer);
    CGContextRef context = CGBitmapContextCreate(data, bufferSize.width, bufferSize.height, 8, CVPixelBufferGetBytesPerRow(buffer), CGColorSpaceCreateDeviceRGB(), kCGImageByteOrder32Little|kCGImageAlphaNoneSkipFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, bufferSize.width, bufferSize.height), image);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return buffer;
}

+ (CGImageRef)imageFromCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    CGFloat width = CVPixelBufferGetWidth(pixelBuffer);
    CGFloat height = CVPixelBufferGetHeight(pixelBuffer);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, CVPixelBufferGetBytesPerRow(pixelBuffer), CGColorSpaceCreateDeviceRGB(), kCGImageByteOrder32Little|kCGImageAlphaNoneSkipFirst);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    return image;
}

@end
