//
//  SinglePost.m
//  oschina
//
//  Created by wangjun on 12-3-14.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SinglePost.h"

@implementation SinglePost
@synthesize webView;
@synthesize postID;
@synthesize singlePost;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.webView stopLoading];
}
#pragma mark - View lifecycle
- (void)viewDidAppear:(BOOL)animated
{
    self.parentViewController.navigationItem.title = @"问答详情";
    if (self.singlePost) {
        [self refreshFavorite:self.singlePost];
    }
}

- (void)clickFavorite:(id)sender
{
    UIBarButtonItem * btn = (UIBarButtonItem *)sender;
    BOOL isFav = [btn.title isEqualToString:@"收藏此帖"];
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [ToolHelp showHUD:isFav ? @"正在添加收藏":@"正在删除收藏" andView:self.view andHUD:hud];
    [[AFOSCClient sharedClient]getPath:isFav?api_favorite_add:api_favorite_delete 
                            parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSString stringWithFormat:@"%d", [Config Instance].getUID],@"uid",
                                        [NSString stringWithFormat:@"%d", postID],@"objid",
                                        @"2",@"type", nil] success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                
                                [hud hide:YES];
                                [ToolHelp getOSCNotice2:operation.responseString];
                                
                                ApiError *error = [ToolHelp getApiError2:operation.responseString];
                                if (error == nil) {
                                    [ToolHelp ToastNotification:operation.responseString andView:self.view andLoading:NO andIsBottom:NO];
                                    return;
                                }
                                switch (error.errorCode) 
                                {
                                    case 1:
                                    {
                                        btnFavorite.title = isFav ? @"取消收藏" : @"收藏此文";
                                        self.singlePost.favorite = !self.singlePost.favorite; 
                                    }
                                        break;
                                    case 0:
                                    case -2:
                                    case -1:
                                    {
                                        [ToolHelp ToastNotification:[NSString stringWithFormat:@"错误 %@",error.errorMessage] andView:self.view andLoading:NO andIsBottom:NO];
                                    }
                                        break;
                                }
                                
                                
                            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                [hud hide:YES];
                                [ToolHelp ToastNotification:@"添加收藏失败" andView:self.view andLoading:NO andIsBottom:NO];
                            }];

    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [ToolHelp processLoginNotice:actionSheet andButtonIndex:buttonIndex andNav:self.parentViewController.navigationController andParent:self];
}
- (void)viewDidLoad
{
    [ToolHelp clearWebViewBackground:webView];
    self.tabBarItem.image = [UIImage imageNamed:@"detail"];
    [super viewDidLoad];
    self.singlePost = [[SinglePostDetail alloc] init];
    self.webView.delegate = self;
    [self.webView loadHTMLString:@"" baseURL:nil];
    
    if ([Config Instance].isNetworkRunning) {

        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        [ToolHelp showHUD:@"正在加载" andView:self.view andHUD:hud];
        
        NSString *url = [NSString stringWithFormat:@"%@?id=%d",api_post_detail, postID];
        [[AFOSCClient sharedClient] getPath:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [ToolHelp getOSCNotice2:operation.responseString];
            [hud hide:YES];
            self.singlePost = [ToolHelp readStrSinglePostDetail:operation.responseString];
            if (self.singlePost == nil) {
                [ToolHelp ToastNotification:@"加载失败" andView:self.view andLoading:NO andIsBottom:NO];
                return;
            }
            [self loadData:self.singlePost];
            
            if ([Config Instance].isNetworkRunning) {
                [ToolHelp saveCache:2 andID:self.singlePost._id andString:operation.responseString];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            [hud hide:YES];
            if ([Config Instance].isNetworkRunning) {
                [ToolHelp ToastNotification:@"错误 网络无连接" andView:self.view andLoading:NO andIsBottom:NO];
            }
            
        }];
        
    }
    else
    {      
        NSString *value = [ToolHelp getCache:2 andID:postID];
        if (value) {
            self.singlePost = [ToolHelp readStrSinglePostDetail:value];
            [self loadData:self.singlePost];
        }
        else {
            [ToolHelp ToastNotification:@"错误 网络无连接" andView:self.view andLoading:NO andIsBottom:NO];
        }
    }
}
- (void)loadData:(SinglePostDetail *)p
{
    [self refreshFavorite:p];
    //通知已经获取了帖子回复数 
    Notification_CommentCount *notification = [[Notification_CommentCount alloc] initWithParameters:self andCommentCount:p.answerCount];
    [[NSNotificationCenter defaultCenter] postNotificationName:Notification_DetailCommentCount object:notification];
    
    //微博分享准备
    [Config Instance].shareObject = [[ShareObject alloc] initWithParameters:p.title andUrl:p.url];
    //显示
    NSString *author_str = [NSString stringWithFormat:@"<a href='http://my.oschina.net/u/%d'>%@</a> 发布于 %@",p.authorid, p.author, p.pubDate];
    NSString *html = [NSString stringWithFormat:@"<body style='background-color:#EBEBF3;'>%@<div id='oschina_title'>%@</div><div id='oschina_outline'>%@</div><hr/><div id='oschina_body'>%@</div>%@%@</body>",HTML_Style, p.title,author_str,p.body,[ToolHelp GenerateTags:p.tags],HTML_Bottom];

    NSString *result = [ToolHelp getHTMLString:html];
    [self.webView loadHTMLString:result baseURL:nil];
}
- (void)refreshFavorite:(SinglePostDetail *)p
{
    btnFavorite = [[UIBarButtonItem alloc] initWithTitle:p.favorite ? @"取消收藏" : @"收藏此帖" style:UIBarButtonItemStyleBordered target:self action:@selector(clickFavorite:)];
    self.parentViewController.navigationItem.rightBarButtonItem = btnFavorite;
}
- (void)viewDidUnload
{
    [ToolHelp ReleaseWebView:self.webView];
    [self setWebView:nil];
    singlePost = nil;
    [super viewDidUnload];
}
#pragma 浏览器链接处理
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [ToolHelp analysis:[request.URL absoluteString] andNavController:self.parentViewController.navigationController];
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) 
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
