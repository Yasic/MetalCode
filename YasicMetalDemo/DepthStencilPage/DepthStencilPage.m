//
//  DepthStencilPage.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/12/7.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "DepthStencilPage.h"
#import <Masonry.h>
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>

typedef struct Vertex {
    simd_float3 pixelPos;
    simd_packed_float4 color;
} Vertex;

static const Vertex vertex_data[] = {
    // 前左下角 0
    {.pixelPos = {-1, -1, 1}, .color = {1, 0, 0, 1}},
    // 前左上角 1
    {.pixelPos = {-1, 1, 1}, .color = {0, 1, 0, 1}},
    // 前右下角 2
    {.pixelPos = {1, -1, 1}, .color = {0, 0, 1, 1}},
    // 前右上角 3
    {.pixelPos = {1, 1, 1}, .color = {1, 1, 0, 1}},
    // 后左下角 4
    {.pixelPos = {-1, -1, -1}, .color = {1, 1, 1, 1}},
    // 后左上角 5
    {.pixelPos = {-1, 1, -1}, .color = {0, 1, 1, 1}},
    // 后右下角 6
    {.pixelPos = {1, -1, -1}, .color = {1, 1, 1, 1}},
    // 后右上角 7
    {.pixelPos = {1, 1, -1}, .color = {0, 0, 0, 1}}
};

static const uint16_t indices[] = {
    0, 1, 2, 1, 3, 2, // 前
    1, 5, 3, 3, 5, 7, // 上
    4, 1, 0, 5, 1, 4, // 左
    3, 7, 2, 2, 7, 6, // 右
    0, 2, 6, 6, 4, 0, // 下
    5, 4, 6, 7, 5, 6  // 后
};

/**
 转换矩阵结构体
 */
typedef struct Uniforms {
    GLKMatrix4 matrix;
} Uniforms;

@interface DepthStencilPage ()<MTKViewDelegate>

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
 深度检测状态
 */
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;

@property (nonatomic, strong) id<MTLTexture> depthTexture;

/**
 渲染命令队列
 */
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

/**
 顶点缓冲区
 */
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

/**
 顶点索引缓冲区
 */
@property (nonatomic, strong) id<MTLBuffer> indicesBuffer;

/**
 矩阵缓冲区
 */
@property (nonatomic, strong) id<MTLBuffer> matrixBuffer;

/**
 模型相关参数——位置
 */
@property (nonatomic, assign) CGFloat positionX;
@property (nonatomic, assign) CGFloat positionY;
@property (nonatomic, assign) CGFloat positionZ;

/**
 模型相关参数——旋转角度
 */
@property (nonatomic, assign) CGFloat rotationX;
@property (nonatomic, assign) CGFloat rotationY;
@property (nonatomic, assign) CGFloat rotationZ;

/**
 模型相关参数——缩放因子
 */
@property (nonatomic, assign) CGFloat scaleX;
@property (nonatomic, assign) CGFloat scaleY;
@property (nonatomic, assign) CGFloat scaleZ;

@property (nonatomic, strong) UIButton *viewChangeButton;
@property (nonatomic, strong) UIButton *depthChangeButton;
@property (nonatomic, assign) BOOL isLeftView;
@property (nonatomic, assign) BOOL depthEnable;

@end

@implementation DepthStencilPage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    [self p_makeMetalInitWork];
    [self p_loadVertexData];
    [self.view addSubview:self.mtkView];
    [self.view addSubview:self.viewChangeButton];
    [self.view addSubview:self.depthChangeButton];
    [self.mtkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.view);
        make.width.height.equalTo(self.view.mas_width);
    }];
    [self.viewChangeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(0.5);
        make.height.equalTo(@64);
    }];
    [self.depthChangeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(0.5);
        make.height.equalTo(@64);
    }];
    [self p_updateModelParameter];
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
    id<MTLFunction> vertextFunc = [library newFunctionWithName:@"ds_vertex_func"];
    id<MTLFunction> fragFunc = [library newFunctionWithName:@"ds_fragment_func"];
    renderPipeLineDescriptor.vertexFunction = vertextFunc;
    renderPipeLineDescriptor.fragmentFunction = fragFunc;
    renderPipeLineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    // 需要设置深度像素格式，默认的像素格式 MTLPixelFormatInvalid 与 MTKView 的格式不符合
    // For depth attachment, the render pipeline's pixelFormat does not match the framebuffer's pixelFormat
    renderPipeLineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[1].offset = sizeof(simd_float3);
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.layouts[0].stride = sizeof(Vertex);
    renderPipeLineDescriptor.vertexDescriptor = vertexDescriptor;
    
    self.pipelineState = [self.mtlDevice newRenderPipelineStateWithDescriptor:renderPipeLineDescriptor error:nil];
    
    MTLDepthStencilDescriptor *depthStencilDescriptor = [[MTLDepthStencilDescriptor alloc] init];
    // 较远的片段被舍弃
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    // 记录深度测试结果
    depthStencilDescriptor.depthWriteEnabled = YES;
    self.depthStencilState = [self.mtlDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    
    MTLTextureDescriptor *depthTexDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                            width:self.mtkView.drawableSize.width      height:self.mtkView.drawableSize.height mipmapped:NO];
    
    if (@available(iOS 9.0, *)) { // Texture at depthAttachment has usage (0x01) which doesn't specify MTLTextureUsageRenderTarget (0x04)
        depthTexDesc.usage = MTLTextureUsageRenderTarget;
    }
    self.depthTexture = [self.mtlDevice newTextureWithDescriptor:depthTexDesc];
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
 更新模型参数
 */
- (void)p_updateModelParameter
{
    self.rotationX += 0.5;
    self.rotationY += 0.5;
    self.rotationZ += 0.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self p_updateModelParameter];
    });
}

/**
 加载矩阵缓冲数据
 */
- (void)p_loadMatrix
{
    // 模型变换矩阵
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    modelMatrix = GLKMatrix4RotateZ(modelMatrix, GLKMathDegreesToRadians(self.rotationZ));
    modelMatrix = GLKMatrix4RotateY(modelMatrix, GLKMathDegreesToRadians(self.rotationY));
    modelMatrix = GLKMatrix4RotateX(modelMatrix, GLKMathDegreesToRadians(self.rotationX));
    modelMatrix = GLKMatrix4Scale(modelMatrix, self.scaleX, self.scaleY, self.scaleZ);
    GLKMatrix4 translation = GLKMatrix4Translate(GLKMatrix4Identity, self.positionX, self.positionY, self.positionZ);
    modelMatrix = GLKMatrix4Multiply(translation, modelMatrix);
    
    GLKVector3 eyePosition = GLKVector3Make(0, 0, 0.0f);
    GLKVector3 lookAtPosition = GLKVector3Make(0, 0, -5);
    GLKVector3 upVector = GLKVector3Make(0, 1, 0);
    // 旋转到左面观察两个立方体可看出两个立方体并不会相交，但是没有深度检测器的时候正面观察就会出现错位混叠现象
    if (self.isLeftView) {
        eyePosition = GLKVector3Make(-20, 0, -15);
        lookAtPosition = GLKVector3Make(0, 0, -15);
    }
    GLKMatrix4 cameraMatrix = GLKMatrix4MakeLookAt(eyePosition.x,
                                                      eyePosition.y,
                                                      eyePosition.z,
                                                      lookAtPosition.x,
                                                      lookAtPosition.y,
                                                      lookAtPosition.z,
                                                      upVector.x,
                                                      upVector.y,
                                                      upVector.z); // 模型变换矩阵
    GLKMatrix4 translationMatrix = GLKMatrix4Identity;
    translationMatrix = GLKMatrix4Multiply(cameraMatrix, modelMatrix);
    
    // 投影变换矩阵
    GLKMatrix4 perspectiveMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(75.0), self.mtkView.frame.size.width/self.mtkView.frame.size.height, 0.01, 1000.0);
    translationMatrix = GLKMatrix4Multiply(perspectiveMatrix, translationMatrix);
    
    Uniforms uniform = {.matrix = translationMatrix};
    
    self.matrixBuffer = [self.mtlDevice newBufferWithBytes:&uniform length:sizeof(Uniforms) options:0];
}

#pragma mark MTKView 代理方法

- (void)drawInMTKView:(MTKView *)view
{
    id<MTLDrawable> drawable = [view currentDrawable];
    MTLRenderPassDescriptor *renderPassDescriptor = [self.mtkView currentRenderPassDescriptor];
    if (!drawable || !renderPassDescriptor) {
        return;
    }
    // 为渲染流程状态加上深度缓冲区，用于写入深度测试结果值
    renderPassDescriptor.depthAttachment.texture = self.depthTexture;
    renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
    renderPassDescriptor.depthAttachment.clearDepth = 1.0;
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [commandEncoder setCullMode:MTLCullModeBack];
    [commandEncoder setFrontFacingWinding:MTLWindingClockwise];
    [commandEncoder setRenderPipelineState:self.pipelineState];
    if (self.depthEnable) { // 是否启用深度检测
        [commandEncoder setDepthStencilState:self.depthStencilState];
    }
    
    for (int x = 0; x < 2; x++) {
        // 绘制两个立方体，其中 x = 1 的立方体在 x = 0 的立方体前面，且体积较小，但是在未开启深度检测情况下，后绘制的立方体会覆盖先绘制的立方体的像素，出现错乱现象
        self.positionZ = (x == 0 ? -10:-20);
        self.scaleX = (x == 0 ? 1 : 5);
        self.scaleY = (x == 0 ? 1 : 5);
        self.scaleZ = (x == 0 ? 1 : 0.5);
        [self p_loadMatrix];
        [self p_drawCubeWithEncoder:commandEncoder];
    }
    
    [commandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)p_drawCubeWithEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
{
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:self.matrixBuffer offset:0 atIndex:1];
    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:sizeof(indices)/sizeof(uint16_t) indexType:MTLIndexTypeUInt16 indexBuffer:self.indicesBuffer indexBufferOffset:0];
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

- (UIButton *)viewChangeButton
{
    if (!_viewChangeButton) {
        _viewChangeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_viewChangeButton setTitle:@"切换到左侧视角" forState:UIControlStateNormal];
        [_viewChangeButton addTarget:self action:@selector(p_viewChangeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [_viewChangeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _viewChangeButton.layer.borderColor = [UIColor blueColor].CGColor;
        _viewChangeButton.layer.borderWidth = 2;
    }
    return _viewChangeButton;
}

- (UIButton *)depthChangeButton
{
    if (!_depthChangeButton) {
        _depthChangeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_depthChangeButton setTitle:@"深度检测关" forState:UIControlStateNormal];
        [_depthChangeButton addTarget:self action:@selector(p_depthChangeButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [_depthChangeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _depthChangeButton.layer.borderColor = [UIColor redColor].CGColor;
        _depthChangeButton.layer.borderWidth = 2;
    }
    return _depthChangeButton;
}

- (void)p_viewChangeButtonClicked
{
    self.isLeftView = !self.isLeftView;
    [self.viewChangeButton setTitle:self.isLeftView ? @"切换到正前方视角" : @"切换到左侧视角" forState:UIControlStateNormal];
}

- (void)p_depthChangeButtonClicked
{
    self.depthEnable = !self.depthEnable;
    [self.depthChangeButton setTitle:[NSString stringWithFormat:self.depthEnable ? @"深度检测开":@"深度检测关"] forState:UIControlStateNormal];
}

@end
