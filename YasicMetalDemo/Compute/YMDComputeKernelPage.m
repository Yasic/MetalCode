//
//  YMDComputeKernelPage.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/10/26.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "YMDComputeKernelPage.h"
#import <Masonry.h>
#import <MetalKit/MetalKit.h>

@interface YMDComputeKernelPage ()<MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> mtlDevice;
@property (nonatomic, strong) MTKView *mtkView;

// 计算管道状态描述位
@property (nonatomic, strong) id <MTLComputePipelineState> computePipelineState;

@end

@implementation YMDComputeKernelPage

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
        make.bottom.right.equalTo(self.view);
//        make.width.height.mas_equalTo([UIScreen mainScreen].bounds.size.width);
    }];
    
    id<MTLLibrary> library = [self.mtlDevice newDefaultLibrary];
    id<MTLFunction> computeFunc = [library newFunctionWithName:@"kernelComputeFunc"];
    self.computePipelineState = [self.mtlDevice newComputePipelineStateWithFunction:computeFunc error:nil];
}

- (void)drawInMTKView:(MTKView *)view
{
    id<CAMetalDrawable> drawable = [self.mtkView currentDrawable];
    id <MTLCommandBuffer> commandBuffer = [[self.mtlDevice newCommandQueue] commandBuffer];
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setComputePipelineState:self.computePipelineState];
    [computeEncoder setTexture:drawable.texture atIndex:0];
    MTLSize threadGroupCount = MTLSizeMake(8, 8, 1);
    MTLSize threadGroup = MTLSizeMake(drawable.texture.width/threadGroupCount.width, drawable.texture.height/threadGroupCount.height, 1);
    [computeEncoder dispatchThreadgroups:threadGroup threadsPerThreadgroup:threadGroupCount];
    [computeEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
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
