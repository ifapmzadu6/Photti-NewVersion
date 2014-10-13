//
//  PHNavigationControllerViewController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/20.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PENavigationController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PEAssetsManager.h"
#import "PEHomeViewController.h"
#import "PATabBarAdsController.h"
#import "PLAccessPhotoLibraryViewController.h"

@interface PENavigationController ()

@property (strong, nonatomic) UIImage *tabBarImageLandscape;
@property (strong, nonatomic) UIImage *tabBarImageLandspaceSelected;

@end

@implementation PENavigationController

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *title = NSLocalizedString(@"Camera Roll", nil);
        UIImage *tabBarImage = [UIImage imageNamed:@"Picture"];
        UIImage *tabBarImageSelected = [UIImage imageNamed:@"PictureSelected"];
        _tabBarImageLandscape = [PAIcons imageWithImage:[UIImage imageNamed:@"Picture"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        _tabBarImageLandspaceSelected = [PAIcons imageWithImage:[UIImage imageNamed:@"PictureSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:tabBarImage selectedImage:tabBarImageSelected];
        
        if (![PEAssetsManager isStatusAuthorized]) {
            PLAccessPhotoLibraryViewController *accessPhotoLibraryViewController = [PLAccessPhotoLibraryViewController new];
            __weak typeof(self) wself = self;
            accessPhotoLibraryViewController.completion = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    PEHomeViewController *homeViewController = [PEHomeViewController new];
                    [sself setViewControllers:@[homeViewController] animated:YES];
                });
            };
            self.viewControllers = @[accessPhotoLibraryViewController];
        }
        else {
            PEHomeViewController *homeViewController = [PEHomeViewController new];
            self.viewControllers = @[homeViewController];
        }
    
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [PAColors getColor:PAColorsTypeBackgroundLightColor];
    self.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
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
            self.tabBarItem.image = [UIImage imageNamed:@"Picture"];
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"PictureSelected"];
        }
    }
}

#pragma mark UINavigationBarDelegate
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTop;
}

@end
