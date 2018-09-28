//
//  ViewController.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/9/26.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "ViewController.h"
#import "YMDImageLUTFilterPage.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    YMDImageLUTFilterPage *imagePage = [[YMDImageLUTFilterPage alloc] init];
    [self.navigationController pushViewController:imagePage animated:NO];
}

@end
