//
//  PWAppDelegate.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAppDelegate.h"

#import <Crashlytics/Crashlytics.h>

#import "PWTabBarController.h"

#import "SDImageCache.h"

#import "PDTaskManager.h"
#import "PLAssetsManager.h"
#import "PLDateFormatter.h"

#import "PWPicasaAPI.h"

@implementation PWAppDelegate

static NSString * const kPWAppDelegateBackgroundFetchDateKey = @"kPWADBFDK";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{kPDTaskManagerIsResizePhotosKey: @(YES),
                                                              kPWAppDelegateBackgroundFetchDateKey: [NSDate date]}];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [Crashlytics startWithAPIKey:@"e304869e1f84a6d87002a3e24fd4a640cfff713f"];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[PWTabBarController alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [[[NSURLSession sharedSession] configuration] setURLCache:nil];
    
    [[PDTaskManager sharedManager] cancel];
    [PWPicasaAPI getAuthorizedURLRequest:[NSURL URLWithString:@""] completion:^(NSMutableURLRequest *request, NSError *error) {
        [[PDTaskManager sharedManager] start];
    }];
    
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


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    
}

#pragma mark Background Fetch
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[PDTaskManager sharedManager] start];
    
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(24 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completionHandler(UIBackgroundFetchResultNoData);
    });
}

#pragma mark Background Transfer
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
//    NSLog(@"%s", __func__);
    
    PDTaskManager *sharedManager = [PDTaskManager sharedManager];
    sharedManager.backgroundComplecationHandler = completionHandler;
}

@end
