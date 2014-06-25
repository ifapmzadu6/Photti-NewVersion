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
#import "PLAccessPhotoLibraryViewController.h"
#import "PLAutoCreateAlbumViewController.h"

@interface PLNavigationController ()

@end

@implementation PLNavigationController

- (id)init {
    self = [super init];
    if (self) {
        NSString *title = NSLocalizedString(@"Camera Roll", nil);
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:@"Picture"] selectedImage:[UIImage imageNamed:@"PictureSelected"]];
        
        if ([PLAssetsManager getAuthorizationStatus] != ALAuthorizationStatusAuthorized) {
            PLAccessPhotoLibraryViewController *accessPhotoLibraryViewController = [[PLAccessPhotoLibraryViewController alloc] init];
            self.viewControllers = @[accessPhotoLibraryViewController];
        }
        else if ([PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeUnknown) {
            PLAutoCreateAlbumViewController *autoCreateAlbumViewController = [[PLAutoCreateAlbumViewController alloc] init];
            __weak typeof(self) wself = self;
            autoCreateAlbumViewController.completion = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PLPageViewController *pageViewcontroller = [[PLPageViewController alloc] init];
                [sself setViewControllers:@[pageViewcontroller] animated:YES];
            };
            self.viewControllers = @[autoCreateAlbumViewController];
        }
        else {
            PLPageViewController *pageViewcontroller = [[PLPageViewController alloc] init];
            self.viewControllers = @[pageViewcontroller];            
        }        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintLocalColor];
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [PWColors getColor:PWColorsTypeTextColor]};
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
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        self.tabBarItem.image = [PWIcons imageWithImage:[UIImage imageNamed:@"Picture"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        self.tabBarItem.selectedImage = [PWIcons imageWithImage:[UIImage imageNamed:@"PictureSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    }
    else {
        self.tabBarItem.image = [UIImage imageNamed:@"Picture"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"PictureSelected"];
    }
}

@end
