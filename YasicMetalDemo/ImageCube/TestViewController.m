//
//  TestViewController.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/10/24.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "TestViewController.h"
#import <Masonry.h>
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>

typedef struct {
    float x;
    float y;
    float z;
    float w;
} Position;

typedef struct {
    float r;
    float g;
    float b;
    float a;
} Color;

// 这里的纹理坐标类型要与着色器中的纹理坐标类型一致
typedef struct {
    float x;
    float y;
} TextureCoords;

typedef struct Vertex {
    Position pos;
    TextureCoords coords;
} Vertex;

typedef struct Uniforms {
    GLKMatrix4 modelMatrix;
} Uniforms;

// 每一个面均以顺时针顺序索引坐标
static const Vertex vertex_data[] = {
    // front
    {.pos = { 1, -1, 1.0,  1.0}, .coords = {1, 1}},
    {.pos = {-1, -1, 1.0,  1.0}, .coords = {0, 1}},
    {.pos = { 1, 1, 1.0,  1.0}, .coords = {1, 0}},
    {.pos = {-1, 1, 1.0,  1.0}, .coords = {0, 0}},
    
    // back
    {.pos = {-1,  1, -1.0,  1.0}, .coords = {1, 1}},
    {.pos = {-1, -1, -1.0,  1.0}, .coords = {0, 1}},
    {.pos = { 1,  1, -1.0,  1.0}, .coords = {1, 0}},
    {.pos = { 1, -1, -1.0,  1.0}, .coords = {0, 0}},
    
    // left
    {.pos = { -1, -1, 1.0,  1.0}, .coords = {1, 1}},
    {.pos = { -1,  -1, -1.0,  1.0}, .coords = {0, 1}},
    {.pos = { -1,  1, 1.0,  1.0},  .coords = {1, 0}},
    {.pos = { -1,  1, -1.0,  1.0},  .coords = {0, 0}},
    
    // right
    {.pos = {  1, -1,  -1.0,  1.0}, .coords = {1, 1}},
    {.pos = {  1,  -1,  1.0,  1.0}, .coords = {0, 1}},
    {.pos = {  1, 1,   -1.0,  1.0}, .coords = {1, 0}},
    {.pos = {  1, 1,    1.0,  1.0}, .coords = {0, 0}},
    
    // up
    {.pos = {  1,  1, 1.0,  1.0}, .coords = {1, 1}},
    {.pos = { -1,  1, 1.0,  1.0}, .coords = {0, 1}},
    {.pos = {  1, 1, -1.0,  1.0}, .coords = {1, 0}},
    {.pos = {  -1, 1, -1.0,  1.0}, .coords = {0, 0}},
    
    // bottom
    {.pos = {  1, -1, 1.0,  1.0}, .coords = {1, 1}},
    {.pos = {  1, -1, -1.0,  1.0}, .coords = {0, 1}},
    {.pos = { -1, -1, 1.0,  1.0}, .coords = {1, 0}},
    {.pos = { -1, -1, -1.0,  1.0}, .coords = {0, 0}},
};

@interface TestViewController ()<MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> mtlDevice;
@property (nonatomic, strong) MTKView *mtkView;

// 渲染管道状态描述位
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState;

// 顶点缓存
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;

// 图片纹理
@property (nonatomic, strong) id<MTLTexture> imageTexture;

@property (nonatomic, assign) CGFloat positionX;
@property (nonatomic, assign) CGFloat positionY;
@property (nonatomic, assign) CGFloat positionZ;

@property (nonatomic, assign) CGFloat rotationX;
@property (nonatomic, assign) CGFloat rotationY;
@property (nonatomic, assign) CGFloat rotationZ;

@property (nonatomic, assign) CGFloat scaleX;
@property (nonatomic, assign) CGFloat scaleY;
@property (nonatomic, assign) CGFloat scaleZ;

@property (nonatomic, assign) CGFloat diffScale;

@property (nonatomic, strong) CADisplayLink *updateValueLink;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    
    [self setMetalVariable];
    
    self.updateValueLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMatrix)];
    [self.updateValueLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    self.scaleX = 0.5;
    self.scaleY = 0.5;
    self.scaleZ = 0.5;
    self.diffScale = 0.01;
}

- (void)setMetalVariable
{
    self.mtlDevice = MTLCreateSystemDefaultDevice();
    [self.view addSubview:self.mtkView];
    [_mtkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    id<MTLLibrary> library = [self.mtlDevice newDefaultLibraryWithBundle:[NSBundle mainBundle] error:nil];
    id<MTLFunction> vertextFunc = [library newFunctionWithName:@"cube_image_vertex_func"];
    id<MTLFunction> fragFunc = [library newFunctionWithName:@"cube_image_fragment_func"];
    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderPipelineDescriptor.vertexFunction = vertextFunc;
    renderPipelineDescriptor.fragmentFunction = fragFunc;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.pipelineState = [self.mtlDevice newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:nil];
    
    // 加载缓冲数据
    self.vertexBuffer = [self.mtlDevice newBufferWithBytes:vertex_data length:sizeof(vertex_data) options:0];
    self.uniformBuffer = [self.mtlDevice newBufferWithLength:sizeof(Uniforms) options:0];
    // 加载纹理
    self.imageTexture = [[[MTKTextureLoader alloc] initWithDevice:self.mtlDevice] newTextureWithData:UIImageJPEGRepresentation([UIImage imageNamed:@"CubeImage"], 0.7) options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:nil];
    // 更新动画数据
    [self copyModelMatrix];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    MTLRenderPassDescriptor *renderPassDescriptor = [view currentRenderPassDescriptor];
    id <CAMetalDrawable> drawable = [view currentDrawable];
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1.0);
    id <MTLCommandBuffer> commandBuffer = [[self.mtlDevice newCommandQueue] commandBuffer];
    id <MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [encoder setRenderPipelineState:self.pipelineState];
    
    // 定义顺时针为正面
    [encoder setFrontFacingWinding:MTLWindingClockwise];
    // 裁剪背面
    [encoder setCullMode:MTLCullModeBack];
    // 设置顶点缓冲和 Uniform 缓冲
    [encoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [encoder setVertexBuffer:self.uniformBuffer offset:0 atIndex:1];
    // 设置纹理 0 图片
    [encoder setFragmentTexture:self.imageTexture atIndex:0];
    
    for (int i = 0; i < 6; i++) {
        // 遍历绘制六个面
        [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:i * 4 vertexCount:4];
    }
    [encoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)updateMatrix
{
    self.positionZ = -5.0;
    
    self.rotationX += 0.5;
    self.rotationZ += 0.5;
    self.rotationY += 0.5;
    
    self.scaleX += self.diffScale;
    self.scaleY += self.diffScale;
    self.scaleZ += self.diffScale;
    
    if (self.scaleX > 2) {
        self.diffScale = -0.01;
    }
    
    if (self.scaleX < 0.5) {
        self.diffScale = 0.01;
    }
    
    [self copyModelMatrix];
}

- (void)copyModelMatrix
{
    GLKMatrix4 translationMatrix = GLKMatrix4Identity;
    
    // 模型变换矩阵
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    modelMatrix = GLKMatrix4RotateZ(modelMatrix, GLKMathDegreesToRadians(self.rotationZ));
    modelMatrix = GLKMatrix4RotateY(modelMatrix, GLKMathDegreesToRadians(self.rotationY));
    modelMatrix = GLKMatrix4RotateX(modelMatrix, GLKMathDegreesToRadians(self.rotationX));
    modelMatrix = GLKMatrix4Scale(modelMatrix, self.scaleX, self.scaleY, self.scaleZ);
    
    // 视图变换矩阵
    GLKMatrix4 viewMatrix = GLKMatrix4Identity;
    viewMatrix = GLKMatrix4Translate(viewMatrix, self.positionX, self.positionY, self.positionZ);
    translationMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
    
    // 投影变换矩阵
    GLKMatrix4 perspectiveMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0), self.mtkView.frame.size.width/self.mtkView.frame.size.height, 0.01, 100.0);
    translationMatrix = GLKMatrix4Multiply(perspectiveMatrix, translationMatrix);
    
    void *content = self.uniformBuffer.contents;
    Uniforms uniform = {.modelMatrix = translationMatrix};
    memcpy(content, &uniform, sizeof(Uniforms));
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
