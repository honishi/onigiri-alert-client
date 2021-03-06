//
//  TwitCastingUtility.m
//  OnigiriAlert
//
//  Created by Hiroyuki Onishi on 2/23/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import "TwitCastingUtility.h"
#import "Credential.h"

static NSString* const kTwitCastingUrlSchemeOpenLive = @"tcviewer://live/";

@implementation TwitCastingUtility

#pragma mark - Public Interface

+(BOOL)canOpenLive
{
    return [[UIApplication sharedApplication] canOpenURL:[TwitCastingUtility urlForLive]];
}

+(void)openLive
{
    if ([TwitCastingUtility canOpenLive]) {
        [[UIApplication sharedApplication] openURL:[TwitCastingUtility urlForLive]];
    }
}

#pragma mark - Internal Methods

+(NSURL*)urlForLive
{
    NSString* urlSchemeString = [kTwitCastingUrlSchemeOpenLive stringByAppendingString:TARGET_USER];
    return [NSURL URLWithString:urlSchemeString];
}

@end
