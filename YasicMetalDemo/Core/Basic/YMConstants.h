//
//  YMConstants.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/3.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMMetalContext.h"

NS_ASSUME_NONNULL_BEGIN

#define standardSingleInputVertex @"standardSingleInputVertex"
#define standardFragment @"standardFragment"

// 标准顶点坐标数组
FOUNDATION_EXPORT const float kStandardVertexs[];
FOUNDATION_EXPORT const int kStandardVertexsLength;
FOUNDATION_EXPORT const int kStandardVertexsComponentCount;

// 标准顶点索引数组
FOUNDATION_EXPORT const uint16_t kStandardIndices[];
FOUNDATION_EXPORT const int kStandardIndicesCount;

// 标准纹理坐标数组
FOUNDATION_EXPORT const float kStandardTextureCoordinates[];
FOUNDATION_EXPORT const int kStandardTextureCoordinatesLength;
FOUNDATION_EXPORT const int kStandardTextureCoordinatesComponentCount;

// 纹理输入个数
typedef NS_ENUM(NSUInteger, YMTextureInputCount) {
    YMTextureInputCountOne = 1,
    YMTextureInputCountTwo = 2
};

@interface YMConstants : NSObject

/**
 清屏色值
 */
@property (nonatomic, assign, class) MTLClearColor clearColor;

@end

NS_ASSUME_NONNULL_END
