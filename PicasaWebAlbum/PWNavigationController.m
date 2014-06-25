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

@interface PWNavigationController ()

@end

@implementation PWNavigationController

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Web Album", nil);
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:self.title image:[UIImage imageNamed:@"Picasa"] selectedImage:[UIImage imageNamed:@"PicasaSelected"]];
        
        [PWOAuthManager logout];
        
        if ([PWOAuthManager isLogined]) {
            PWAlbumListViewController *albumListViewController = [[PWAlbumListViewController alloc] init];
            self.viewControllers = @[albumListViewController];
        }
        else {
            PWGoogleLoginViewController *googleLoginViewController = [[PWGoogleLoginViewController alloc] init];
            __weak typeof(self) wself = self;
            [googleLoginViewController setCompletion:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    
                    PWAlbumListViewController *albumListViewController = [[PWAlbumListViewController alloc] init];
                    [sself setViewControllers:@[albumListViewController] animated:YES];
                });
            }];
            self.viewControllers = @[googleLoginViewController];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.tintColor = [PWColors getColor:PWColorsTypeTintWebColor];
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
        self.tabBarItem.image = [PWIcons imageWithImage:[UIImage imageNamed:@"Picasa"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        self.tabBarItem.selectedImage = [PWIcons imageWithImage:[UIImage imageNamed:@"PicasaSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
    }
    else {
        self.tabBarItem.image = [UIImage imageNamed:@"Picasa"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"PicasaSelected"];
    }
}

@end
