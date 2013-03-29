//
//  BlogDetail.h
//  oschina
//
//  Created by wangjun on 12-3-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Tool.h"
#import "BlogInfoModel.h"

@interface BlogDetail : UIViewController<UIWebViewDelegate>
{
    UIBarButtonItem * btnFavorite;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (retain, nonatomic) BlogInfoModel * singleBlog;
@property int blogID;

- (void)loadData:(BlogInfoModel *)b;
- (void)refreshFavorite:(BlogInfoModel *)b;
@end
