//
//  ViewController.m
//  YasicMetalDemo
//
//  Created by yasic on 2018/9/26.
//  Copyright © 2018年 yasic. All rights reserved.
//

#import "ViewController.h"
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
    self.demoNameList = @[@{@"pageName":@"图片滤镜", @"selector":@"YMDImageLUTFilterPage"},
                          @{@"pageName":@"视频滤镜", @"selector":@"YMDVideoLUTFilterPage"},
                          @{@"pageName":@"图片立方体", @"selector":@"CubeViewController"},
                          @{@"pageName":@"计算内核", @"selector":@"YMDComputeKernelPage"},
                          @{@"pageName":@"光照效果", @"selector":@"YMDLightDemoPage"},
                          @{@"pageName":@"顶点描述符示例", @"selector":@"VertexDescrpitorPage"},
                          @{@"pageName":@"采样器示例", @"selector":@"SamplerDemoPage"},
                          @{@"pageName":@"深度检测", @"selector":@"DepthStencilPage"},
                          @{@"pageName":@"文字渲染", @"selector":@"TextRenderPage"},
                          @{@"pageName":@"自定义MetalView", @"selector":@"CAMetalLayerPage"}];
}

- (void)addViews
{
    [self.view addSubview:self.demoListTableView];
    [self.demoListTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
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
    NSString *viewControllerName = self.demoNameList[indexPath.row][@"selector"];
    Class pageClass = NSClassFromString(viewControllerName);
    UIViewController *page = [[pageClass alloc] init];
    [self.navigationController pushViewController:page animated:NO];
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
