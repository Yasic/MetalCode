//
//  YMBasicOperation.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/4.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YMPipeline.h"

NS_ASSUME_NONNULL_BEGIN

@interface YMBasicOperation : NSObject<YMImageProcessingOperation>

@property (nonatomic, strong) id<YMImageInput> imageInput;
@property (nonatomic, strong) id<YMImageOutput> imageOutput;

/**
 输入顶点数据buffer
 */
@property (nonatomic, strong) NSMutableArray<id<MTLBuffer>> *inputVertexBuffers;

/**
 输入片段数据buffer
 */
@property (nonatomic, strong) NSMutableArray<id<MTLBuffer>> *inputFragmentBuffers;

- (instancetype)initWithVertexFunction:(NSString *)vertexFunc fragmentFunction:(NSString *)fragmentFunc;
- (instancetype)initWithVertexFunction:(NSString *)vertexFunc fragmentFunction:(NSString *)fragmentFunc maxInputCount:(NSInteger)maxInputCount;

- (void)renderTexture:(YMTexture *)outputTexture
        commandBuffer:(id<MTLCommandBuffer>)commandBuffer
       imageVerteices:(const float[])imageVerteices
 imageVerteicesLength:(NSInteger)imageVerteicesLength
   textureCoordinates:(const float[])textureCoordinates
textureCoordinatesLength:(NSInteger)textureCoordinatesLength
         vertextCount:(NSInteger)vertextCount;

- (id<MTLRenderCommandEncoder>)generateCommandEncoder:(id<MTLCommandBuffer>)commandBuffer texture:(id <MTLTexture>)outputTexture clearColor:(MTLClearColor)clearColor;

@end

NS_ASSUME_NONNULL_END
