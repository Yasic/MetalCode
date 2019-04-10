//
//  YMLUTFilterOperation.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//
// LUT 滤镜操作

#import "YMBasicOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMLUTFilterOperation : YMBasicOperation

@property (nonatomic, assign) float intensity;

- (instancetype)initWithLUTImage:(UIImage *)lutImage;

@end

NS_ASSUME_NONNULL_END
