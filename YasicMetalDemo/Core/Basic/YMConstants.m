//
//  YMConstants.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/3.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMConstants.h"

// 标准顶点坐标数组
const float kStandardVertexs[] = {
    // 左下角 0
    -1.0, -1.0, 0.0, 1.0,
    // 左上角 1
    -1.0, 1.0, 0.0, 1.0,
    // 右下角 2
    1.0, -1.0, 0.0, 1.0,
    // 右上角 3
    1.0, 1.0, 0.0, 1.0
};

const int kStandardVertexsLength = 16;
const int kStandardVertexsComponentCount = 4;

// 顶点索引，Metal 按照此索引查询顶点数组对应下标，作为三角图元顶点
const uint16_t kStandardIndices[] = {
    0, 1, 2, 1, 3, 2
};

const int kStandardIndicesLength = 6;

// 标准纹理坐标数组
const float kStandardTextureCoordinates[] = {
    0.0, 1.0, // 左下
    0.0, 0.0, // 左上
    1.0, 1.0, // 右下
    1.0, 0.0 // 右上
};

const int kStandardTextureCoordinatesLength = 8;
const int kStandardTextureCoordinatesComponentCount = 2;

@implementation YMConstants

+ (void)setClearColor:(MTLClearColor)clearColor
{}

+ (MTLClearColor)clearColor
{
    return MTLClearColorMake(51.0/255.0, 153.0/255.0, 1.0, 1.0);
}

@end
