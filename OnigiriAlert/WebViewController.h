//
//  WebViewController.h
//  OnigiriAlert
//
//  Created by Hiroyuki Onishi on 2/22/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

@property (strong, nonatomic) NSURL* url;
@property (assign, nonatomic) BOOL useToolbar;

@end
