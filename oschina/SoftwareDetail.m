//
//  SoftwareDetail.m
//  oschina
//
//  Created by wangjun on 12-3-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SoftwareDetail.h"

@implementation SoftwareDetail
@synthesize webView;
@synthesize softwareName;

#pragma mark - View lifecycle
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.webView stopLoading];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"软件详情";
    [ToolHelp clearWebViewBackground:webView];
    self.webView.delegate = self;

    self.webView.frame = CGRectMake(0, 0, 320, [UIScreen mainScreen].bounds.size.height - 44 - 20);
    
    //如果没有网络
    if ([Config Instance].isNetworkRunning) {

        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        [ToolHelp showHUD:@"正在加载" andView:self.view andHUD:hud];
        
        NSString *url = [NSString stringWithFormat:@"%@?ident=%@",api_software_detail, self.softwareName];
        [[AFOSCClient sharedClient] getPath:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            [hud hide:YES];
            [ToolHelp getOSCNotice2:operation.responseString];
            
            Software *s = [ToolHelp readStrSoftwareDetail:operation.responseString];
            if (s == nil) {
                [ToolHelp ToastNotification:@"加载失败" andView:self.view andLoading:NO andIsBottom:NO];
                return;
            }
            [self loadData:s];
            
            if ([Config Instance].isNetworkRunning) {
                [ToolHelp saveSoftware:self.softwareName andString:operation.responseString];
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
        NSString *value = [ToolHelp getSoftware:self.softwareName];
        if (value) {
            Software *s = [ToolHelp readStrSoftwareDetail:value];
            [self loadData:s];
        }
        else {
            [ToolHelp ToastNotification:@"错误 网络无连接" andView:self.view andLoading:NO andIsBottom:NO];
        }
    }
}

- (void)clickFavorite:(id)sender
{
    UIBarButtonItem * btn = (UIBarButtonItem *)sender;
    BOOL isFav = [btn.title isEqualToString:@"收藏此软件"];

    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [ToolHelp showHUD:isFav ? @"正在添加收藏":@"正在删除收藏" andView:self.view andHUD:hud];
    [[AFOSCClient sharedClient]getPath:isFav?api_favorite_add:api_favorite_delete 
                            parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSString stringWithFormat:@"%d", [Config Instance].getUID],@"uid",
                                        [NSString stringWithFormat:@"%d", objid],@"objid",
                                        @"1",@"type", nil] success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                
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
                                        btnFavorite.title = isFav ? @"取消收藏" : @"收藏此软件";
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
- (void)viewDidUnload
{
    [ToolHelp ReleaseWebView:self.webView];
    [self setWebView:nil];
    [super viewDidUnload];
}

- (void)loadData:(Software *)s
{
    objid = s._id;
    [self refreshFavorite:s];
    
    NSString *str_title = [NSString stringWithFormat:@"%@ %@", s.extensionTitle,s.title];
    NSString *tail = [NSString stringWithFormat:@"<div>授权协议: %@</div><div>开发语言: %@</div><div>操作系统: %@</div><div>收录时间: %@</div>",
                      s.license,s.language,s.os,s.recordTime];
    tail = [NSString stringWithFormat:@"<div><table><tr><td style='font-weight:bold'>授权协议:&nbsp;</td><td>%@</td></tr><tr><td style='font-weight:bold'>开发语言:</td><td>%@</td></tr><tr><td style='font-weight:bold'>操作系统:</td><td>%@</td></tr><tr><td style='font-weight:bold'>收录时间:</td><td>%@</td></tr></table></div>",s.license,s.language,s.os,s.recordTime];
    
    NSString *html = [NSString stringWithFormat:@"<body style='background-color:#EBEBF3'>%@<div id='oschina_title'><img src='%@' width='34' height='34'/>%@</div><hr/><div id='oschina_body'>%@</div><div>%@</div>%@%@</body>",HTML_Style,s.logo,str_title,s.body,tail, [self getButtonString:s.homePage andDocument:s.document andDownload:s.download],HTML_Bottom];
    
    NSString *result = [ToolHelp getHTMLString:html];
    [self.webView loadHTMLString:result baseURL:nil];
}
- (void)refreshFavorite:(Software *)s
{
    btnFavorite = [[UIBarButtonItem alloc] initWithTitle:s.favorite ? @"取消收藏" : @"收藏此软件" style:UIBarButtonItemStyleBordered target:self action:@selector(clickFavorite:)];
    self.navigationItem.rightBarButtonItem = btnFavorite;
}
- (NSString *)getButtonString:(NSString *)homePage andDocument:(NSString *)document andDownload:(NSString *)download
{
    NSString *strHomePage = @"";
    NSString *strDocument = @"";
    NSString *strDownload = @"";
    if ([homePage isEqualToString:@""] == NO) {
        strHomePage = [NSString stringWithFormat:@"<a href=%@><input type='button' value='软件首页' style='font-size:14px;'/></a>", homePage];
    }
    if ([document isEqualToString:@""] == NO) {
        strDocument = [NSString stringWithFormat:@"<a href=%@><input type='button' value='软件文档' style='font-size:14px;'/></a>", document];
    }
    if ([download isEqualToString:@""] == NO) {
        strDownload = [NSString stringWithFormat:@"<a href=%@><input type='button' value='软件下载' style='font-size:14px;'/></a>", download];
    }
    return [NSString stringWithFormat:@"<p>%@&nbsp;&nbsp;%@&nbsp;&nbsp;%@</p>", strHomePage, strDocument, strDownload];
}

#pragma 浏览器链接处理
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [ToolHelp analysis:[request.URL absoluteString] andNavController:self.navigationController];
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
