//
//  PWAppDelegate.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAppDelegate.h"

#import "PWNavigationController.h"
#import "PLNavigationController.h"
#import "PDNavigationController.h"
#import "PWTabBarAdsController.h"

#import <Crashlytics/Crashlytics.h>
#import <SDImageCache.h>
#import <Appirater.h>

#import "GAI.h"

#import "PDTaskManager.h"
#import "PLAssetsManager.h"
#import "PLDateFormatter.h"
#import "PDInAppPurchase.h"

#import "PWColors.h"
#import "PWPicasaAPI.h"

@implementation PWAppDelegate

static NSString * const kPWAppDelegateBackgroundFetchDateKey = @"kPWADBFDK";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Background Fetch
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // NSLocalNotification
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    // User Defaults
    NSDictionary *userDefaults = @{kPDTaskManagerIsResizePhotosKey: @(YES),
                                   kPWAppDelegateBackgroundFetchDateKey: [NSDate date]};
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Crashlytics
    [Crashlytics startWithAPIKey:@"e304869e1f84a6d87002a3e24fd4a640cfff713f"];
    
    // Appirater
    [Appirater setAppId:APPID];
    [Appirater appLaunched:YES];
    
    // NSURLSession
    [[[NSURLSession sharedSession] configuration] setURLCache:nil];
    
    // Google Analytics
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [GAI sharedInstance].dispatchInterval = 20;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-53899497-2"];
    [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:YES];
    
    
    PLNavigationController *localNavigationController = [PLNavigationController new];
    PWNavigationController *webNavigationViewController = [PWNavigationController new];
    PDNavigationController *taskNavigationController = [PDNavigationController new];
    
    NSUInteger initialTabPageIndex = 1;
    if ([ALAssetsLibrary authorizationStatus] == kCLAuthorizationStatusAuthorized && ![PWOAuthManager isLogined]) {
        initialTabPageIndex = 0;
    }
    NSArray *viewControllers = @[localNavigationController, webNavigationViewController, taskNavigationController];
    NSArray *colors = @[[PWColors getColor:PWColorsTypeTintLocalColor], [PWColors getColor:PWColorsTypeTintWebColor], [PWColors getColor:PWColorsTypeTintUploadColor]];
    
    PWTabBarAdsController *tabBarController = [[PWTabBarAdsController alloc] initWithIndex:initialTabPageIndex viewControllers:viewControllers colors:colors];
    tabBarController.isRemoveAdsAddonPurchased = [PDInAppPurchase isPurchasedWithKey:kPDRemoveAdsPuroductID];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
//    NSLog(@"%s", __func__);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
//    NSLog(@"%s", __func__);
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kPWAppDelegateBackgroundFetchDateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
//    NSLog(@"%s", __func__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
//    NSLog(@"%s", __func__);
}

- (void)applicationWillTerminate:(UIApplication *)application {
//    NSLog(@"%s", __func__);
}

#pragma mark Local Notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
}

#pragma mark Background Fetch
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[PDTaskManager sharedManager] start];
    
    if ([PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeEnable) {
        NSDate *adjustedDate = [PLDateFormatter adjustZeroClock:[NSDate date]];
        NSDate *beforeDate = [[NSUserDefaults standardUserDefaults] objectForKey:kPWAppDelegateBackgroundFetchDateKey];
        if (![adjustedDate isEqualToDate:beforeDate]) {
            [[NSUserDefaults standardUserDefaults] setObject:adjustedDate forKey:kPWAppDelegateBackgroundFetchDateKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[PLAssetsManager sharedManager] checkNewAlbumBetweenStartDate:beforeDate endDate:adjustedDate completion:^(NSArray *newAlbumDates, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.description);
                    completionHandler(UIBackgroundFetchResultNoData);
                    return;
                }
                
                if (newAlbumDates.count > 0) {
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    notification.fireDate = [NSDate date];
                    notification.timeZone = [NSTimeZone systemTimeZone];
                    if (newAlbumDates.count == 1) {
                        notification.alertBody = NSLocalizedString(@"New Album was Created!", nil);
                    }
                    else {
                        notification.alertBody = [NSString stringWithFormat:NSLocalizedString(@"New %d Albums was Created!", nil), newAlbumDates.count];
                    }
                    notification.soundName = UILocalNotificationDefaultSoundName;
                    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                }
            }];
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(24 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completionHandler(UIBackgroundFetchResultNoData);
    });
}

#pragma mark Background Transfer
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSLog(@"%s", __func__);
    
    PDTaskManager *sharedManager = [PDTaskManager sharedManager];
    sharedManager.backgroundComplecationHandler = completionHandler;
}

@end
