//
//  YMTextureInput.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMPipeline.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMTextureInput : NSObject<YMImageInput>

@property (nonatomic, strong) id<YMImageOutput> imageOutput;

- (instancetype)initWithUIImage:(UIImage *)image;

- (instancetype)initWithCGImage:(CGImageRef)cgImage;

- (void)updateUIImage:(UIImage *)image;

- (void)updateCGImage:(CGImageRef)cgImage;

- (void)processTexture;

@end

NS_ASSUME_NONNULL_END
