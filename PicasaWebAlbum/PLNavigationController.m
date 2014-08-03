//
//  PLNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLNavigationController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PLAssetsManager.h"

#import "PLPageViewController.h"
#import "PWBaseNavigationController.h"
#import "PLAccessPhotoLibraryViewController.h"
#import "PLAutoCreateAlbumViewController.h"
#import "PLNewAlbumCreatedViewController.h"

@interface PLNavigationController ()

@end

@implementation PLNavigationController

- (id)init {
    self = [super init];
    if (self) {
        NSString *title = NSLocalizedString(@"Camera Roll", nil);
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:@"Picture"] selectedImage:[UIImage imageNamed:@"PictureSelected"]];
        
        if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
            PLAccessPhotoLibraryViewController *accessPhotoLibraryViewController = [[PLAccessPhotoLibraryViewController alloc] init];
            __weak typeof(self) wself = self;
            accessPhotoLibraryViewController.completion = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    [sself setAutoCreateAlbumViewController];
                });
            };
            self.viewControllers = @[accessPhotoLibraryViewController];
        }
        else if ([PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeUnknown) {
            [self setAutoCreateAlbumViewController];
        }
        else {
            PLPageViewController *pageViewcontroller = [[PLPageViewController alloc] init];
            self.viewControllers = @[pageViewcontroller];            
        }
        
        [[PLAssetsManager sharedManager] enumurateAssetsWithCompletion:^(NSError *error) {
            if (error) return;
        }];
        
        __weak typeof(self) wself = self;
        [PLAssetsManager sharedManager].libraryUpDateBlock = ^(NSDate *enumuratedDate, NSUInteger newAlbumCount) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (newAlbumCount == 0) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                PLNewAlbumCreatedViewController *viewController = [[PLNewAlbumCreatedViewController alloc] initWithEnumuratedDate:enumuratedDate];
                PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
                [sself.tabBarController presentViewController:navigationController animated:YES completion:nil];
            });
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    PLNewAlbumCreatedViewController *viewController = [[PLNewAlbumCreatedViewController alloc] initWithEnumuratedDate:nil];
//    PWBaseNavigationController *navigationController = [[PWBaseNavigationController alloc] initWithRootViewController:viewController];
//    [self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UINavigationItem *item = self.navigationBar.items.firstObject;
    [item.titleView setNeedsLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITabBarItem
- (void)updateTabBarItem {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            self.tabBarItem.image = [PWIcons imageWithImage:[UIImage imageNamed:@"Picture"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
            self.tabBarItem.selectedImage = [PWIcons imageWithImage:[UIImage imageNamed:@"PictureSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        }
        else {
            self.tabBarItem.image = [UIImage imageNamed:@"Picture"];
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"PictureSelected"];
        }
    }
}

#pragma mark AutoCreateViewController
- (void)setAutoCreateAlbumViewController {
    PLAutoCreateAlbumViewController *autoCreateAlbumViewController = [[PLAutoCreateAlbumViewController alloc] init];
    __weak typeof(self) wself = self;
    autoCreateAlbumViewController.completion = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PLPageViewController *pageViewcontroller = [[PLPageViewController alloc] init];
        [sself setViewControllers:@[pageViewcontroller] animated:YES];
        
        [[PLAssetsManager sharedManager] enumurateAssetsWithCompletion:nil];
    };
    [self setViewControllers:@[autoCreateAlbumViewController] animated:YES];
}

#pragma mark UINavigationBarDelegate
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTop;
}

@end
