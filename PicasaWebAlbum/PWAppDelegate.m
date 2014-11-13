//
//  PWAppDelegate.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAppDelegate.h"

#import <Crashlytics/Crashlytics.h>
#import <GAI.h>
#import <SDImageCache.h>
#import <UAAppReviewManager.h>
#import <SKNotificationManager.h>

#import "PAColors.h"
#import "PWPicasaAPI.h"
#import "PDTaskManager.h"
#import "PLAssetsManager.h"
#import "PADateFormatter.h"
#import "PAInAppPurchase.h"
#import "PWCoreDataAPI.h"
#import "PLCoreDataAPI.h"
#import "PDCoreDataAPI.h"
#import "PAAlertControllerKit.h"

#import "PWNavigationController.h"
#import "PLNavigationController.h"
#import "PENavigationController.h"
#import "PEHomeViewController.h"
#import "PATabBarAdsController.h"
#import "PAMigrationViewController.h"

@implementation PWAppDelegate

static NSString * const kPWAppDelegateBackgroundFetchDateKey = @"kPWADBFDK";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // OAuth
    [PWOAuthManager refreshKeychain];
    
    // Background Fetch
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // NSLocalNotification
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    // User Defaults
    NSDictionary *userDefaults = @{kPDTaskManagerIsResizePhotosKey: @YES,
                                   kPWAppDelegateBackgroundFetchDateKey: [NSDate date],
                                   kPEHomeViewControllerUserDefaultsEnabledItemKey: [PEHomeViewController defaultEnabledItems]};
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Crashlytics
    [Crashlytics startWithAPIKey:CLASHLYTICSID];
    
    // UAAppReviewManager
    [UAAppReviewManager setAppID:APPID];
    [UAAppReviewManager showPromptIfNecessary];
    
    // Google Analytics
    [GAI sharedInstance].dispatchInterval = 30;
    [[GAI sharedInstance] trackerWithTrackingId:GOOGLEANALYTICSID];
    [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:YES];
    
    // SKNotification
    NSString *lang = [[NSUserDefaults standardUserDefaults] arrayForKey:@"AppleLanguages"].firstObject;
    NSString *jsonURL = [NSString stringWithFormat:@"http://54.64.82.148/%@/gioqulo.json", lang];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:jsonURL]];
    [SKNotificationManager setJSONRequest:request];
    [SKNotificationManager appLaunched];
    NSString *idfaURL = @"http://54.64.82.148/";
    [SKNotificationManager sharedManager].notificationViewTappedAction = ^(SKNotification *notification) {
        NSNumber *appID = @(notification.appid.integerValue);
        [SKNotificationIDFAManager tappedAdsenceWithAppID:appID serverURL:idfaURL];
    };
    [SKNotificationIDFAManager appLaunched:@(APPID.longLongValue) serverURL:idfaURL];
    
    // TaskManager
    [PDTaskManager sharedManager].notAllowedAccessPhotoLibraryAction = ^{
        [PAAlertControllerKit showNotPermittedToPhotoLibrary];
    };
    [PDTaskManager sharedManager].notLoginGoogleAccountAction = ^{
        [PAAlertControllerKit showYouNeedToLoginWebAlbum];
    };
    
    UIViewController *rootViewController = nil;
    if ([PWCoreDataAPI shouldPerformCoreDataMigration] || [PDCoreDataAPI shouldPerformCoreDataMigration]) {
        rootViewController = [self migrationViewController];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [PWCoreDataAPI readContext];
            [PDCoreDataAPI readContext];
            
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
    UIViewController *localNavigationController = nil;
    if (UIDevice.currentDevice.systemVersion.floatValue >= 8.0f) {
        localNavigationController = [PENavigationController new];;
    }
    else {
        localNavigationController = [PLNavigationController new];
    }
    PWNavigationController *webNavigationViewController = [PWNavigationController new];
    
    NSUInteger initialTabPageIndex = 0;
    NSArray *viewControllers = @[localNavigationController, webNavigationViewController];
    NSArray *colors = @[[PAColors getColor:kPAColorsTypeTintLocalColor], [PAColors getColor:kPAColorsTypeTintWebColor]];
    
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
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kPWAppDelegateBackgroundFetchDateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [PWOAuthManager refreshKeychain];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [PWOAuthManager refreshKeychain];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

#pragma mark KeyChain
- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
    [PWOAuthManager refreshKeychain];
}

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application {
}

#pragma mark Local Notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
}

#pragma mark Background Fetch
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[PDTaskManager sharedManager] start];
    
    [PAAnalytics sendEventWithClass:self.class action:@"Background Fetch"];
    
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
