//
//  PWNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWNavigationController.h"

#import "PWAppDelegate.h"
#import "PAColors.h"
#import "PAIcons.h"
#import "PWOAuthManager.h"

#import "PWAlbumListViewController.h"
#import "PWGoogleLoginViewController.h"
#import "PWTabBarAdsController.h"

@interface PWNavigationController () <UINavigationBarDelegate>

@property (strong, nonatomic) UIImage *tabBarImageLandscape;
@property (strong, nonatomic) UIImage *tabBarImageLandspaceSelected;

@end

@implementation PWNavigationController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Web Album", nil);
        UIImage *tabBarImage = [UIImage imageNamed:@"Picasa"];
        UIImage *tabBarImageSelected = [UIImage imageNamed:@"PicasaSelected"];
        _tabBarImageLandscape = [PAIcons imageWithImage:tabBarImage insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        _tabBarImageLandspaceSelected = [PAIcons imageWithImage:tabBarImageSelected insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:tabBarImage selectedImage:tabBarImageSelected];
        
        if ([PWOAuthManager isLogined]) {
            [self setAlbumViewControllerAnimated:NO];
        }
        else {
            [self setLoginViewControllerAnimated:NO];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeAll;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![PWOAuthManager isLogined]) {
        [self setLoginViewControllerAnimated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITabBarItem
- (void)updateTabBarItem {
    PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)self.tabBarController;
    if (tabBarController.isPhone) {
        if (tabBarController.isLandscape) {
            self.tabBarItem.image = _tabBarImageLandscape;
            self.tabBarItem.selectedImage = _tabBarImageLandspaceSelected;
        }
        else {
            self.tabBarItem.image = [UIImage imageNamed:@"Picasa"];
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"PicasaSelected"];
        }
    }
}

#pragma mark AlbumViewController
- (void)setAlbumViewControllerAnimated:(BOOL)animated {
    UIViewController *viewController = self.viewControllers.firstObject;
    if (![viewController isKindOfClass:[PWAlbumListViewController class]]) {
        PWAlbumListViewController *albumListViewController = [PWAlbumListViewController new];
        [self setViewControllers:@[albumListViewController] animated:animated];
    }
}

#pragma mark LoginViewController
- (void)setLoginViewControllerAnimated:(BOOL)animated {
    UIViewController *viewController = self.viewControllers.firstObject;
    if (![viewController isKindOfClass:[PWGoogleLoginViewController class]]) {
        PWGoogleLoginViewController *googleLoginViewController = [PWGoogleLoginViewController new];
        __weak typeof(self) wself = self;
        googleLoginViewController.completion = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                [sself setAlbumViewControllerAnimated:YES];
            });
        };
        googleLoginViewController.skipAction = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                PWTabBarAdsController *tabBarController = (PWTabBarAdsController *)sself.tabBarController;
                [tabBarController setSelectedIndex:0];
            });
        };
        [self setViewControllers:@[googleLoginViewController] animated:animated];
    }
}

@end
