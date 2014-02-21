//
//  AppDelegate.m
//  OnigiriAlert
//
//  Created by Hiroyuki Onishi on 2/12/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import "AppDelegate.h"
#import "Credential.h"
#import "TwitCastingUtility.h"
#import <Parse/Parse.h>

#ifdef DEBUG

#define DUMP_PFINSTLATION(installation) { \
        NSLog(@"pfinstallation: %@", installation); \
        NSLog(@"pfinstallation, objectId: %@", installation.objectId); \
        NSLog(@"pfinstallation, created: %@ updated: %@", installation.createdAt, installation.updatedAt); \
        NSLog(@"pfinstallation, allKeys: %@", installation.allKeys); \
}

#else

#define DUMP_PFINSTLATION(install) ;

#endif

@interface AppDelegate ()<UIActionSheetDelegate>

@end

@implementation AppDelegate

-(BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    // NSLog(@"applicationDidFinishLaunchingWithOptions w/ launchOptions: %@", launchOptions);
    [Parse setApplicationId:PARSE_APPLICATION_ID clientKey:PARSE_CLIENT_KEY];

    [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];

    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        [self launchViewer];
    }

    return YES;
}

-(void)applicationWillResignActive:(UIApplication*)application
{
    NSLog(@"applicationWillResignActive.");

    if ([[PFInstallation currentInstallation] isDirty]) {
        // saveInBackground will not be executed, so use save here
        [[PFInstallation currentInstallation] save];
    }
}

#pragma mark - Push Notification Methods

-(void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSLog(@"device token: %@", deviceToken);

    PFInstallation* currentInstallation = [PFInstallation currentInstallation];
    DUMP_PFINSTLATION(currentInstallation);

    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

-(void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    // NSLog(@"applicationDidReceiveRemoteNotification w/ userInfo: %@", userInfo);

    if (![TwitCastingUtility canOpenLive]) {
        return;
    }

    if (application.applicationState == UIApplicationStateInactive) {
        [self launchViewer];
    }
    else if (application.applicationState == UIApplicationStateActive) {
        UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"放送がはじまりました"
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        [actionSheet addButtonWithTitle:@"見る"];
        [actionSheet addButtonWithTitle:@"キャンセル"];
        actionSheet.cancelButtonIndex = actionSheet.numberOfButtons-1;

        UIView* mainView = self.window.rootViewController.view;
        [actionSheet showInView:mainView];
    }
}

-(void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.numberOfButtons-1) {     // cancel
        return;
    }

    [self launchViewer];
}

#pragma mark - Private Methods

-(void)launchViewer
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [TwitCastingUtility openLive];
        });
}

@end
