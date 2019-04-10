//
//  YMDLightDemoPage.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/10/28.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "YMDLightDemoPage.h"
#import <Masonry.h>
#import <MetalKit/MetalKit.h>

@interface YMDLightDemoPage ()<MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> mtlDevice;
@property (nonatomic, strong) MTKView *mtkView;

// 计算管道状态描述位
@property (nonatomic, strong) id <MTLComputePipelineState> computePipelineState;

// float 格式的计时器
@property (nonatomic, assign) float timer;
@property (nonatomic, strong) id<MTLBuffer> timerBuffer;

@property (nonatomic, strong) CADisplayLink *timerLink;

@end

@implementation YMDLightDemoPage

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    
    [self setMetalVariable];
}

- (void)setMetalVariable
{
    self.mtlDevice = MTLCreateSystemDefaultDevice();
    // 设置为 NO，以支持内核计算方法
    [self.mtkView setFramebufferOnly:NO];
    [self.view addSubview:self.mtkView];
    [_mtkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view);
        make.width.height.mas_equalTo([UIScreen mainScreen].bounds.size.width);
    }];
    
    id<MTLLibrary> library = [self.mtlDevice newDefaultLibrary];
    id<MTLFunction> computeFunc = [library newFunctionWithName:@"LightKernelFunc"];
    self.computePipelineState = [self.mtlDevice newComputePipelineStateWithFunction:computeFunc error:nil];
    
    self.timerBuffer = [self.mtlDevice newBufferWithLength:sizeof(float) options:0];
    
    self.timerLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateTimer)];
    [self.timerLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)drawInMTKView:(MTKView *)view
{
    [self writeTimerBuffer];
    id<CAMetalDrawable> drawable = [self.mtkView currentDrawable];
    id <MTLCommandBuffer> commandBuffer = [[self.mtlDevice newCommandQueue] commandBuffer];
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:self.computePipelineState];
    [computeEncoder setTexture:drawable.texture atIndex:0];
    [computeEncoder setBuffer:self.timerBuffer offset:0 atIndex:0];
    MTLSize threadGroupCount = MTLSizeMake(8, 8, 1);
    MTLSize threadGroup = MTLSizeMake(drawable.texture.width/threadGroupCount.width, drawable.texture.height/threadGroupCount.height, 1);
    [computeEncoder dispatchThreadgroups:threadGroup threadsPerThreadgroup:threadGroupCount];
    [computeEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)writeTimerBuffer
{
    void *content = self.timerBuffer.contents;
    memcpy(content, &_timer, sizeof(float));
}

- (void)updateTimer
{
    self.timer += 0.01;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

- (MTKView *)mtkView
{
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:self.view.frame device:self.mtlDevice];
        _mtkView.delegate = self;
    }
    return _mtkView;
}

@end
