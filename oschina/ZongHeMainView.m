//
//  NewsBase.m
//  oschina
//
//  Created by wangjun on 12-3-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ZongHeMainView.h"

@implementation ZongHeMainView
@synthesize zongheSegment;
@synthesize newsView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //初始化
        [self myInit];
    }
    return self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.zongheSegment = nil;
    self.newsView = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.newsView == nil || self.zongheSegment == nil)
    {
        [self myInit];
    }
}

//综合主界面
//设计思路：
//1.整体导航上tabbar导航
//2.通过segment来动态加载表数据


//初始化
- (void)myInit
{
    self.tabBarItem.image = [UIImage imageNamed:@"info"];//设置tabbar的图片
    self.tabBarItem.title = @"综合";//设置tabbar的标题
    
    //初始化segment
    NSArray *segmentTitleArray = [NSArray arrayWithObjects:
                                  @"资讯",
                                  @"博客",
                                  @"推荐阅读",
                                  nil];
    self.zongheSegment = [[UISegmentedControl alloc] initWithItems:segmentTitleArray];
    self.zongheSegment.selectedSegmentIndex = 0;
    self.zongheSegment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.zongheSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    self.zongheSegment.frame = CGRectMake(0, 0, 300, 30);
    [self.zongheSegment addTarget:self
                           action:@selector(segmentAction:)//动作segmentAction
                 forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.zongheSegment;
    
    //子页面初始化
    self.newsView = [[NewsView alloc] init];
    self.newsView.catalog = 1;
    [self addChildViewController:self.newsView];
    [self.view addSubview:self.newsView.view];
    
    //右上角的搜索按钮
    UIBarButtonItem *btnSearch = [[UIBarButtonItem alloc]
                                  initWithTitle:@""
                                  style:UIBarButtonItemStyleBordered
                                  target:self
                                  action:nil];
    btnSearch.image = [UIImage imageNamed:@"searchWhite"];
    [btnSearch setAction:@selector(clickSearch:)];//设置动作
    self.navigationItem.rightBarButtonItem = btnSearch;
}

//搜索
- (void)clickSearch:(id)sender
{
    SearchView * sView = [[SearchView alloc] init];
    sView.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:sView animated:YES];
}

//segment动作
- (void)segmentAction:(id)sender
{
    //调用newsView的reloadType方法加载页面
    [self.newsView reloadType:self.zongheSegment.selectedSegmentIndex+1];
}


//获取segment的标题：根据segment的index
- (NSString *)getSegmentTitle
{
    switch (self.zongheSegment.selectedSegmentIndex) {
        case 0:
            return @"资讯";
        case 1:
            return @"博客";
        case 2:
            return @"推荐阅读";
    }
    return @"";
}



@end
