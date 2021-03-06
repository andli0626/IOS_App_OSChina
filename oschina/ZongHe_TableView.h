//
//  NewsView.h
//  oschina
//
//  Created by wangjun on 12-3-6.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "NewsInfoModel.h"
#import "ZongHeDetailView.h"
#import "ShareView.h"
#import "CommentsView.h"
#import "ZongHeTableCell.h"
#import "ZongHe_MainView.h"
#import "ASIProgressDelegate.h"
#import "MBProgressHUD.h"
#import "BlogUnitModel.h"

//下拉刷新的委托
@interface ZongHe_TableView : UIViewController<UITableViewDelegate,UITableViewDataSource,EGORefreshTableHeaderDelegate,MBProgressHUDDelegate, UITabBarControllerDelegate,UIAlertViewDelegate>
{
    NSMutableArray * dataArray;
    BOOL isLoading;
    BOOL isLoadOver;
    int allCount;
    
    //下拉刷新
    EGORefreshTableHeaderView *refreshEGOTableView;
    BOOL _reloading;
}
@property (strong, nonatomic) IBOutlet UITableView *mTableView;
@property int catalog;

- (void)reloadType:(int)ncatalog;
- (void)reload:(BOOL)noRefresh;

//清空
- (void)clear;

//下拉刷新
- (void)refresh;
- (void)reloadTableViewDataSource;
- (void)doneLoadingTableViewData;

@end
