//
//  YMDVideoLUTFilterPage.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/9/27.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "YMDVideoLUTFilterPage.h"
#import <Metal/Metal.h>
#import <MetalKit/MTKView.h>
#import "YMDMacros.h"
#import "YMDFilterProcessor.h"
#import <Masonry.h>
#import <AVFoundation/AVFoundation.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface YMDVideoLUTFilterPage ()<MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) YMDFilterProcessor *filterProcessor;
@property (nonatomic, strong) id<MTLDevice> mtlDevice;

@property (nonatomic, strong) UIView *swipeView;

@property (nonatomic, assign) NSInteger lutImageIndex;
@property (nonatomic, strong) NSArray<UIImage *> *lutImages;
@property (nonatomic, strong) UILabel *lutImageLabel;

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItemVideoOutput *playerOutput;

@property (nonatomic, strong) CADisplayLink *displayLink;

@end

@implementation YMDVideoLUTFilterPage

- (void)viewDidLoad {
    [super viewDidLoad];
    AVAsset *movieAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"]]];
    NSDictionary *settings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    self.playerOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
    self.playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    [self.playerItem addOutput:self.playerOutput];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    @weakify(self)
    [RACObserve(self.playerItem, status) subscribeNext:^(id x) {
        @strongify(self);
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            // 视频准备就绪
            NSLog(@"ready");
            [self.player play];
        }else if (self.playerItem.status == AVPlayerItemStatusFailed) {
            NSLog(@"failed");
        }
    }];
    
    [RACObserve(self.player, rate) subscribeNext:^(id x) {
        @strongify(self);
        float currentTime = CMTimeGetSeconds(self.playerItem.currentTime);
        float durationTime = CMTimeGetSeconds(self.playerItem.duration);
        if (self.player.rate == 0 && currentTime >= durationTime) {
            NSLog(@"finish");
            [self.player seekToTime:kCMTimeZero];
            [self.player play];
        }
    }];
    
    self.filterProcessor = [[YMDFilterProcessor alloc] init];
    self.mtlDevice = self.filterProcessor.mtlDevice;
    [self addViews];
    [self.mtkView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.view);
        make.width.height.equalTo(self.view);
    }];
    [self.swipeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.lutImageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-32);
    }];
    
    self.filterProcessor.mtlView = self.mtkView;
    [self.filterProcessor loadLUTImage:[UIImage imageNamed:@"lookup_000"]];
    
    [self.displayLink invalidate];
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.displayLink invalidate];
}

- (void)render
{

}

- (void)addViews
{
    [self.view addSubview:self.mtkView];
    [self.view addSubview:self.swipeView];
    [self.view addSubview:self.lutImageLabel];
}

- (void)swipe:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
        if (self.lutImageIndex > 0) {
            self.lutImageIndex--;
        }
    } else {
        if (self.lutImageIndex < self.lutImages.count - 1) {
            self.lutImageIndex++;
        }
    }
    [self.filterProcessor loadLUTImage:self.lutImages[self.lutImageIndex]];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    CMTime itemTime = self.player.currentItem.currentTime;
    CVPixelBufferRef pixelBuffer = [self.playerOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
    if (!pixelBuffer) {
        return;
    }
    [self.filterProcessor loadPixelBuffer:pixelBuffer];
    CVPixelBufferRelease(pixelBuffer);
    [self.filterProcessor renderImage];
}

- (MTKView *)mtkView
{
    if (!_mtkView) {
        _mtkView = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) device:self.mtlDevice];
        _mtkView.delegate = self;
    }
    return _mtkView;
}

- (UIView *)swipeView
{
    if (!_swipeView) {
        _swipeView = [UIView new];
        UISwipeGestureRecognizer *leftSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
        leftSwiper.direction = UISwipeGestureRecognizerDirectionLeft;
        UISwipeGestureRecognizer *rightSwiper = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipe:)];
        rightSwiper.direction = UISwipeGestureRecognizerDirectionRight;
        [_swipeView addGestureRecognizer:leftSwiper];
        [_swipeView addGestureRecognizer:rightSwiper];
    }
    return _swipeView;
}

- (NSArray<UIImage *> *)lutImages
{
    if (!_lutImages) {
        NSMutableArray *temp = [NSMutableArray array];
        for (int i = 0; i < 7; i++) {
            NSString *name = [NSString stringWithFormat:@"lookup_00%d", i];
            [temp addObject:[UIImage imageNamed:name]];
        }
        _lutImages = [temp copy];
    }
    return _lutImages;
}

- (UILabel *)lutImageLabel
{
    if (!_lutImageLabel) {
        _lutImageLabel = [UILabel new];
        _lutImageLabel.text = @"横划切换滤镜";
        _lutImageLabel.backgroundColor = HEXCOLOR(0xf7f8f3);
    }
    return _lutImageLabel;
}

@end
