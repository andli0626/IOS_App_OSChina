//
//  NewsBase.h
//  oschina
//
//  Created by wangjun on 12-3-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NewsView.h"

@interface ZongHeMainView : UIViewController

@property (strong,nonatomic) UISegmentedControl * zongheSegment;
@property (strong,nonatomic) NewsView * newsView;

- (NSString *)getSegmentTitle;
- (void)myInit;

@end