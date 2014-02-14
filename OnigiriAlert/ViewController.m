//
//  ViewController.m
//  OnigiriAlert
//
//  Created by Hiroyuki Onishi on 2/12/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import "ViewController.h"
#import "Credential.h"

static NSString* const kTwitCastingApiServer = @"http://api.twitcasting.tv";
static NSString* const kApiPathLiveStatus = @"/api/livestatus";
static NSString* const kTwitCastingUrlSchemeOpenLive = @"tcviewer://live/";

static CGFloat const kStatusUpdateTimerInterval = 10.0f;

typedef void (^ asyncRequestCompletionBlock)(NSURLResponse* response, NSData* data, NSError* error);

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *liveStatusMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdateLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdateDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *openLiveButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;

@end

@implementation ViewController

#pragma mark - Object Lifecycle

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController Overrides

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    if (![ViewController canOpenLive:[ViewController urlForLive]]) {
        self.openLiveButton.hidden = YES;
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:kStatusUpdateTimerInterval target:self selector:@selector(updateLiveStatus) userInfo:nil repeats:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateLiveStatus];
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Public Interface

+(NSURL*)urlForLive
{
    NSString* urlSchemeString = [kTwitCastingUrlSchemeOpenLive stringByAppendingString:TARGET_USER];
    return [NSURL URLWithString:urlSchemeString];
}

+(BOOL)canOpenLive:(NSURL*)url
{
    return [[UIApplication sharedApplication] canOpenURL:url];
}

+(void)openLive
{
    NSURL* url = [ViewController urlForLive];
    
    if ([ViewController canOpenLive:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark Button Handler

- (IBAction)openLive:(id)sender
{
    [ViewController openLive];
}

- (IBAction)refreshLiveStatus:(id)sender
{
    [self updateLiveStatus];
}

#pragma mark - Internal Methods

-(void)updateLiveStatus
{
    NSString* urlString = [NSString stringWithFormat:@"%@%@?type=json&user=%@", kTwitCastingApiServer, kApiPathLiveStatus, TARGET_USER];
    NSURL* url = [NSURL URLWithString:urlString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    
    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        [self.activityIndicatorView stopAnimating];
        self.refreshButton.enabled = YES;
        
        self.lastUpdateLabel.textColor = [UIColor whiteColor];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        self.lastUpdateDateLabel.text = [dateFormatter stringFromDate:[NSDate date]];
        self.lastUpdateDateLabel.textColor = [UIColor whiteColor];
        
        if (error) {
            return;
        }
        
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        
        if (httpResponse.statusCode != 200) {
            return;
        }
        
        NSError* jsonParseError = nil;
        NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonParseError];
        
        // NSLog(@"json: %@", jsonObject);
        NSNumber* isLive = jsonObject[@"islive"];
        
        if ([isLive intValue]) {
            self.liveStatusMessageLabel.text = @"放送中のようです.";
            self.liveStatusMessageLabel.textColor = [UIColor redColor];
            self.lastUpdateLabel.textColor = [UIColor redColor];
            self.lastUpdateDateLabel.textColor = [UIColor redColor];
        }
        else {
            self.liveStatusMessageLabel.text = @"放送してないようです.";
            self.liveStatusMessageLabel.textColor = [UIColor whiteColor];
        }
    };
    
    [self.activityIndicatorView startAnimating];
    self.refreshButton.enabled = NO;
    
    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:requestCompletion];
}

#pragma mark Notification hander

-(void)applicationDidBecomeActive:(NSNotification*)notification
{
    [self updateLiveStatus];
}

@end
