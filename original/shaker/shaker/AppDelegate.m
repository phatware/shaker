//
//  AppDelegate.m
//  shaker
//
//  Created by Stanislav Miasnikov on 12/14/14.
//  Copyright (c) 2014 PhatWare Corp. All rights reserved.
//

#import "AppDelegate.h"
#import "RateApplication.h"
#ifdef TWITTER_SUPPORT
#import <TwitterKit/TWTRKit.h>
#endif // TWITTER_SUPPORT
#ifdef GOOGLE_ADMOB
#import <GoogleMobileAds/GoogleMobileAds.h>
#endif // GOOGLE_ADMOB
#ifdef GOOGLE_ANALYTICS
#import <Firebase.h>
#endif // GOOGLE_ANALYTICS

@interface AppDelegate ()

@end

BOOL gDisablePrompt = NO;
@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
#ifdef GOOGLE_ANALYTICS
    [FIRApp configure];
#endif // GOOGLE_ANALYTICS

#ifdef GOOGLE_ADMOB
    [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus * _Nonnull status) {
        // TODO: process response, if needed
    }];
#endif // GOOGLE_ADMOB
#ifdef TWITTER_SUPPORT
    [[Twitter sharedInstance] startWithConsumerKey:@"n5cDUr6Hvn3TB2nAUibJQhrCn" consumerSecret:@"m0rZoYWJQYCkoNbw29bUEBLp7XVqh7Uc7QjixP55URGpfVWGmi"];
#endif // TWITTER_SUPPORT
    [RateApplication sharedInstance].usesBrforePrompt = 10;
    [RateApplication sharedInstance].daysBeforePrompt = 10;
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
#ifdef TWITTER_SUPPORT
    return [[Twitter sharedInstance] application:app openURL:url options:options];
#else
    return false;
#endif // TWITTER_SUPPORT
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
