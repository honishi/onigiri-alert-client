//
//  WebViewController.m
//  OnigiriAlert
//
//  Created by Hiroyuki Onishi on 2/22/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIWebView* webView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem* backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem* refreshButton;

@end

@implementation WebViewController

#pragma mark - Object Lifecycle

-(id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - UIViewController Overrides

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:!self.useToolbar];

    NSURLRequest* request = [NSURLRequest requestWithURL:self.url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:60.0f];
    [self.webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate Methods

-(void)webViewDidStartLoad:(UIWebView*)webView
{
    [self.activityIndicatorView startAnimating];
    [self enableToolbarButtons:NO];
}

-(void)webViewDidFinishLoad:(UIWebView*)webView
{
    [self.activityIndicatorView stopAnimating];
    [self enableToolbarButtons:YES];

    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

-(void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    [self.activityIndicatorView stopAnimating];
    [self enableToolbarButtons:YES];
}

#pragma mark - Public Interface

#pragma mark Toolbar handler

-(IBAction)goBack:(id)sender
{
    [self.webView goBack];
}

-(IBAction)goForward:(id)sender
{
    [self.webView goForward];
}

-(IBAction)refresh:(id)sender
{
    [self.webView reload];
}

#pragma mark - Internal Methods

-(void)enableToolbarButtons:(BOOL)enabled
{
    self.backButton.enabled = [self.webView canGoBack] && enabled;
    self.forwardButton.enabled = [self.webView canGoForward] && enabled;
    self.refreshButton.enabled = enabled;
}

@end
