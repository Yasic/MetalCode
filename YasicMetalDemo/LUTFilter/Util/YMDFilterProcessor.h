//
//  YMDFilterProcessor.h
//  YasicMetalDemo
//
//  Created by yasic on 2018/9/27.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MTKView.h>
#import <Metal/Metal.h>

@interface YMDFilterProcessor : NSObject

@property (nonatomic, strong) id<MTLDevice> mtlDevice;
@property (nonatomic, strong) MTKView *mtlView;

- (void)loadLUTImage:(UIImage *)lutImage;
- (void)loadOriginalImage:(UIImage *)originalImage;
- (void)loadPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)renderImage;

@end
