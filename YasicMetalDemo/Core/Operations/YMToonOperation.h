//
//  YMToonOperation.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/11.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMBasicOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMToonOperation : YMBasicOperation

/**
 梯度阈值，越小描边越明显
 */
@property (nonatomic, assign) float magTol;

/**
 量化级别，越小颜色数量越少
 */
@property (nonatomic, assign) float quantize;

@end

NS_ASSUME_NONNULL_END
