//
//  PWAlbumPickerNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumPickerNavigationController.h"

#import "PAColors.h"

@interface PWAlbumPickerNavigationController ()

@end

@implementation PWAlbumPickerNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationBar.barTintColor = [UIColor blackColor];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

#pragma mark UITabBarItem
- (void)updateTabBarItem {
    for (UIViewController *viewController in self.viewControllers) {
        if ([viewController respondsToSelector:@selector(updateTabBarItem)]) {
            [viewController performSelector:@selector(updateTabBarItem)];
        }
    }
}

@end
