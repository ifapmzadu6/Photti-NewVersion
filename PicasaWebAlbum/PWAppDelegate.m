//
//  PWAppDelegate.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAppDelegate.h"

#import <Crashlytics/Crashlytics.h>
#import <SDImageCache.h>
#import <UAAppReviewManager.h>
#import <GAI.h>
#import <GAIDictionaryBuilder.h>

#import "PAColors.h"
#import "PWPicasaAPI.h"
#import "PDTaskManager.h"
#import "PLAssetsManager.h"
#import "PADateFormatter.h"
#import "PAInAppPurchase.h"
#import "PWCoreDataAPI.h"
#import "PLCoreDataAPI.h"
#import "PDCoreDataAPI.h"

#import "PWNavigationController.h"
#import "PLNavigationController.h"
#import "PDNavigationController.h"
#import "PENavigationController.h"
#import "PATabBarAdsController.h"
#import "PAMigrationViewController.h"

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
    [Crashlytics startWithAPIKey:CLASHLYTICSID];
    
    // UAAppReviewManager
    [UAAppReviewManager setAppID:APPID];
    [UAAppReviewManager showPromptIfNecessary];
    
    // NSURLSession
    [[[NSURLSession sharedSession] configuration] setURLCache:nil];
    
    // Google Analytics
    [GAI sharedInstance].dispatchInterval = 30;
#ifdef DEBUG
//    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
#endif
    [[GAI sharedInstance] trackerWithTrackingId:GOOGLEANALYTICSID];
    [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:YES];
    
    UIViewController *rootViewController = nil;
    if ([PWCoreDataAPI shouldPerformCoreDataMigration]) {
        rootViewController = [self migrationViewController];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [PWCoreDataAPI readContext];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.window.rootViewController = [self tabBarController];
            });
        });
    }
    else {
        rootViewController = [self tabBarController];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (UIViewController *)tabBarController {
    // Renewal
    PENavigationController *phNavigationController = [PENavigationController new];
    
    PLNavigationController *localNavigationController = [PLNavigationController new];
    PWNavigationController *webNavigationViewController = [PWNavigationController new];
    PDNavigationController *taskNavigationController = [PDNavigationController new];
    
//    NSUInteger initialTabPageIndex = 1;
    // Renewal
    NSUInteger initialTabPageIndex = 0;
    
    if ([ALAssetsLibrary authorizationStatus] == kCLAuthorizationStatusAuthorized && ![PWOAuthManager isLogined]) {
        initialTabPageIndex = 0;
    }
//    NSArray *viewControllers = @[localNavigationController, webNavigationViewController, taskNavigationController];
//    NSArray *colors = @[[PAColors getColor:PAColorsTypeTintLocalColor], [PAColors getColor:PAColorsTypeTintWebColor], [PAColors getColor:PAColorsTypeTintUploadColor]];
    
    // Renewal
    NSArray *viewControllers = @[phNavigationController, localNavigationController, webNavigationViewController, taskNavigationController];
    NSArray *colors = @[[UIColor colorWithWhite:0.5f alpha:1.0f], [PAColors getColor:PAColorsTypeTintLocalColor], [PAColors getColor:PAColorsTypeTintWebColor], [PAColors getColor:PAColorsTypeTintUploadColor]];
    
    PATabBarAdsController *tabBarController = [[PATabBarAdsController alloc] initWithIndex:initialTabPageIndex viewControllers:viewControllers colors:colors];
    tabBarController.isRemoveAdsAddonPurchased = [PAInAppPurchase isPurchasedWithKey:kPDRemoveAdsPuroductID];
    
    return tabBarController;
}

- (UIViewController *)migrationViewController {
    PAMigrationViewController *viewController = [PAMigrationViewController new];
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    
    return navigationController;
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
    
    // Google Analytics
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GOOGLEANALYTICSID];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"PWAppDelegate" action:@"Background Fetch" label:@"default" value:@(0)] build]];
    
    __block BOOL isFinish = NO;
    if ([PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeEnable) {
        NSDate *adjustedDate = [PADateFormatter adjustZeroClock:[NSDate date]];
        NSDate *beforeDate = [[NSUserDefaults standardUserDefaults] objectForKey:kPWAppDelegateBackgroundFetchDateKey];
        if (![adjustedDate isEqualToDate:beforeDate]) {
            [[NSUserDefaults standardUserDefaults] setObject:adjustedDate forKey:kPWAppDelegateBackgroundFetchDateKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[PLAssetsManager sharedManager] checkNewAlbumBetweenStartDate:beforeDate endDate:adjustedDate completion:^(NSArray *newAlbumDates, NSError *error) {
                if (error) {
#ifdef DEBUG
                    NSLog(@"%@", error);
#endif
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!isFinish) {
                            completionHandler(UIBackgroundFetchResultNoData);
                            isFinish = YES;
                        }
                    });
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!isFinish) {
                        completionHandler(UIBackgroundFetchResultNewData);
                        isFinish = YES;
                    }
                });
            }];
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(24 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!isFinish) {
            completionHandler(UIBackgroundFetchResultNoData);
            isFinish = YES;
        }
    });
}

#pragma mark Background Transfer
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    
    PDTaskManager *sharedManager = [PDTaskManager sharedManager];
    sharedManager.backgroundComplecationHandler = completionHandler;
}

@end
