//
//  PWNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWNavigationController.h"

#import "PWColors.h"
#import "PWIcons.h"
#import "PWOAuthManager.h"

#import "PWAlbumListViewController.h"
#import "PWGoogleLoginViewController.h"
#import "PWTabBarController.h"


@interface PWNavigationController () <UINavigationBarDelegate>

@end

@implementation PWNavigationController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Web Album", nil);
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"Picasa"] selectedImage:[UIImage imageNamed:@"PicasaSelected"]];
        
        if ([PWOAuthManager isLogined]) {
            PWAlbumListViewController *albumListViewController = [[PWAlbumListViewController alloc] init];
            self.viewControllers = @[albumListViewController];
        }
        else {
            [self setLoginViewController];
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
        [self setLoginViewController];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UITabBarItem
- (void)updateTabBarItem {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            self.tabBarItem.image = [PWIcons imageWithImage:[UIImage imageNamed:@"Picasa"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
            self.tabBarItem.selectedImage = [PWIcons imageWithImage:[UIImage imageNamed:@"PicasaSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        }
        else {
            self.tabBarItem.image = [UIImage imageNamed:@"Picasa"];
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"PicasaSelected"];
        }
    }
}

#pragma mark LoginViewController
- (void)setLoginViewController {
    UIViewController *viewController = self.viewControllers.firstObject;
    if (![viewController isKindOfClass:[PWGoogleLoginViewController class]]) {
        PWGoogleLoginViewController *googleLoginViewController = [[PWGoogleLoginViewController alloc] init];
        __weak typeof(self) wself = self;
        googleLoginViewController.completion = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                UIViewController *viewController = sself.viewControllers.firstObject;
                if (![viewController isKindOfClass:[PWAlbumListViewController class]]) {
                    PWAlbumListViewController *albumListViewController = [[PWAlbumListViewController alloc] init];
                    [sself setViewControllers:@[albumListViewController] animated:YES];
                }
            });
        };
        googleLoginViewController.skipAction = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                
                PWTabBarController *tabBarController = (PWTabBarController *)sself.tabBarController;
                [tabBarController setSelectedIndex:0];
            });
        };
        [self setViewControllers:@[googleLoginViewController] animated:NO];
    }
}

@end
