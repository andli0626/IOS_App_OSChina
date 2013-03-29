//
//  NewsView.m
//  oschina
//
//  Created by wangjun on 12-3-6.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ZongHe_TableView.h"

@implementation ZongHe_TableView
@synthesize mTableView;
@synthesize catalog;

//综合栏目列表界面


- (void)viewDidLoad
{
    [super viewDidLoad];
    allCount = 0;
    
    //初始化refreshEGOTableView
    if (refreshEGOTableView == nil) {
        EGORefreshTableHeaderView *view = [[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, -320.0f, self.view.frame.size.width, 320)];
        view.delegate = self;
        [self.mTableView addSubview:view];
        refreshEGOTableView = view;
    }
    [refreshEGOTableView refreshLastUpdatedDate];//更新刷新时间
    
    dataArray = [[NSMutableArray alloc] initWithCapacity:20];
    [self reload:YES];
    self.mTableView.backgroundColor = [ToolHelp getBackgroundColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshed:)
                                                 name:Notification_TabClick
                                               object:nil];
}
- (void)refreshed:(NSNotification *)notification
{
    if (notification.object) {
        if ([(NSString *)notification.object isEqualToString:@"0"]) {
            [self.mTableView setContentOffset:CGPointMake(0, -75) animated:YES];
            [self performSelector:@selector(doneManualRefresh) withObject:nil afterDelay:0.4];
        }
    }
}
- (void)doneManualRefresh
{
    [refreshEGOTableView egoRefreshScrollViewDidScroll:self.mTableView];
    [refreshEGOTableView egoRefreshScrollViewDidEndDragging:self.mTableView];
}
- (void)viewDidUnload
{
    [self setMTableView:nil];
    refreshEGOTableView = nil;
    [dataArray removeAllObjects];
    dataArray = nil;
    [super viewDidUnload];
}

//重新载入类型
- (void)reloadType:(int)ncatalog
{
    self.catalog = ncatalog;
    [self clear];
    [self.mTableView reloadData];
    [self reload:NO];
}
- (void)clear
{
    allCount = 0;
    [dataArray removeAllObjects];
    isLoadOver = NO;
}
- (void)reload:(BOOL)noRefresh
{
    //如果有网络连接
    if ([Config Instance].isNetworkRunning) {
        if (isLoading || isLoadOver) {
            return;
        }
        if (!noRefresh) {
            allCount = 0;
        }
        int pageIndex = allCount/20;
        NSString *url;
        switch (self.catalog) {
            case 1:
                url = [NSString stringWithFormat:@"%@?catalog=%d&pageIndex=%d&pageSize=%d", api_news_list, 1, pageIndex, 20];
                break;
            case 2:
                url = [NSString stringWithFormat:@"%@?type=latest&pageIndex=%d&pageSize=%d", api_blog_list, pageIndex, 20];
                break;
            case 3:
                url = [NSString stringWithFormat:@"%@?type=recommend&pageIndex=%d&pageSize=%d", api_blog_list, pageIndex, 20];
                break;
        }
        
        [[AFOSCClient sharedClient]getPath:url parameters:Nil
         
                                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                       
                                       [ToolHelp getOSCNotice2:operation.responseString];
                                       isLoading = NO;
                                       if (!noRefresh) {
                                           [self clear];
                                       }
                                       
                                       @try {
                                           NSMutableArray *newNews = self.catalog <= 1 ?
                                           
                                           [ToolHelp readStrNewsArray:operation.responseString andOld: dataArray]:
                                           [ToolHelp readStrUserBlogsArray:operation.responseString andOld: dataArray];
                                           int count = [ToolHelp isListOver2:operation.responseString];
                                           allCount += count;
                                           if (count < 20)
                                           {
                                               isLoadOver = YES;
                                           }
                                           [dataArray addObjectsFromArray:newNews];
                                           [self.mTableView reloadData];
                                           [self doneLoadingTableViewData];
                                           
                                           //如果是第一页 则缓存下来
                                           if (dataArray.count <= 20) {
                                               [ToolHelp saveCache:5 andID:self.catalog andString:operation.responseString];
                                           }
                                       }
                                       @catch (NSException *exception) {
                                           [NdUncaughtExceptionHandler TakeException:exception];
                                       }
                                       @finally {
                                           [self doneLoadingTableViewData];
                                       }
                                   } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       NSLog(@"新闻列表获取出错");
                                       //如果是刷新
                                       [self doneLoadingTableViewData];
                                       
                                       if ([Config Instance].isNetworkRunning == NO) {
                                           return;
                                       }
                                       isLoading = NO;
                                       if ([Config Instance].isNetworkRunning) {
                                           [ToolHelp ToastNotification:@"错误 网络无连接" andView:self.view andLoading:NO andIsBottom:NO];
                                       }
                                   }];
        isLoading = YES;
        [self.mTableView reloadData];
    }
    //如果没有网络连接
    else
    {
        NSString *value = [ToolHelp getCache:5 andID:self.catalog];
        if (value) {
            NSMutableArray *newNews = [ToolHelp readStrNewsArray:value andOld:dataArray];
            [self.mTableView reloadData];
            isLoadOver = YES;
            [dataArray addObjectsFromArray:newNews];
            [self.mTableView reloadData];
            [self doneLoadingTableViewData];
        }
    }
}

#pragma TableView的处理
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([Config Instance].isNetworkRunning) {
        if (isLoadOver) {
            return dataArray.count == 0 ? 1 : dataArray.count;
        }
        else
            return dataArray.count + 1;
    }
    else
        return dataArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 62;
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [ToolHelp getCellBackgroundColor];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([dataArray count] > 0) {
        if ([indexPath row] < [dataArray count])
        {
            ZongHeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:NewsCellIdentifier];
            if (!cell) {
                NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"ZongHeTableCell" owner:self options:nil];
                for (NSObject *o in objects) {
                    if ([o isKindOfClass:[ZongHeTableCell class]]) {
                        cell = (ZongHeTableCell *)o;
                        break;
                    }
                }
            }
            cell.lblTitle.font = [UIFont boldSystemFontOfSize:15.0];
            if (self.catalog <= 1) {
                NewsInfoModel *n = [dataArray objectAtIndex:[indexPath row]];
                cell.lblTitle.text = n.title;
                cell.lblAuthor.text = [NSString stringWithFormat:@"%@ 发布于 %@ (%d评)", n.author, n.pubDate, n.commentCount];
            }
            else
            {
                BlogUnitModel *b = [dataArray objectAtIndex:indexPath.row];
                cell.lblTitle.text = b.title;
                cell.lblAuthor.text = [NSString stringWithFormat:@"%@ %@ %@ (%d评)", b.authorName,b.documentType==1?@"原创":@"转载", b.pubDate, b.commentCount];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        }
        else
        {
            return [[DataSingleton Instance] getLoadMoreCell:tableView
                                               andIsLoadOver:isLoadOver
                                           andLoadOverString:@"已经加载全部新闻"
                                            andLoadingString:(isLoading ? loadingTip : loadNext20Tip) andIsLoading:isLoading];
        }
    }
    else
    {
        return [[DataSingleton Instance] getLoadMoreCell:tableView
                                           andIsLoadOver:isLoadOver
                                       andLoadOverString:@"已经加载全部新闻"
                                        andLoadingString:(isLoading ? loadingTip : loadNext20Tip)
                                            andIsLoading:isLoading];
    }
}

//列表点击事件
- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    int row = [indexPath row];
    if (row >= [dataArray count]) {
        if (!isLoading) {
            [self performSelector:@selector(reload:)];
        }
    }
    else {
        ZongHe_MainView *mZongHe_MainView = (ZongHe_MainView *)self.parentViewController;
        self.parentViewController.title = [mZongHe_MainView getSegmentTitle];
        self.parentViewController.tabBarItem.title = @"综合";
        if (self.catalog == 1) {
            NewsInfoModel *newInfo = [dataArray objectAtIndex:row];
            if (newInfo)
            {
                
                if (newInfo.url.length == 0) {
                    //跳转到综合详情
                    [ToolHelp pushNewsDetail:newInfo
                            andNavController:self.parentViewController.navigationController
                               andIsNextPage:NO];
                }
                else
                {
                    //对URL类型进行判断，跳转到其他页面
                    [ToolHelp analysis:newInfo.url
                      andNavController:mZongHe_MainView.navigationController];
                }
            }
        }
        else
        {
            BlogUnitModel *blogUnit = [dataArray objectAtIndex:row];
            if (blogUnit) {
                [ToolHelp analysis:blogUnit.url
                  andNavController:mZongHe_MainView.navigationController];
            }
        }
    }
}

#pragma 下提刷新
- (void)reloadTableViewDataSource
{
    _reloading = YES;
}
- (void)doneLoadingTableViewData
{
    _reloading = NO;
    [refreshEGOTableView egoRefreshScrollViewDataSourceDidFinishedLoading:self.mTableView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [refreshEGOTableView egoRefreshScrollViewDidScroll:scrollView];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [refreshEGOTableView egoRefreshScrollViewDidEndDragging:scrollView];
}
- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view
{
    [self reloadTableViewDataSource];
    [self refresh];
}
- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView *)view
{
    return _reloading;
}
- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView *)view
{
    return [NSDate date];
}
- (void)refresh
{
    if ([Config Instance].isNetworkRunning) {
        isLoadOver = NO;
        [self reload:NO];
    }
    //无网络连接则读取缓存
    else {
        NSString *value = [ToolHelp getCache:5 andID:self.catalog];
        if (value) 
        {
            NSMutableArray *newNews = [ToolHelp readStrNewsArray:value andOld:dataArray];
            if (newNews == nil) {
                [self.mTableView reloadData];
            }
            else if(newNews.count <= 0){
                [self.mTableView reloadData];
                isLoadOver = YES;
            }
            else if(newNews.count < 20){
                isLoadOver = YES;
            }
            [dataArray addObjectsFromArray:newNews];
            [self.mTableView reloadData];
            [self doneLoadingTableViewData];
        }
    }
}

@end
