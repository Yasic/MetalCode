//
//  YMDFilterProcessor.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/9/27.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "YMDFilterProcessor.h"
#import <MetalKit/MTKTextureLoader.h>

static const float vertexArrayData[] = {
    // 左下角 0
    -1.0, -1.0, 0.0, 1.0, 0, 1,
    // 左上角 1
    -1.0, 1.0, 0.0, 1.0, 0, 0,
    // 右下角 2
    1.0, -1.0, 0.0, 1.0, 1, 1,
    // 左上角 1
//    -1.0, 1.0, 0.0, 1.0, 0, 0,
    // 右上角 3
    1.0, 1.0, 0.0, 1.0, 1, 0,
    // 右下角 2
//    1.0, -1.0, 0.0, 1.0, 1, 1
};

// 顶点索引，Metal 按照此索引查询顶点数组对应下标，作为三角图元顶点
static const uint16_t indices[] = {
    0, 1, 2, 1, 3, 2
};

typedef struct {
    float animatedBy;
} Constants;

static Constants constants = {
    .animatedBy = 0
};

@interface YMDFilterProcessor()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer; // 顶点缓存
@property (nonatomic, strong) id<MTLBuffer> indicesBuffer; // 顶点索引缓存
@property (nonatomic, strong) id <MTLRenderPipelineState> pipelineState; // 渲染管道状态描述位
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@property (nonatomic, strong) id<MTLTexture> lutTexture;
@property (nonatomic, strong) id<MTLTexture> originalTexture;
@property (nonatomic, strong) dispatch_semaphore_t renderSemaphore;

@property (nonatomic, assign) CVMetalTextureCacheRef textureCache; // 纹理缓存
@property (nonatomic, strong) MTKTextureLoader *loader; // 纹理加载器

/**
 动画时间点
 */
@property (nonatomic, assign) double frameTime;

@end

@implementation YMDFilterProcessor

- (instancetype)init
{
    self = [super init];
    if (self){
        self.mtlDevice = MTLCreateSystemDefaultDevice(); // 获取 GPU 接口
        self.vertexBuffer = [self.mtlDevice newBufferWithBytes:vertexArrayData length:sizeof(vertexArrayData) options:0]; // 利用数组初始化一个顶点缓存，MTLResourceStorageModeShared 资源存储在CPU和GPU都可访问的系统存储器中
        self.indicesBuffer = [self.mtlDevice newBufferWithBytes:indices length:sizeof(indices) options:0]; // 存储索引缓存
        
        id<MTLLibrary> library = [self.mtlDevice newDefaultLibraryWithBundle:[NSBundle mainBundle] error:nil];
        id<MTLFunction> vertextFunc = [library newFunctionWithName:@"vertex_func"];
        id<MTLFunction> fragFunc = [library newFunctionWithName:@"fragment_func"]; //从 bundle 中获取顶点着色器和片段着色器
        
        MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
        pipelineDescriptor.vertexFunction = vertextFunc;
        pipelineDescriptor.fragmentFunction = fragFunc;
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm; //此设置配置像素格式，以便通过渲染管线的所有内容都符合相同的颜色分量顺序（在本例中为Blue(蓝色)，Green(绿色)，Red(红色)，Alpha(阿尔法)）以及尺寸（在这种情况下，8-bit(8位)颜色值变为 从0到255）
        self.pipelineState = [self.mtlDevice newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil]; // 初始化一个渲染管线状态描述位，相当于 CPU 和 GPU 之间建立的管道
        
        self.commandQueue = [self.mtlDevice newCommandQueue]; // 获取一个渲染队列，其中装载需要渲染的指令 MTLCommandBuffer
        
        self.renderSemaphore = dispatch_semaphore_create(1);
        
        CVMetalTextureCacheCreate(NULL, NULL, self.mtlDevice, NULL, &_textureCache); // 创建纹理缓存
        
        self.loader = [[MTKTextureLoader alloc] initWithDevice:self.mtlDevice];
    }
    return self;
}

- (void)renderImage
{
    dispatch_semaphore_wait(self.renderSemaphore, DISPATCH_TIME_FOREVER);
    id<CAMetalDrawable> drawable = [self.mtlView currentDrawable];
    if (!drawable || !self.originalTexture || !self.lutTexture) {
        dispatch_semaphore_signal(self.renderSemaphore);
        return;
    }
    MTLRenderPassDescriptor *renderPassDescriptor = [self.mtlView currentRenderPassDescriptor]; // 获取当前的渲染描述符
    if (!renderPassDescriptor) {
        dispatch_semaphore_signal(self.renderSemaphore);
        return;
    }
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0); // 设置颜色附件的清除颜色
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear; // 用于避免渲染新的帧时附带上旧的内容
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer]; // 获取一个可用的命令 buffer
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor]; // 通过渲染描述符构建 encoder
    [commandEncoder setCullMode:MTLCullModeBack]; // 设置剔除背面
    [commandEncoder setFrontFacingWinding:MTLWindingClockwise]; // 设定按顺时针顺序绘制顶点的图元是朝前的
    [commandEncoder setViewport:(MTLViewport){0.0, 0.0, self.mtlView.drawableSize.width, self.mtlView.drawableSize.height, -1.0, 1.0 }]; // 设置可视区域
    [commandEncoder setRenderPipelineState:self.pipelineState];// 设置渲染管线状态位
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0]; // 设置顶点buffer
    [commandEncoder setFragmentTexture:self.originalTexture atIndex:0]; // 设置纹理 0，即原图
    [commandEncoder setFragmentTexture:self.lutTexture atIndex:1]; // 设置纹理 1，即 LUT 图
    
    // 写入动画参数常量
    self.frameTime += 1/(double)(self.mtlView.preferredFramesPerSecond);
    constants.animatedBy = ABS(sin(self.frameTime)/2 + 0.5); // 变化范围 [0, 1]
    [commandEncoder setVertexBytes:&constants length:sizeof(Constants) atIndex:1];
    
    // 按照顶点索引绘制三角图元
    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:sizeof(indices)/sizeof(uint16_t) indexType:MTLIndexTypeUInt16 indexBuffer:self.indicesBuffer indexBufferOffset:0];
    [commandEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    dispatch_semaphore_signal(self.renderSemaphore);
}

- (void)loadLUTImage:(UIImage *)lutImage
{
    dispatch_semaphore_wait(self.renderSemaphore, DISPATCH_TIME_FOREVER);
    NSError* err;
    unsigned char *imageBytes = [self bitmapFromImage:lutImage];
    NSData *imageData = [self imageDataFromBitmap:imageBytes imageSize:CGSizeMake(CGImageGetWidth(lutImage.CGImage), CGImageGetHeight(lutImage.CGImage))];
    free(imageBytes);
    self.lutTexture = [self.loader newTextureWithData:imageData options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:&err]; // 生成 LUT 滤镜纹理
    dispatch_semaphore_signal(self.renderSemaphore);
}

- (void)loadOriginalImage:(UIImage *)originalImage
{
    unsigned char *imageBytes = [self bitmapFromImage:originalImage];
    NSData *imageData = [self imageDataFromBitmap:imageBytes imageSize:CGSizeMake(CGImageGetWidth(originalImage.CGImage), CGImageGetHeight(originalImage.CGImage))];
    free(imageBytes);
    NSError* err;
    self.originalTexture = [self.loader newTextureWithData:imageData options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:&err];
}

- (void)loadPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    dispatch_semaphore_wait(self.renderSemaphore, DISPATCH_TIME_FOREVER);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CVMetalTextureRef tmpTexture = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &tmpTexture); // 这里格式注意与传入视频的格式要一致
    id<MTLTexture> texture = nil;
    if (status == kCVReturnSuccess) {
        self.mtlView.drawableSize = CGSizeMake(width, height);
        texture = CVMetalTextureGetTexture(tmpTexture);
        self.originalTexture = texture;
        CFRelease(tmpTexture);
        dispatch_semaphore_signal(self.renderSemaphore);
    } else {
        dispatch_semaphore_signal(self.renderSemaphore);
        return;
    }
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

@end
