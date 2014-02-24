//
//  MainViewController.m
//  OnigiriAlert
//
//  Created by Hiroyuki Onishi on 2/12/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import "MainViewController.h"
#import "Credential.h"
#import "WebViewController.h"
#import <Parse/Parse.h>
#import "Reachability.h"

// #define DEBUG_FORCE_INITIALIZE_PARSE_INSTALLATION

static NSString* const kReachabilityHostname = @"twitcasting.tv";

static NSString* const kWebUrlTwitCasting = @"http://twitcasting.tv";
static NSString* const kTwitCastingApiUrl = @"http://api.twitcasting.tv";
static NSString* const kTwitCastingApiPathLiveStatus = @"/api/livestatus";

static CGFloat const kStatusUpdateTimerInterval = 10.0f;

static NSString* const kSegueIdentifierShowWeb = @"showWeb";

static NSString* kCellReuseIdentifierStatus = @"StatusCell";
static NSString* kCellReuseIdentifierSetting = @"SettingCell";
static NSString* kCellReuseIdentifierAppInfo = @"AppInfoCell";

static NSString* const kParseInstallationKeyChannels = @"channels";
static NSString* const kParseChannelNameDefault = @"default";
static NSString* const kParseChannelNamePrefixTimeSlot = @"ts";
static CGFloat const kBackgroundSaveFireGraceTime = 1.0f;

typedef void (^ asyncRequestCompletionBlock)(NSURLResponse* response, NSData* data, NSError* error);

#pragma mark - Utililty

@interface TimeSlotSubscriptionSwitch : UISwitch
@property (assign, nonatomic) NSInteger hour;
@end

@implementation TimeSlotSubscriptionSwitch
@end

#pragma mark - Main

@interface MainViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) BOOL reachable;

@property (weak, nonatomic) IBOutlet UITableView* tableView;
@property (strong, nonatomic) UIRefreshControl* refreshControl;
@property (strong, nonatomic) UIActivityIndicatorView* activityIndicatorView;

@property (assign, nonatomic) BOOL liveStatus;
@property (strong, nonatomic) NSDate* liveStatusUpdateDate;

@property (strong, nonatomic) NSMutableArray* cachedChannels;
@property (strong, nonatomic) NSTimer* backgroundSaveTriggerTimer;

@end

@implementation MainViewController

#pragma mark - Object Lifecycle

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController Overrides

-(void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"おにぎり";

    [self initReachability];

    [self initCachedChannels];
    [self readChannelsFromParse];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshStart:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView];
    [self navigationItem].rightBarButtonItem = barButton;

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];

    [NSTimer scheduledTimerWithTimeInterval:kStatusUpdateTimerInterval target:self selector:@selector(updateLiveStatus) userInfo:nil repeats:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateLiveStatus];
    [self updateSetting];
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Segue

-(void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:kSegueIdentifierShowWeb]) {
        WebViewController* webViewController = [segue destinationViewController];
        NSURL* url = nil;
        BOOL useToolbar = YES;
        NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];

        if (indexPath.section == 0 && indexPath.row == 0) {
            NSString* urlString = [NSString stringWithFormat:@"%@/%@", kWebUrlTwitCasting, TARGET_USER];
            url = [NSURL URLWithString:urlString];
        }
        else if (indexPath.section == 2 && indexPath.row == 0) {
            url = [NSURL URLWithString:APP_ABOUT_SITE_URL];
            useToolbar = NO;
        }

        webViewController.url = url;
        webViewController.useToolbar = useToolbar;
    }
}

#pragma mark - UITableViewDataSource Methods

#pragma mark Tableview outline

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 3;   // status, setting, app info
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    if (section == 0) {
        numberOfRows = 2;
    }
    else if (section == 1) {
        numberOfRows = 24;  // = a day
    }
    else if (section == 2) {
        numberOfRows = 2;
    }

    return numberOfRows;
}

-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = @"";

    if (section == 0) {
        title = @"配信状況";
    }
    else if (section == 1) {
        title = @"通知設定";
    }
    else if (section == 2) {
        title = @"アプリケーション情報";
    }

    return title;
}

#pragma mark Cell

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;

    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifierStatus];

        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellReuseIdentifierStatus];
        }
    }
    else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifierSetting];

        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellReuseIdentifierSetting];
            TimeSlotSubscriptionSwitch* switchView = [[TimeSlotSubscriptionSwitch alloc] initWithFrame:CGRectZero];
            [switchView addTarget:self action:@selector(changeTimeSlotSubscription:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = switchView;
        }
    }
    else if (indexPath.section == 2) {
        cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifierAppInfo];

        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kCellReuseIdentifierAppInfo];
        }
    }

    [self updateCell:cell atIndexPath:indexPath animated:NO];

    return cell;
}

#pragma mark Cell updater

-(void)updateCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"配信";
            if (self.liveStatus) {
                cell.detailTextLabel.text = @"配信中のようです";
                cell.detailTextLabel.textColor = [UIColor redColor];
            }
            else {
                cell.detailTextLabel.text = @"配信してないようです";
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (indexPath.row == 1) {
            cell.textLabel.text = @"更新日時";
            cell.detailTextLabel.text = [self dateStringForDate:self.liveStatusUpdateDate];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    else if (indexPath.section == 1) {
        cell.textLabel.text = [NSString stringWithFormat:@"%02d:00-", indexPath.row];

        TimeSlotSubscriptionSwitch* switchView = (TimeSlotSubscriptionSwitch*)cell.accessoryView;
        switchView.hour = indexPath.row;

        BOOL currentSettingOn = [self.cachedChannels indexOfObject:[self channelNameForTimeSlotWithHour:indexPath.row]] != NSNotFound;
        [switchView setOn:currentSettingOn animated:animated];
        switchView.enabled = self.reachable;

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"About";
            cell.detailTextLabel.text = @"";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else if (indexPath.row == 1) {
            cell.textLabel.text = @"バージョン";
            cell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
}

-(void)updateVisibleCells
{
    for (UITableViewCell* cell in self.tableView.visibleCells) {
        [self updateCell:cell atIndexPath:[self.tableView indexPathForCell:cell] animated:YES];
    }
}

#pragma mark - UITableViewDelegate Methods

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ((indexPath.section == 0 && indexPath.row == 0) || (indexPath.section == 2 && indexPath.row == 0)) {
        [self performSegueWithIdentifier:kSegueIdentifierShowWeb sender:self];
    }

    // do not call deselectRowAtIndexPath at the top in this method, cause indexPathForSelectedRow is used in prepareForSegue
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Internal Methods

-(void)initReachability
{
    Reachability* reach = [Reachability reachabilityWithHostname:kReachabilityHostname];

    __weak MainViewController* weakSelf = self;
    reach.reachableBlock = ^(Reachability* reach)
    {
        // NSLog(@"REACHABLE.");
        weakSelf.reachable = YES;
        // force to use main thread to update ui
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateVisibleCells];
        });
    };

    reach.unreachableBlock = ^(Reachability* reach)
    {
        // NSLog(@"UNREACHABLE.");
        weakSelf.reachable = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateVisibleCells];
        });
    };

    [reach startNotifier];
}

#pragma mark View updater

-(void)updateLiveStatus
{
    NSString* urlString = [NSString stringWithFormat:@"%@%@?type=json&user=%@", kTwitCastingApiUrl, kTwitCastingApiPathLiveStatus, TARGET_USER];
    NSURL* url = [NSURL URLWithString:urlString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];

    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        [self.refreshControl endRefreshing];

        self.liveStatusUpdateDate = [NSDate date];

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

        self.liveStatus = 0 < [isLive intValue];

        [self updateVisibleCells];
    };

    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:requestCompletion];
}

-(void)updateSetting
{
    // NSLog(@"currentInstallation.isDirty: %d", [PFInstallation currentInstallation].isDirty);
    if ([PFInstallation currentInstallation].isDirty) {
        NSLog(@"there is dirty data in currentInstallation. so skipped refresh.");
        return;
    }
    
    [[PFInstallation currentInstallation] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        [self readChannelsFromParse];
        [self updateVisibleCells];
    }];
}

#pragma mark Notification hander

-(void)applicationDidBecomeActive:(NSNotification*)notification
{
    [self updateLiveStatus];
    [self updateSetting];
}

#pragma mark Refresh control

-(void)refreshStart:(id)sender
{
    [self.refreshControl beginRefreshing];

    if (!self.reachable) {
        [self.refreshControl endRefreshing];
        return;
    }

    [self updateLiveStatus];
    [self updateSetting];
}

#pragma mark - Parse & Cached channels utilities

-(void)initCachedChannels
{
    if (!self.cachedChannels) {
        self.cachedChannels = NSMutableArray.new;
    }

    BOOL isFirstLaunch = ([PFInstallation currentInstallation].objectId == nil);

    if (isFirstLaunch) {
        [self.cachedChannels addObject:kParseChannelNameDefault];
        for (NSInteger hour = 0; hour < 24; hour++) {
            [self.cachedChannels addObject:[self channelNameForTimeSlotWithHour:hour]];
        }

        [self flushCachedChannelsToParse];
    }
}

-(void)readChannelsFromParse
{
    self.cachedChannels = [[PFInstallation currentInstallation] channels].mutableCopy;
    // NSLog(@"cached subscriptions: %@", self.cachedChannels);
}

-(void)flushCachedChannelsToParse
{
    [[PFInstallation currentInstallation] setObject:self.cachedChannels forKey:kParseInstallationKeyChannels];

    if ([[PFInstallation currentInstallation] isDirty]) {
        [self.activityIndicatorView startAnimating];
        [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError* error) {
             [self.activityIndicatorView stopAnimating];
         }];
    }
}

-(void)changeTimeSlotSubscription:(id)sender
{
    // NSLog(@"value changed.");

    TimeSlotSubscriptionSwitch* switchView = sender;
    NSString* channelName = [self channelNameForTimeSlotWithHour:switchView.hour];

    if (switchView.on) {
        if ([self.cachedChannels indexOfObject:channelName] == NSNotFound) {
            [self.cachedChannels addObject:channelName];
        }
    }
    else {
        if ([self.cachedChannels indexOfObject:channelName] != NSNotFound) {
            [self.cachedChannels removeObject:channelName];
        }
    }
    // NSLog(@"cachedChannels changed: %@", self.cachedChannels);

    [self reserveBackgroundSave];
}

#pragma mark Save timer

-(void)reserveBackgroundSave
{
    if (self.backgroundSaveTriggerTimer) {
        [self.backgroundSaveTriggerTimer invalidate];
        self.backgroundSaveTriggerTimer = nil;
    }

    self.backgroundSaveTriggerTimer = [NSTimer scheduledTimerWithTimeInterval:kBackgroundSaveFireGraceTime
                                                                       target:self
                                                                     selector:@selector(executeBackgroundSave)
                                                                     userInfo:nil
                                                                      repeats:NO];
}

-(void)executeBackgroundSave
{
    [self.backgroundSaveTriggerTimer invalidate];
    self.backgroundSaveTriggerTimer = nil;

    [self flushCachedChannelsToParse];
}

#pragma mark utility

-(NSString*)channelNameForTimeSlotWithHour:(NSInteger)hour
{
    return [NSString stringWithFormat:@"%@%02d", kParseChannelNamePrefixTimeSlot, hour];
}

#pragma mark - Misc utilities

-(NSString*)dateStringForDate:(NSDate*)date
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    return [dateFormatter stringFromDate:[NSDate date]];
}

@end
