//
//  TextRenderPage.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/3/5.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "TextRenderPage.h"
#import <CoreText/CoreText.h>
#import <Photos/Photos.h>
#import <malloc/malloc.h>
#import "GlyphInfo.h"
#import <Masonry.h>

@interface TextRenderPage ()

/**
 字体颜色
 */
@property (nonatomic, strong) NSString *fontName;

/**
 目标文案
 */
@property (nonatomic, strong) NSString *targetString;

/**
 线宽
 */
@property (nonatomic, assign) CGFloat lineWidth;

/**
 字体间距
 */
@property (nonatomic, assign) CGFloat glyphPadding;

/**
 字体大小
 */
@property (nonatomic, assign) CGFloat fontSize;

/**
 点大小
 */
@property (nonatomic, assign) CGFloat pointSize;

/**
 内容缩放
 */
@property (nonatomic, assign) CGFloat contextScale;

/**
 图片偏移
 */
@property (nonatomic, assign) CGFloat imageOffset;

/**
 字体缓存
 */
@property (nonatomic, strong) NSMutableArray *glyphCache;

/**
 字体宽度
 */
@property (nonatomic, assign) CGFloat totalWidth;

@end

@implementation TextRenderPage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"文字渲染";
    self.view.backgroundColor = [UIColor blackColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.fontName = @"Helvetica";
    self.targetString = @"Hello 世界";
    self.lineWidth = 1;
    self.glyphPadding = 2 + self.lineWidth;
    self.pointSize = 2;
    self.contextScale = 1.0;
    self.fontSize = 32;
    CTFontRef ctFont = [self createFont];
    [self createFontLayoutWithString:self.targetString withFont:self.fontName ctFont:ctFont];
}

/**
 创建目标风格的 CTFont

 @return CTFontRef 对象
 */
- (CTFontRef)createFont
{
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    NSString *family = self.fontName; // 10px sans-serif
    // 字体族
    attrs[(NSString *)kCTFontFamilyNameAttribute] = family;
    // 字体大小
    attrs[(NSString *)kCTFontSizeAttribute] = @(self.fontSize);
    
    CTFontSymbolicTraits symbolicTraits = 0;
    // 加粗
    symbolicTraits |= kCTFontBoldTrait;
    // 斜体
    symbolicTraits |= kCTFontItalicTrait;
    BOOL isItalic = NO;
    
    if (isItalic)
    {
        NSDictionary *traits = @{(NSString*)kCTFontSymbolicTrait:@(symbolicTraits)};
        attrs[(NSString*)kCTFontTraitsAttribute] = traits;
    }
    
    // 字体描述符
    CTFontDescriptorRef fontDesc = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)attrs);
    
    CGAffineTransform matrix;
    if (isItalic)
    {
        matrix = CGAffineTransformMake(1, 0, tan(15*M_PI/180), 1, 0, 0);
    }
    
    // 创建字体对象
    CTFontRef curFont = CTFontCreateWithFontDescriptor(fontDesc, 0, isItalic ? &matrix : NULL );
    return curFont;
}

- (void)createFontLayoutWithString:(NSString *)string withFont:(NSString *)font ctFont:(CTFontRef)ctFont
{
    NSInteger strIndex, n = [string length];
    wchar_t c;
    CGFloat offsetX = 0;
    for (strIndex = 0; strIndex < n; strIndex++) {
        c = [string characterAtIndex:strIndex];
        // 遍历字符串中每一个字符
        NSString *cs = [[NSString alloc] initWithBytes:&c length:sizeof(c) encoding:NSUTF32LittleEndianStringEncoding];
        NSAttributedString *attributeString = [[NSAttributedString alloc] initWithString:cs attributes:@{(id)kCTFontAttributeName: (__bridge id)ctFont}];
        // 创建一个 CTLine
        CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributeString);
        // 获取 line 中的 run 数组
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        // run 个数
        NSInteger runCount = CFArrayGetCount(runs);
        for (int runIndex = 0; runIndex < runCount; runIndex++) {
            // 获取单个 run
            CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runs, runIndex);
            // 获取run中的字符
            NSInteger runGlyphCount = CTRunGetGlyphCount(run);
            // 获取当前 run 的 CTFont 对象
            CTFontRef runFont = (CTFontRef)CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
            // 获取 run 中的字形数组，可能返回 NULL
            const CGGlyph *glyphs = CTRunGetGlyphsPtr(run);
            if (!glyphs) {
                CGGlyph *glyphsBuffer;
                size_t glyphsBufferSize = sizeof(CGGlyph) * runGlyphCount;
                if(malloc_size(glyphsBuffer) < glyphsBufferSize ) {
                    glyphsBuffer = (CGGlyph *)realloc(glyphsBuffer, glyphsBufferSize);
                }
                // range 传 (0, 0) 表示从头拷贝到尾
                CTRunGetGlyphs(run, CFRangeMake(0, 0), glyphsBuffer);
                glyphs = glyphsBuffer;
            }
            
            CGPoint *positionsBuffer;
            CGPoint *positions = (CGPoint *)CTRunGetPositionsPtr(run);
            if (!positions) {
                size_t positionsBufferSize = sizeof(CGPoint) * runGlyphCount;
                if (malloc_size(positionsBuffer) < positionsBufferSize) {
                    positionsBuffer = (CGPoint *)realloc(positionsBuffer, positionsBufferSize);
                }
                CTRunGetPositions(run, CFRangeMake(0, 0), positionsBuffer);
                positions = positionsBuffer;
            }
            
            for (int glyphIndex = 0; glyphIndex < runGlyphCount; glyphIndex++) {
                CGGlyph glyph = glyphs[glyphIndex];
                // 进行绘制
                GlyphInfo *info = [self drawGlyph:glyph withFont:runFont];
                info.charcode = c;
                info.xpos = positions[glyphIndex].x + offsetX;
                // 这里计算存疑
                offsetX += info.advanceX;
            }
        }
        CFRelease(line);
    }
    self.totalWidth = offsetX + 2 * self.glyphPadding;
}

- (GlyphInfo *)drawGlyph:(CGGlyph)glyph withFont:(CTFontRef)font
{
    GlyphInfo *info = [[GlyphInfo alloc] init];
    CGRect bbRect;
    // 字形的边界区域
    CTFontGetBoundingRectsForGlyphs(font, kCTFontOrientationDefault, &glyph, &bbRect, 1);
    // 字形宽高
    CGSize advance;
    CTFontGetAdvancesForGlyphs(font, kCTFontOrientationDefault, &glyph, &advance, 1);
    info.advanceX = advance.width;
    info.advanceY = advance.height;
    // Y偏移，边界减间距
    info.offsetY = floorf(bbRect.origin.y) - self.glyphPadding;
    // X偏移，边界减间距
    info.offsetX = floorf(bbRect.origin.x) - self.glyphPadding;
    // 整体宽度
    info.width = bbRect.size.width + self.glyphPadding * 2;
    // 整体高度
    info.height = bbRect.size.height + self.glyphPadding * 2;
    // 字节宽与高
    int pxWidth = floorf(info.width * self.contextScale/8 + 1) * 8;
    int pxHeight = floorf(info.height * self.contextScale/8 + 1) * 8;
    NSMutableData *pixels = [NSMutableData dataWithLength:pxHeight * pxWidth];
    // 创建灰度图
    CGContextRef context = CGBitmapContextCreate(pixels.mutableBytes, pxWidth, pxHeight, 8, pxWidth, NULL, kCGImageAlphaOnly);
    CGContextSetFontSize(context, self.pointSize);

    // 为什么不需要旋转了呢
//    CGContextTranslateCTM(context, 0.0, pxHeight);
//    CGContextScaleCTM(context, self.contextScale, - 1.0 * self.contextScale);
    
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetGrayStrokeColor(context, 1.0, 1.0);
    CGContextSetLineWidth(context, self.lineWidth);
    
    // 由于加入了 padding，需要调整起始点
    CGPoint p = CGPointMake(-info.offsetX, -info.offsetY);
    CTFontDrawGlyphs(font, &glyph, &p, 1, context);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    if (!imgRef) {
        return nil;
    }
    info.textureData = pixels;
    UIImage* img = [UIImage imageWithCGImage:imgRef];
    [self createImageView:img];
    CGImageRelease(imgRef);
    
    CGContextRelease(context);
    [self.glyphCache addObject:info];
    return info;
}

- (void)createImageView:(UIImage *)image
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.imageOffset, 0, 30, 30)];
    self.imageOffset += 30;
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
}

- (NSMutableArray *)glyphCache
{
    if (!_glyphCache) {
        _glyphCache = [NSMutableArray new];
    }
    return _glyphCache;
}

@end
