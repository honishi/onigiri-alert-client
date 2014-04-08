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
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kTwitCastingUrlSchemeOpenLive]];
}

+(void)openLiveWithUsername:(NSString*)username
{
    if ([TwitCastingUtility canOpenLive]) {
        if (!username) {
            username = MAIN_TARGET_USER;
        }

        NSString* urlSchemeString = [kTwitCastingUrlSchemeOpenLive stringByAppendingString:username];
        NSURL* url = [NSURL URLWithString:urlSchemeString];

        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
