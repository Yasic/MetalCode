//
//  YMMetalContext.m
//  YasicMetalDemo
//
//  Created by yasic on 2019/4/3.
//  Copyright © 2019 yasic. All rights reserved.
//

#import "YMMetalContext.h"
#import "YMPipeline.h"

static YMMetalContext * context = nil;

@implementation YMMetalContext

+ (YMMetalContext *)shareContext
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        context = [[YMMetalContext alloc] init];
    });
    return context;
}

- (instancetype)init
{
    self = [super init];
    if (self){
        self.device = MTLCreateSystemDefaultDevice();
        self.commandQueue = [self.device newCommandQueue];
        self.defaultLibrary = [self.device newDefaultLibrary];
        self.textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.device];
    }
    return self;
}

@end
