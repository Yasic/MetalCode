//
//  VertexDescrpitorPage.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/12/6.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "VertexDescrpitorPage.h"
#import <Masonry.h>
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>

typedef struct Vertex {
    simd_float3 pos;
    simd_packed_float4 color;
} Vertex;

static const Vertex vertex_data[] = {
    // 左下角 0
    {.pos = {-1, -1, 0}, .color = {0, 1, 0, 1}},
    // 左上角 1
    {.pos = {-1, 1, 0}, .color = {1, 0, 0, 1}},
    // 右下角 2
    {.pos = {1, -1, 0}, .color = {0, 0, 1, 1}},
    // 右上角 3
    {.pos = {1, 1, 0}, .color = {1, 0, 1, 1}},
};

static const uint16_t indices[] = {
    0, 1, 2, 1, 3, 2
};

@interface VertexDescrpitorPage ()<MTKViewDelegate>

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

@end

@implementation VertexDescrpitorPage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    [self setMetalVariable];
}

- (void)setMetalVariable
{
    self.mtlDevice = MTLCreateSystemDefaultDevice();
    [self.view addSubview:self.mtkView];
    [self.mtkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    id<MTLLibrary> library = [self.mtlDevice newDefaultLibraryWithBundle:[NSBundle mainBundle] error:nil];
    id<MTLFunction> vertextFunc = [library newFunctionWithName:@"vd_vertex_func"];
    id<MTLFunction> fragFunc = [library newFunctionWithName:@"vd_fragment_func"];
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexFunction = vertextFunc;
    renderPipelineDescriptor.fragmentFunction = fragFunc;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // 顶点描述符，用于描述一个 vertexbuffer 中的数据结构，包括类型、尺寸、偏移等
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    // 这里计算偏移值时，选取类型要与struct定义一致
    vertexDescriptor.attributes[1].offset = sizeof(simd_float3);
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.layouts[0].stride = sizeof(Vertex); // 两个顶点数据间的距离
    renderPipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    self.pipelineState = [self.mtlDevice newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:nil];
    self.commandQueue = [self.mtlDevice newCommandQueue];
    
    self.vertexBuffer = [self.mtlDevice newBufferWithBytes:vertex_data length:sizeof(vertex_data) options:0];
    self.indicesBuffer = [self.mtlDevice newBufferWithBytes:indices length:sizeof(indices) options:0];
}

- (void)drawInMTKView:(MTKView *)view
{
    id<CAMetalDrawable> drawable = [self.mtkView currentDrawable];
    MTLRenderPassDescriptor *renderPassDescriptor = [self.mtkView currentRenderPassDescriptor]; // 获取当前的渲染描述符
    if (!drawable || !renderPassDescriptor) {
        return;
    }
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0); // 设置颜色附件的清除颜色
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear; // 用于避免渲染新的帧时附带上旧的内容
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer]; // 获取一个可用的命令 buffer
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; // 通过渲染描述符构建 encoder
    [commandEncoder setCullMode:MTLCullModeBack]; // 设置剔除背面
    [commandEncoder setFrontFacingWinding:MTLWindingClockwise]; // 设定按顺时针顺序绘制顶点的图元是朝前的
    [commandEncoder setRenderPipelineState:self.pipelineState];// 设置渲染管线状态位
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0]; // 设置顶点buffer
    // 按照顶点索引绘制三角图元
    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:sizeof(indices)/sizeof(uint16_t) indexType:MTLIndexTypeUInt16 indexBuffer:self.indicesBuffer indexBufferOffset:0];
    [commandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{}

- (MTKView *)mtkView
{
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:self.view.frame device:self.mtlDevice];
        _mtkView.delegate = self;
    }
    return _mtkView;
}

@end
