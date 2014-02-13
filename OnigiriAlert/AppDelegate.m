//
//  AppDelegate.m
//  OnigiriAlert
//
//  Created by Hiroyuki Onishi on 2/12/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import "AppDelegate.h"
#import "Credential.h"
#import "ViewController.h"
#import <Parse/Parse.h>

@implementation AppDelegate

-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    NSLog(@"applicationDidFinishLaunchingWithOptions w/ launchOptions: %@", launchOptions);

    [Parse setApplicationId:PARSE_APPLICATION_ID clientKey:PARSE_CLIENT_KEY];
    
    [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [self launchViewer];
    }
    
    return YES;
}

#pragma mark - Push Notification Methods

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    NSLog(@"token: %@", newDeviceToken);
    
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"applicationDidReceiveRemoteNotification w/ userInfo: %@", userInfo);
    [PFPush handlePush:userInfo];
    [self launchViewer];
}

#pragma mark - Private Methods

-(void)launchViewer
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ViewController openLive];
    });
}

@end
