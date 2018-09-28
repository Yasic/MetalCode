//
//  YMDMacros.h
//  YasicMetalDemo
//
//  Created by yasic on 2018/9/27.
//  Copyright © 2018年 yasic. All rights reserved.
//

#ifndef YMDMacros_h
#define YMDMacros_h

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]

#define HEXCOLOR(hexValue) HEXACOLOR(hexValue, 1.0)
#define HEXACOLOR(hexValue, alphaValue) [UIColor colorWithRed:((CGFloat)((hexValue & 0xFF0000) >> 16))/255.0 green:((CGFloat)((hexValue & 0xFF00) >> 8))/255.0 blue:((CGFloat)(hexValue & 0xFF))/255.0 alpha:(alphaValue)]

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#endif /* YMDMacros_h */
