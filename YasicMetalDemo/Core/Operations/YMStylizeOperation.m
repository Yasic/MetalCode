//
//  YMStylizeOperation.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/12.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMStylizeOperation.h"
#import "YMMetalContext.h"
#import "mosaic.h"
#import "YMBasicTool.h"
#import <CoreML/MLFeatureProvider.h>

@interface StyleTextureInput : NSObject <MLFeatureProvider>

@property (nonatomic, assign) CVPixelBufferRef input;

@end

@implementation StyleTextureInput

- (instancetype)initWithInput:(CVPixelBufferRef)input
{
    self = [self init];
    if (self) {
        self.input = input;
    }
    return self;
}

- (NSSet<NSString *> *)featureNames
{
    // 由 mlmodel 确定
    return [NSSet setWithArray:@[@"inputImage"]];
}

- (MLFeatureValue *)featureValueForName:(NSString *)featureName
API_AVAILABLE(ios(11.0)){
    if ([featureName isEqualToString:@"inputImage"]) {
        return [MLFeatureValue featureValueWithPixelBuffer:self.input];
    }
    return nil;
}

@end

@implementation YMStylizeOperation

- (void)recieveTexture:(YMTexture *)texture atIndex:(NSInteger)index
{
    if (@available(iOS 11.0, *)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            CGImageRef originalImage = [YMBasicTool transformTextureToImage:texture.texture];
            StyleTextureInput *mosaicInput = [[StyleTextureInput alloc] initWithInput:[YMBasicTool pixelBufferWithImage:[YMBasicTool scaleImage:[UIImage imageWithCGImage:originalImage] toSize:CGSizeMake(720, 720) scalingMode:YMBasicToolFillModeAspectFit].CGImage size:CGSizeMake(720, 720)]];
            id<MLFeatureProvider> mosaicOutput = [[[mosaic alloc] init].model predictionFromFeatures:mosaicInput error:nil];
            YMTexture *outtexture = [[YMTexture alloc] initWithTexture:[[YMMetalContext shareContext].textureLoader newTextureWithCGImage:[YMBasicTool imageFromCVPixelBuffer:[mosaicOutput featureValueForName:@"outputImage"].imageBufferValue] options:@{MTKTextureLoaderOptionSRGB:@(NO)} error:nil]];
            [self updateOutputWithTexture:outtexture];
        });
        [self updateOutputWithTexture:texture];
    } else {
        [self updateOutputWithTexture:texture];
    }
}

@end
