//
//  PWAppDelegate.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAppDelegate.h"

#import "PWTabBarController.h"

#import "SDImageCache.h"

//Test
#import "PDTaskManager.h"

@implementation PWAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[PWTabBarController alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [[SDImageCache sharedImageCache] setMaxMemoryCost:10 * 10^6];
//    [[[NSURLSession sharedSession] configuration] setURLCache:nil];
    [[NSURLSession sharedSession] configuration].URLCache.memoryCapacity = 0;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    NSLog(@"%s", __func__);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"%s", __func__);
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"%s", __func__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"%s", __func__);
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"%s", __func__);
}

#pragma mark Background Fetch
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"%s", __func__);
        
    completionHandler(UIBackgroundFetchResultNoData);
}

#pragma mark Background Transfer
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSLog(@"%s", __func__);
    
    [PDTaskManager resumeAllTasks];
    
    completionHandler();
}

@end
