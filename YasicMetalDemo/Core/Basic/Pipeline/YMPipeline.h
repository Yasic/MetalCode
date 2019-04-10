//
//  YMImageSource.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/4.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMTexture.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YMImageOutput;

@protocol YMImageInput <NSObject>

@property (nonatomic, strong) id<YMImageOutput> imageOutput;

/**
 更新输出端纹理

 @param texture 传递纹理
 */
- (void)updateOutputWithTexture:(YMTexture *)texture;

@end

@protocol YMImageOutput <NSObject>

/**
 接收源纹理，加载到output的0下标纹理

 @param texture 待接收的纹理
 */
- (void)recieveOriginalTexture:(YMTexture *)texture;

/**
 收到输入端纹理

 @param texture 纹理接收
 @param index 输出到poutput的对应下标纹理
 */
- (void)recieveTexture:(YMTexture *)texture atIndex:(NSInteger)index;

@end

@protocol YMImageProcessingOperation <NSObject, YMImageOutput, YMImageInput>

@end

NS_ASSUME_NONNULL_END
