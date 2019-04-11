//
//  CAMetalLayerPage.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/1.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "CAMetalLayerPage.h"
#import "CustomMetalView.h"
#import <Masonry.h>
#import "YMTextureOutput.h"
#import "YMTextureInput.h"
#import "YMConstants.h"
#import "YMLUTFilterOperation.h"
#import "YMSaturationOperation.h"
#import "YMBrightnessOperation.h"
#import "YMZoomBlurOperation.h"
#import "YMToonOperation.h"

@interface CAMetalLayerPage ()

/**
 自定义的 MetalView
 */
@property (nonatomic, strong) YMTextureOutput *outputView;

/**
 纹理输入
 */
@property (nonatomic, strong) YMTextureInput *textureInput;

@property (nonatomic, strong) CADisplayLink *link;

@property (nonatomic, assign) float intensity;
@property (nonatomic, assign) float offset;
@property (nonatomic, strong) YMToonOperation *operation;

@end

@implementation CAMetalLayerPage

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.outputView];
    [self.outputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.mas_topLayoutGuideBottom);
        make.bottom.equalTo(self.mas_bottomLayoutGuideTop);
    }];
    self.textureInput = [[YMTextureInput alloc] initWithUIImage:[UIImage imageNamed:@"DogLogo"]];
    self.operation = [[YMToonOperation alloc] init];
    self.textureInput.imageOutput = self.operation;
    self.operation.imageOutput = self.outputView;
    [self.textureInput processTexture];
    [self addSliderWithIndex:0];
    [self addSliderWithIndex:1];
}

- (void)addSliderWithIndex:(NSInteger)index
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
    [self.view addSubview:slider];
    slider.tag = index;
    if (index == 0) {
        slider.minimumValue = 0;
        slider.maximumValue = 1.0;
    } else {
        slider.minimumValue = 0;
        slider.maximumValue = 20;
    }
    slider.value = 0.0;
    slider.continuous = YES;
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(50);
        make.right.equalTo(self.view).offset(-50);
        make.bottom.equalTo(self.mas_bottomLayoutGuideTop).offset(-45 + index * 20);
        make.height.equalTo(@(32));
    }];
}

- (void)sliderValueChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    if (slider.tag == 0) {
        self.operation.magTol = slider.value;
    } else {
        self.operation.quantize = slider.value;
    }
    [self.textureInput processTexture];
}

- (YMTextureOutput *)outputView
{
    if (!_outputView) {
        _outputView = [[YMTextureOutput alloc] initWithFrame:CGRectZero];
    }
    return _outputView;
}

@end
