//
//  ViewController.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/9/26.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "ViewController.h"
#import "YMDImageLUTFilterPage.h"
#import "YMDVideoLUTFilterPage.h"
#import "TestViewController.h"
#import "YMDComputeKernelPage.h"
#import "YMDLightDemoPage.h"
#import "VertexDescrpitorPage.h"
#import "SamplerDemoPage.h"
#import "DepthStencilPage.h"
#import <Masonry.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *demoListTableView;
@property (nonatomic, strong) NSArray *demoNameList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor redColor];
    [self addViews];
    self.demoNameList = @[@{@"pageName":@"图片滤镜", @"selector":@"pushImageLutPage"},
                          @{@"pageName":@"视频滤镜", @"selector":@"pushVideoLutPage"},
                          @{@"pageName":@"图片立方体", @"selector":@"pushCubeImage"},
                          @{@"pageName":@"计算内核", @"selector":@"pushComputeKernel"},
                          @{@"pageName":@"光照效果", @"selector":@"pushLightDemo"},
                          @{@"pageName":@"顶点描述符示例", @"selector":@"pushVDPage"},
                          @{@"pageName":@"采样器示例", @"selector":@"pushSamplerDemoPage"},
                          @{@"pageName":@"深度检测", @"selector":@"pushDepthStencilPage"}];
}

- (void)addViews
{
    [self.view addSubview:self.demoListTableView];
    [self.demoListTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark 点击事件

- (void)pushImageLutPage
{
    YMDImageLUTFilterPage *page = [[YMDImageLUTFilterPage alloc] init];
    [self.navigationController pushViewController:page animated:NO];
}

- (void)pushVideoLutPage
{
    YMDVideoLUTFilterPage *page = [[YMDVideoLUTFilterPage alloc] init];
    [self.navigationController pushViewController:page animated:NO];
}

- (void)pushCubeImage
{
    TestViewController *page = [[TestViewController alloc] init];
    [self.navigationController pushViewController:page animated:NO];
}

- (void)pushComputeKernel
{
    YMDComputeKernelPage *page = [[YMDComputeKernelPage alloc] init];
    [self.navigationController pushViewController:page animated:NO];
}

- (void)pushLightDemo
{
    YMDLightDemoPage *page = [[YMDLightDemoPage alloc] init];
    [self.navigationController pushViewController:page animated:NO];
}

- (void)pushVDPage
{
    VertexDescrpitorPage *VDPage = [[VertexDescrpitorPage alloc] init];
    [self.navigationController pushViewController:VDPage animated:NO];
}

- (void)pushSamplerDemoPage
{
    SamplerDemoPage *page = [[SamplerDemoPage alloc] init];
    [self.navigationController pushViewController:page animated:NO];
}

- (void)pushDepthStencilPage
{
    DepthStencilPage *page = [[DepthStencilPage alloc] init];
    [self.navigationController pushViewController:page animated:NO];
}

#pragma mark tableView代理方法

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.demoNameList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *selector = self.demoNameList[indexPath.row][@"selector"];
    if (![selector isEqualToString:@""]) {
        [self performSelector:NSSelectorFromString(selector)];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DemoCell"];
    cell.textLabel.text = self.demoNameList[indexPath.row][@"pageName"];
    return cell;
}

#pragma mark 懒加载

- (UITableView *)demoListTableView
{
    if (!_demoListTableView) {
        _demoListTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _demoListTableView.estimatedRowHeight = 0;
        _demoListTableView.estimatedSectionHeaderHeight = 0;
        _demoListTableView.estimatedSectionFooterHeight = 0;
        _demoListTableView.delegate = self;
        _demoListTableView.dataSource = self;
        [_demoListTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DemoCell"];
    }
    return _demoListTableView;
}

@end
