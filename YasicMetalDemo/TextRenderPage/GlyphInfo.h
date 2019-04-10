//
//  GlyphInfo.h
//  YasicMetalDemo
//
//  Created by yasic on 2019/3/7.
//  Copyright © 2019 yasic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface GlyphInfo : NSObject

@property (nonatomic, assign) wchar_t charcode;
@property (nonatomic, strong) NSData *textureData;

@property (nonatomic, assign) CGFloat xpos;

@property (nonatomic, assign) CGFloat advanceX;
@property (nonatomic, assign) CGFloat advanceY;
@property (nonatomic, assign) CGFloat offsetX;
@property (nonatomic, assign) CGFloat offsetY;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@end

NS_ASSUME_NONNULL_END
