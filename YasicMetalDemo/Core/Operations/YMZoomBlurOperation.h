//
//  YMZoomBlurOperation.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/11.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMBasicOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMZoomBlurOperation : YMBasicOperation

/**
 模糊程度
 */
@property (nonatomic, assign) float blurSize;

@end

NS_ASSUME_NONNULL_END
