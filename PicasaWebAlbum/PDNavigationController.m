//
//  PDNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDNavigationController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"
#import "PDInAppPurchase.h"
#import "BlocksKit+UIKit.h"

#import "PWTabBarController.h"

#import "PDTaskManagerViewController.h"
#import "PDUploadDescriptionViewController.h"

@interface PDNavigationController ()

@end

@implementation PDNavigationController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Tasks", @"l");
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"Upload"] selectedImage:[UIImage imageNamed:@"UploadSelect"]];
        
//        [PDInAppPurchase resetKeyChain];
        
        [self checkTaskIsNone];
        [self badgeUpdate];
        
        [self setTaskManagerChangedBlock];
        [self setTaskManagerNotAllowedAccessPhotoLibraryBlock];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PWColors getColor:PWColorsTypeBackgroundLightColor];
    
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
    self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintUploadColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITabBarItem
- (void)updateTabBarItem {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            self.tabBarItem.image = [PWIcons imageWithImage:[UIImage imageNamed:@"Upload"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
            self.tabBarItem.selectedImage = [PWIcons imageWithImage:[UIImage imageNamed:@"UploadSelect"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        }
        else {
            self.tabBarItem.image = [UIImage imageNamed:@"Upload"];
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"UploadSelect"];
        }
    }
}

#pragma mark BadgeUpdate
- (void)badgeUpdate {
    __weak typeof(self) wself = self;
    PDTaskManager *taskManager = [PDTaskManager sharedManager];
    [taskManager countOfAllPhotosInTaskWithCompletion:^(NSUInteger count, NSError *error) {
        if (error) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            [UIApplication sharedApplication].applicationIconBadgeNumber = count;
            
            if (count > 0) {
                sself.tabBarItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)count];
            }
            else {
                sself.tabBarItem.badgeValue = nil;
            }
        });
    }];
}

- (void)checkTaskIsNone {
    __weak typeof(self) wself = self;
    [[PDTaskManager sharedManager] countOfAllPhotosInTaskWithCompletion:^(NSUInteger count, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) return;
        
        if (count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                UIViewController *viewController = sself.viewControllers.firstObject;
                if (![viewController isKindOfClass:[PDTaskManagerViewController class]]) {
                    [sself showTaskManagerViewController];
                }
            });
        }
        else {
            [[PDTaskManager sharedManager] getRequestingTasksWithCompletion:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    
                    if (dataTasks.count == 0 && uploadTasks.count == 0 && downloadTasks.count == 0) {
                        UIViewController *viewController = sself.viewControllers.firstObject;
                        if (![viewController isKindOfClass:[PDUploadDescriptionViewController class]]) {
                            [sself showUploadDescriptionViewController];
                        }
                    }
                    else {
                        UIViewController *viewController = sself.viewControllers.firstObject;
                        if (![viewController isKindOfClass:[PDTaskManagerViewController class]]) {
                            [sself showTaskManagerViewController];
                        }
                    }
                });
            }];
        }
    }];
}

- (void)showUploadDescriptionViewController {
    PDUploadDescriptionViewController *viewController = [[PDUploadDescriptionViewController alloc] init];
    [self setViewControllers:@[viewController] animated:YES];
}

- (void)showTaskManagerViewController {
    PDTaskManagerViewController *taskManagerViewController = [[PDTaskManagerViewController alloc] init];
    [self setViewControllers:@[taskManagerViewController] animated:YES];
}

#pragma mark PDTaskManager
- (void)setTaskManagerChangedBlock {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskManagerChangedBlock) name:NSManagedObjectContextDidSaveNotification object:[PDCoreDataAPI readContext]];
}

- (void)taskManagerChangedBlock {
    [self badgeUpdate];
    [self checkTaskIsNone];
}

- (void)setTaskManagerNotAllowedAccessPhotoLibraryBlock {
    PDTaskManager *taskManager = [PDTaskManager sharedManager];
    taskManager.notAllowedAccessPhotoLibraryAction = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Go to Settings > Privacy > Photos and switch Photti to ON to access Photo Library.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
        });
    };
}

@end
