//
//  YMBasicTool.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, YMBasicToolFillMode) {
    YMBasicToolFillModeDefault, // 默认模式，拉伸铺满
    YMBasicToolFillModeAspectFit, // 等比例完全展示
    YMBasicToolFillModeAspectFill, // 等比例铺满
};

@interface YMBasicTool : NSObject

@end

NS_ASSUME_NONNULL_END
