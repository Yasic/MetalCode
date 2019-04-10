//
//  SamplerDemoPage.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/12/7.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "SamplerDemoPage.h"
#import <Masonry.h>
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>

typedef struct Vertex {
    simd_float3 pixelPos;
    simd_packed_float2 texPos;
} Vertex;

static const Vertex vertex_data[] = {
    // 左下角 0
    {.pixelPos = {-1, -1, 0}, .texPos = {0, 1}},
    // 左上角 1
    {.pixelPos = {-1, 1, 0}, .texPos = {0, 0}},
    // 右下角 2
    {.pixelPos = {1, -1, 0}, .texPos = {1, 1}},
    // 右上角 3
    {.pixelPos = {1, 1, 0}, .texPos = {1, 0}},
};

static const uint16_t indices[] = {
    0, 1, 2, 1, 3, 2
};

@interface SamplerDemoPage ()<MTKViewDelegate>

/**
 GPU 设备对象
 */
@property (nonatomic, strong) id<MTLDevice> mtlDevice;

/**
 Metal 渲染图层
 */
@property (nonatomic, strong) MTKView *mtkView;

/**
 渲染管线状态
 */
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;

/**
 渲染命令队列
 */
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

/**
 顶点缓存
 */
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

/**
 顶点索引缓存
 */
@property (nonatomic, strong) id<MTLBuffer> indicesBuffer;

/**
 图形纹理
 */
@property (nonatomic, strong) id<MTLTexture> imageTexture;

/**
 采样器
 */
@property (nonatomic, strong) id<MTLSamplerState> samplerState;

@property (nonatomic, strong) UIButton *changeSamplerButton;
@property (nonatomic, assign) BOOL isLinearMode;

@end

@implementation SamplerDemoPage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    [self p_makeMetalInitWork];
    [self p_loadVertexData];
    [self p_loadTexture];
    [self p_setupSampler];
    [self.view addSubview:self.mtkView];
    [self.view addSubview:self.changeSamplerButton];
    [self.mtkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.view);
        make.width.height.equalTo(self.view.mas_width);
    }];
    [self.changeSamplerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.equalTo(@64);
    }];
}

/**
 Metal 初始化工作
 */
- (void)p_makeMetalInitWork
{
    self.mtlDevice = MTLCreateSystemDefaultDevice();
    self.commandQueue = [self.mtlDevice newCommandQueue];
    
    id<MTLLibrary> library = [self.mtlDevice newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *renderPipeLineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    id<MTLFunction> vertextFunc = [library newFunctionWithName:@"sd_vertex_func"];
    id<MTLFunction> fragFunc = [library newFunctionWithName:@"sd_fragment_func"];
    renderPipeLineDescriptor.vertexFunction = vertextFunc;
    renderPipeLineDescriptor.fragmentFunction = fragFunc;
    renderPipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].offset = sizeof(simd_float3);
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.layouts[0].stride = sizeof(Vertex);
    renderPipeLineDescriptor.vertexDescriptor = vertexDescriptor;
    
    self.pipelineState = [self.mtlDevice newRenderPipelineStateWithDescriptor:renderPipeLineDescriptor error:nil];
}

/**
 加载顶点数据
 */
- (void)p_loadVertexData
{
    self.vertexBuffer = [self.mtlDevice newBufferWithBytes:vertex_data length:sizeof(vertex_data) options:0];
    self.indicesBuffer = [self.mtlDevice newBufferWithBytes:indices length:sizeof(indices) options:0];
}

/**
 加载纹理数据
 */
- (void)p_loadTexture
{
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:self.mtlDevice];
    NSError* err;
    UIImage *targetImage = [UIImage imageNamed:@"qrcode"];
    unsigned char *imageBytes = [self bitmapFromImage:targetImage];
    NSData *imageData = [self imageDataFromBitmap:imageBytes imageSize:CGSizeMake(CGImageGetWidth(targetImage.CGImage), CGImageGetHeight(targetImage.CGImage))];
    free(imageBytes);
    self.imageTexture = [loader newTextureWithData:imageData options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:&err]; // 生成 LUT 滤镜纹理
}

/**
 设置采样器
 */
- (void)p_setupSampler
{
    MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
    // 缩小过滤器
    samplerDescriptor.minFilter = MDLMaterialTextureFilterModeLinear;
    // 放大过滤器，设置为 Linear 将会从临近像素进行混合得到当前像素值，也即插值操作，会导致二维码失真
    samplerDescriptor.magFilter = self.isLinearMode ? MDLMaterialTextureFilterModeLinear : MDLMaterialTextureFilterModeNearest;
    self.samplerState = [self.mtlDevice newSamplerStateWithDescriptor:samplerDescriptor];
}

- (unsigned char *)bitmapFromImage:(UIImage *)targetImage
{
    CGImageRef imageRef = targetImage.CGImage;
    
    NSUInteger iWidth = CGImageGetWidth(imageRef);
    NSUInteger iHeight = CGImageGetHeight(imageRef);
    NSUInteger iBytesPerPixel = 4;
    NSUInteger iBytesPerRow = iBytesPerPixel * iWidth;
    NSUInteger iBitsPerComponent = 8;
    unsigned char *imageBytes = malloc(iWidth * iHeight * iBytesPerPixel);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(imageBytes,
                                                 iWidth,
                                                 iHeight,
                                                 iBitsPerComponent,
                                                 iBytesPerRow,
                                                 colorspace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); // 转 BGRA 格式
    
    CGRect rect = CGRectMake(0, 0, iWidth, iHeight);
    CGContextDrawImage(context, rect, imageRef);
    CGColorSpaceRelease(colorspace);
    CGContextRelease(context);
    return imageBytes;
}

- (NSData *)imageDataFromBitmap:(unsigned char *)imageBytes imageSize:(CGSize)imageSize
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(imageBytes,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 8,
                                                 imageSize.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    NSData *imageData = UIImagePNGRepresentation(result);
    CGImageRelease(imageRef);
    return imageData;
}

#pragma mark MTKView 代理方法

- (void)drawInMTKView:(MTKView *)view
{
    [self p_setupSampler];
    id<MTLDrawable> drawable = [view currentDrawable];
    MTLRenderPassDescriptor *renderPassDescriptor = [self.mtkView currentRenderPassDescriptor];
    if (!drawable || !renderPassDescriptor) {
        return;
    }
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setCullMode:MTLCullModeBack];
    [commandEncoder setFrontFacingWinding:MTLWindingClockwise];
    [commandEncoder setRenderPipelineState:self.pipelineState];
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [commandEncoder setFragmentTexture:self.imageTexture atIndex:0];
    // 设置片段采样器
    [commandEncoder setFragmentSamplerState:self.samplerState atIndex:0];
    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:sizeof(indices)/sizeof(uint16_t) indexType:MTLIndexTypeUInt16 indexBuffer:self.indicesBuffer indexBufferOffset:0];
    [commandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

#pragma mark 懒加载

- (MTKView *)mtkView
{
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:self.view.frame device:self.mtlDevice];
        _mtkView.delegate = self;
    }
    return _mtkView;
}

- (UIButton *)changeSamplerButton
{
    if (!_changeSamplerButton) {
        _changeSamplerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_changeSamplerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_changeSamplerButton setTitle:@"线性插值已关闭" forState:UIControlStateNormal];
        [_changeSamplerButton addTarget:self action:@selector(p_changeSamplerButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeSamplerButton;
}

- (void)p_changeSamplerButtonClicked
{
    self.isLinearMode = !self.isLinearMode;
    [self.changeSamplerButton setTitle:self.isLinearMode ? @"线性插值已开启" : @"线性插值已关闭" forState:UIControlStateNormal];
}

@end
