//
//  YMBasicOperation.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/4.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMBasicOperation.h"
#import <MetalKit/MetalKit.h>
#import "YMMetalContext.h"
#import "YMConstants.h"

@interface YMBasicOperation()

/**
 渲染管线状态符
 */
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;

/**
 同步信号量
 */
@property (nonatomic, strong) dispatch_semaphore_t textureInputSemaphore;

/**
 输入纹理缓存
 */
@property (nonatomic, strong) NSMutableDictionary *inputTextureCache;

/**
 最大输入个数
 */
@property (nonatomic, assign) NSInteger maxInputCount;

@end

@implementation YMBasicOperation

- (instancetype)initWithVertexFunction:(NSString *)vertexFunc fragmentFunction:(NSString *)fragmentFunc
{
    self = [self initWithVertexFunction:vertexFunc fragmentFunction:fragmentFunc maxInputCount:1];
    return self;
}

- (instancetype)initWithVertexFunction:(NSString *)vertexFunc fragmentFunction:(NSString *)fragmentFunc maxInputCount:(NSInteger)maxInputCount
{
    self = [self init];
    if (self){
        self.maxInputCount = maxInputCount;
        id<MTLFunction> verFunc = [[YMMetalContext shareContext].defaultLibrary newFunctionWithName:vertexFunc];
        id<MTLFunction> fragFunc = [[YMMetalContext shareContext].defaultLibrary newFunctionWithName:fragmentFunc];
        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
        renderPipelineDescriptor.vertexFunction = verFunc;
        renderPipelineDescriptor.fragmentFunction = fragFunc;
        NSError *error = nil;
        self.renderPipelineState = [[YMMetalContext shareContext].device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
        if (error) {
            NSAssert(NO, @"创建 RenderPipelineState 出错！");
        }
    }
    return self;
}

- (void)recieveOriginalTexture:(YMTexture *)texture
{
    [self recieveTexture:texture atIndex:0];
}

- (void)recieveTexture:(YMTexture *)texture atIndex:(NSInteger)index
{
    dispatch_semaphore_wait(self.textureInputSemaphore, DISPATCH_TIME_FOREVER);
    self.inputTextureCache[@(index)] = texture;
    if (self.inputTextureCache.count < self.maxInputCount) {
        dispatch_semaphore_signal(self.textureInputSemaphore);
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [[YMMetalContext shareContext].commandQueue commandBuffer];
    if (!commandBuffer) {
        dispatch_semaphore_signal(self.textureInputSemaphore);
        return;
    }
    YMTexture *firstTexture = self.inputTextureCache[@(0)];
    NSUInteger outputWidth = firstTexture.texture.width;
    NSUInteger outputHeight = firstTexture.texture.height;
    YMTexture *outputTexture = [[YMTexture alloc] initWithWidth:outputWidth height:outputHeight];
    [self renderTexture:outputTexture commandBuffer:commandBuffer imageVerteices:kStandardVertexs imageVerteicesLength:kStandardVertexsLength textureCoordinates:kStandardTextureCoordinates textureCoordinatesLength:kStandardTextureCoordinatesLength vertextCount:4];
    [commandBuffer commit];
    [self updateOutputWithTexture:outputTexture];
    dispatch_semaphore_signal(self.textureInputSemaphore);
}

- (void)renderTexture:(YMTexture *)outputTexture
        commandBuffer:(id<MTLCommandBuffer>)commandBuffer
       imageVerteices:(const float[])imageVerteices
imageVerteicesLength:(NSInteger)imageVerteicesLength
   textureCoordinates:(const float[])textureCoordinates
textureCoordinatesLength:(NSInteger)textureCoordinatesLength
          vertextCount:(NSInteger)vertextCount
{
    id<MTLBuffer> vertexBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:imageVerteices length:imageVerteicesLength * sizeof(float) options:0];
    
    id<MTLRenderCommandEncoder> commandEncoder = [self generateCommandEncoder:commandBuffer texture:outputTexture.texture clearColor:[YMConstants clearColor]];
    [commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    
    id<MTLBuffer> textureCoordinateBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:textureCoordinates length:textureCoordinatesLength * sizeof(float) options:0];
    [commandEncoder setVertexBuffer:textureCoordinateBuffer offset:0 atIndex:1];
    
    [self.inputVertexBuffers enumerateObjectsUsingBlock:^(id<MTLBuffer>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [commandEncoder setVertexBuffer:obj offset:0 atIndex:2+idx];
    }];
    
    [self.inputFragmentBuffers enumerateObjectsUsingBlock:^(id<MTLBuffer>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [commandEncoder setFragmentBuffer:obj offset:0 atIndex:idx];
    }];
    
    for (NSInteger i = 0; i < self.inputTextureCache.count; i++) {
        YMTexture *currentTexture = self.inputTextureCache[@(i)];
        [commandEncoder setFragmentTexture:currentTexture.texture atIndex:i];
    }
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:vertextCount];
    [commandEncoder endEncoding];
}

- (id<MTLRenderCommandEncoder>)generateCommandEncoder:(id<MTLCommandBuffer>)commandBuffer texture:(id <MTLTexture>)outputTexture clearColor:(MTLClearColor)clearColor
{
    MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
    // 输出纹理
    renderPassDescriptor.colorAttachments[0].texture = outputTexture;
    renderPassDescriptor.colorAttachments[0].clearColor = clearColor;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setCullMode:MTLCullModeBack];
    // 顺时针向前
    [commandEncoder setFrontFacingWinding:MTLWindingClockwise];
    [commandEncoder setRenderPipelineState:self.renderPipelineState];
    return commandEncoder;
}

- (void)updateOutputWithTexture:(nonnull YMTexture *)texture
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.imageOutput) {
            return;
        }
        [self.imageOutput recieveTexture:texture atIndex:0];
    });
}

- (dispatch_semaphore_t)textureInputSemaphore
{
    if (!_textureInputSemaphore) {
        _textureInputSemaphore = dispatch_semaphore_create(1);
    }
    return _textureInputSemaphore;
}

- (NSMutableDictionary *)inputTextureCache
{
    if (!_inputTextureCache) {
        _inputTextureCache = [NSMutableDictionary dictionary];
    }
    return _inputTextureCache;
}

- (NSMutableArray<id<MTLBuffer>> *)inputVertexBuffers
{
    if (!_inputVertexBuffers) {
        _inputVertexBuffers = [NSMutableArray array];
    }
    return _inputVertexBuffers;
}

- (NSMutableArray<id<MTLBuffer>> *)inputFragmentBuffers
{
    if (!_inputFragmentBuffers) {
        _inputFragmentBuffers = [NSMutableArray array];
    }
    return _inputFragmentBuffers;
}

@end
