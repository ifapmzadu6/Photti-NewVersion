//
//  PDNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/23.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PDNavigationController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PDTaskManager.h"
#import "PDCoreDataAPI.h"
#import "PAInAppPurchase.h"

#import "PATabBarAdsController.h"

#import "PDTaskManagerViewController.h"
#import "PDUploadDescriptionViewController.h"

@interface PDNavigationController ()

@property (strong, nonatomic) UIImage *tabBarImageLandscape;
@property (strong, nonatomic) UIImage *tabBarImageLandspaceSelected;

@end

@implementation PDNavigationController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Tasks", @"l");
        UIImage *tabBarImage = [UIImage imageNamed:@"Upload"];
        UIImage *tabBarImageSelected = [UIImage imageNamed:@"UploadSelect"];
        _tabBarImageLandscape = [PAIcons imageWithImage:tabBarImage insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        _tabBarImageLandspaceSelected = [PAIcons imageWithImage:tabBarImageSelected insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:tabBarImage selectedImage:tabBarImageSelected];
        
        [self checkTaskIsNone];
        [self badgeUpdate];
        
        [self setTaskManagerChangedBlock];
        [self setTaskManagerNotAllowedAccessPhotoLibraryBlock];
        [self setTaskManagerNotLoginGoogleAccountBlock];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:kPAColorsTypeBackgroundLightColor];
    
    self.navigationBar.tintColor = [PAColors getColor:kPAColorsTypeTintUploadColor];
}

#pragma mark UITabBarItem
- (void)updateTabBarItem {
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    if (tabBarController.isPhone) {
        if (tabBarController.isLandscape) {
            self.tabBarItem.image = _tabBarImageLandscape;
            self.tabBarItem.selectedImage = _tabBarImageLandspaceSelected;
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
                
                [sself showTaskManagerViewControllerAnimated:YES];
            });
        }
        else {
            [[PDTaskManager sharedManager] getRequestingTasksWithCompletion:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    
                    if (dataTasks.count == 0 && uploadTasks.count == 0 && downloadTasks.count == 0) {
                        [sself setUploadDescriptionViewControllerAnimated:YES];
                    }
                    else {
                        [sself showTaskManagerViewControllerAnimated:YES];
                    }
                });
            }];
        }
    }];
}

- (void)setUploadDescriptionViewControllerAnimated:(BOOL)animated {
    UIViewController *viewController = self.viewControllers.firstObject;
    if (![viewController isKindOfClass:[PDUploadDescriptionViewController class]]) {
        PDUploadDescriptionViewController *viewController = [PDUploadDescriptionViewController new];
        [self setViewControllers:@[viewController] animated:animated];
    }
}

- (void)showTaskManagerViewControllerAnimated:(BOOL)animated {
    UIViewController *viewController = self.viewControllers.firstObject;
    if (![viewController isKindOfClass:[PDTaskManagerViewController class]]) {
        PDTaskManagerViewController *taskManagerViewController = [PDTaskManagerViewController new];
        [self setViewControllers:@[taskManagerViewController] animated:animated];
    }
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

- (void)setTaskManagerNotLoginGoogleAccountBlock {
    PDTaskManager *taskManager = [PDTaskManager sharedManager];
    taskManager.notLoginGoogleAccountAction = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You need to login Web Album.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
        });
    };
}

@end
