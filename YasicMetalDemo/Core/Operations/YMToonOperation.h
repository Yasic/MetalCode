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
 梯度阈值
 */
@property (nonatomic, assign) float magTol;

/**
 量化级别
 */
@property (nonatomic, assign) float quantize;

@end

NS_ASSUME_NONNULL_END
