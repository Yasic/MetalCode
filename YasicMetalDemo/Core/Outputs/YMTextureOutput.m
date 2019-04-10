//
//  YMTextureOutput.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/9.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMTextureOutput.h"
#import "YMMetalContext.h"
#import "YMConstants.h"
#import <MetalKit/MetalKit.h>
#import <Masonry.h>

@interface YMTextureOutput()<MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;

/**
 渲染管线状态符
 */
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;

@property (nonatomic, strong) dispatch_semaphore_t textureInputSemaphore;

@property (nonatomic, strong) YMTexture *inputTexture;

@end

@implementation YMTextureOutput

- (instancetype)init
{
    self = [self initWithFrame:CGRectZero];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        [self addViews];
        [self makeConstraints];
        id<MTLFunction> verFunc = [[YMMetalContext shareContext].defaultLibrary newFunctionWithName:standardSingleInputVertex];
        id<MTLFunction> fragFunc = [[YMMetalContext shareContext].defaultLibrary newFunctionWithName:standardFragment];
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

- (void)addViews
{
    [self addSubview:self.mtkView];
}

- (void)makeConstraints
{
    [self.mtkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (void)recieveOriginalTexture:(YMTexture *)texture
{
    self.inputTexture = texture;
    [self.mtkView draw];
}

- (void)recieveTexture:(YMTexture *)texture atIndex:(NSInteger)index
{
    [self recieveOriginalTexture:texture];
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    dispatch_semaphore_wait(self.textureInputSemaphore, DISPATCH_TIME_FOREVER);
    id<CAMetalDrawable> drawable = [self.mtkView currentDrawable];
    if (!drawable) {
        dispatch_semaphore_signal(self.textureInputSemaphore);
        return;
    }
    id <MTLCommandBuffer> commandBuffer = [[YMMetalContext shareContext].commandQueue commandBuffer];
    if (!self.inputTexture) {
        // 输出纹理
        MTLRenderPassDescriptor *renderPassDescriptor = [[MTLRenderPassDescriptor alloc] init];
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
        renderPassDescriptor.colorAttachments[0].clearColor = YMConstants.clearColor;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [commandEncoder setRenderPipelineState:self.renderPipelineState];
        [commandEncoder endEncoding];
    } else {
        [self renderTexture:drawable.texture commandBuffer:commandBuffer imageVerteices:kStandardVertexs imageVerteicesLength:kStandardVertexsLength textureCoordinates:kStandardTextureCoordinates textureCoordinatesLength:kStandardTextureCoordinatesLength vertextCount:4];
    }
    dispatch_semaphore_signal(self.textureInputSemaphore);
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)renderTexture:(id<MTLTexture>)outputTexture
        commandBuffer:(id<MTLCommandBuffer>)commandBuffer
       imageVerteices:(const float[])imageVerteices
  imageVerteicesLength:(NSInteger)imageVerteicesLength
   textureCoordinates:(const float[])textureCoordinates
textureCoordinatesLength:(NSInteger)textureCoordinatesLength
         vertextCount:(NSInteger)vertextCount
{
    id<MTLRenderCommandEncoder> commandEncoder = [self generateCommandEncoder:commandBuffer texture:outputTexture clearColor:YMConstants.clearColor];
    
    id<MTLBuffer> vertexBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:imageVerteices length:imageVerteicesLength * sizeof(float) options:0];
    [commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    
    id<MTLBuffer> textureCoordinateBuffer = [[YMMetalContext shareContext].device newBufferWithBytes:textureCoordinates length:textureCoordinatesLength * sizeof(float) options:0];
    [commandEncoder setVertexBuffer:textureCoordinateBuffer offset:0 atIndex:1];
    
    [commandEncoder setFragmentTexture:self.inputTexture.texture atIndex:0];
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

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

- (MTKView *)mtkView
{
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:self.frame device:[YMMetalContext shareContext].device];
        _mtkView.delegate = self;
//        _mtkView.paused = YES;
    }
    return _mtkView;
}

- (dispatch_semaphore_t)textureInputSemaphore
{
    if (!_textureInputSemaphore) {
        _textureInputSemaphore = dispatch_semaphore_create(1);
    }
    return _textureInputSemaphore;
}

@end
