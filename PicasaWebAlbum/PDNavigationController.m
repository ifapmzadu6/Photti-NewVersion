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
#import "PDInAppPurchase.h"
#import "BlocksKit+UIKit.h"

#import "PDTaskManagerViewController.h"
#import "PDInAppPurchaseViewController.h"
#import "PDUploadDescriptionViewController.h"

@interface PDNavigationController ()

@end

@implementation PDNavigationController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Task Manager", nil);
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"Upload"] selectedImage:[UIImage imageNamed:@"UploadSelect"]];
        
        [PDInAppPurchase resetKeyChain];
        
        if (![PDInAppPurchase isPurchasedWithKey:kPDUploadAndDownloadPuroductID]) {
            PDInAppPurchaseViewController *inAppPurchaseViewController = [[PDInAppPurchaseViewController alloc] init];
            self.viewControllers = @[inAppPurchaseViewController];
        }
        else {
            [self checkTaskIsNone];
            [self badgeUpdate];
        }
        
        [self setInAppPurchaseBlocks];
        [self setTaskManagerChangedBlock];
        [self setTaskManagerNotPurchaseBlock];
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
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        self.tabBarItem.image = [PWIcons imageWithImage:[UIImage imageNamed:@"Upload"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        self.tabBarItem.selectedImage = [PWIcons imageWithImage:[UIImage imageNamed:@"UploadSelect"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    }
    else {
        self.tabBarItem.image = [UIImage imageNamed:@"Upload"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"UploadSelect"];
    }
}

#pragma mark BadgeUpdate
- (void)badgeUpdate {
    __weak typeof(self) wself = self;
    PDTaskManager *taskManager = [PDTaskManager sharedManager];
    [taskManager countOfAllPhotosInTaskWithCompletion:^(NSUInteger count, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) return;
        
        if (count > 0) {
            sself.tabBarItem.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)count];
        }
        else {
            sself.tabBarItem.badgeValue = nil;
        }
    }];
}

- (void)checkTaskIsNone {
    __weak typeof(self) wself = self;
    [[PDTaskManager sharedManager] countOfAllPhotosInTaskWithCompletion:^(NSUInteger count, NSError *error) {
        typeof(wself) sself = wself;
        if (!sself) return;
        if (error) return;
        
        [[PDTaskManager sharedManager] getRequestingTasksWithCompletion:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                if (dataTasks.count == 0 && uploadTasks.count == 0 && downloadTasks.count == 0) {
                    [sself showUploadDescriptionViewController];
                }
                else {
                    [sself showTaskManagerViewController];
                }
            });
        }];
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
    __weak typeof(self) wself = self;
    PDTaskManager *taskManager = [PDTaskManager sharedManager];
    [taskManager setTaskManagerChangedBlock:^(PDTaskManager *taskManager){
        typeof(wself) sself = wself;
        if (!sself) return;
        
        [sself badgeUpdate];
        [sself checkTaskIsNone];
    }];
}

- (void)setTaskManagerNotPurchaseBlock {
    PDTaskManager *taskManager = [PDTaskManager sharedManager];
    __weak typeof(self) wself = self;
    taskManager.notPurchasedUploadDownloadAction = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            
            sself.tabBarController.selectedIndex = 2;
        });
    };
}

#pragma mark PDInAppPurchase
- (void)setInAppPurchaseBlocks {
    PDInAppPurchase *inAppPurchase = [PDInAppPurchase sharedInstance];
    __weak typeof(self) wself = self;
    [inAppPurchase setPaymentQueuePurchaced:^(NSArray *transactions, bool success) {
        if (!success) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself checkTaskIsNone];
        });
    }];
    [inAppPurchase setPaymentQueueRestored:^(NSArray *transactions, bool success) {
        if (!success) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(wself) sself = wself;
            if (!sself) return;
            [sself checkTaskIsNone];
        });
    }];
}

@end
