//
//  PLNavigationController.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/24.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLNavigationController.h"

#import "PAColors.h"
#import "PAIcons.h"
#import "PLAssetsManager.h"

#import "PATabBarAdsController.h"
#import "PLPageViewController.h"
#import "PABaseNavigationController.h"
#import "PLAccessPhotoLibraryViewController.h"
#import "PLAutoCreateAlbumViewController.h"
#import "PLNewAlbumCreatedViewController.h"

@interface PLNavigationController ()

@property (strong, nonatomic) UIImage *tabBarImageLandscape;
@property (strong, nonatomic) UIImage *tabBarImageLandspaceSelected;

@end

@implementation PLNavigationController

- (id)init {
    self = [super init];
    if (self) {
        NSString *title = NSLocalizedString(@"Camera Roll", nil);
        UIImage *tabBarImage = [UIImage imageNamed:@"Picture"];
        UIImage *tabBarImageSelected = [UIImage imageNamed:@"PictureSelected"];
        _tabBarImageLandscape = [PAIcons imageWithImage:[UIImage imageNamed:@"Picture"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        _tabBarImageLandspaceSelected = [PAIcons imageWithImage:[UIImage imageNamed:@"PictureSelected"] insets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:tabBarImage selectedImage:tabBarImageSelected];
        
        if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized) {
            PLAccessPhotoLibraryViewController *accessPhotoLibraryViewController = [PLAccessPhotoLibraryViewController new];
            __weak typeof(self) wself = self;
            accessPhotoLibraryViewController.completion = ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    typeof(wself) sself = wself;
                    if (!sself) return;
                    [sself setAutoCreateAlbumViewControllerAnimated:YES];
                });
            };
            self.viewControllers = @[accessPhotoLibraryViewController];
        }
        else if ([PLAssetsManager sharedManager].autoCreateAlbumType == PLAssetsManagerAutoCreateAlbumTypeUnknown) {
            [self setAutoCreateAlbumViewControllerAnimated:NO];
        }
        else {
            [self setPageViewControllerAnimated:NO];
        }
        
        [[PLAssetsManager sharedManager] enumurateAssetsWithCompletion:^(NSError *error) {
            if (error) return;
        }];
        
        __weak typeof(self) wself = self;
        [PLAssetsManager sharedManager].libraryUpDateBlock = ^(NSDate *enumuratedDate, NSUInteger newAlbumCount) {
            typeof(wself) sself = wself;
            if (!sself) return;
            
            if (newAlbumCount == 0) return;
            if (newAlbumCount > 7) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sself modalNewAlbumCreatedViewControllerAnimated:YES enumuratedDate:enumuratedDate];
            });
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationBar.tintColor = [PAColors getColor:PAColorsTypeTintLocalColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    UINavigationItem *item = self.navigationBar.items.firstObject;
    [item.titleView setNeedsLayout];
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

#pragma mark AutoCreateViewController
- (void)setPageViewControllerAnimated:(BOOL)animated {
    UIViewController *viewController = self.viewControllers.firstObject;
    if (![viewController isKindOfClass:[PLPageViewController class]]) {
        PLPageViewController *pageViewcontroller = [[PLPageViewController alloc] init];
        [self setViewControllers:@[pageViewcontroller] animated:animated];
    }
}

- (void)setAutoCreateAlbumViewControllerAnimated:(BOOL)animated {
    PLAutoCreateAlbumViewController *autoCreateAlbumViewController = [[PLAutoCreateAlbumViewController alloc] init];
    __weak typeof(self) wself = self;
    autoCreateAlbumViewController.completion = ^{
        typeof(wself) sself = wself;
        if (!sself) return;
        PLPageViewController *pageViewcontroller = [[PLPageViewController alloc] init];
        [sself setViewControllers:@[pageViewcontroller] animated:YES];
        
        [[PLAssetsManager sharedManager] enumurateAssetsWithCompletion:nil];
    };
    [self setViewControllers:@[autoCreateAlbumViewController] animated:animated];
}

- (void)modalNewAlbumCreatedViewControllerAnimated:(BOOL)animated enumuratedDate:(NSDate *)enumuratedDate {
    PLNewAlbumCreatedViewController *viewController = [[PLNewAlbumCreatedViewController alloc] initWithEnumuratedDate:enumuratedDate];
    PABaseNavigationController *navigationController = [[PABaseNavigationController alloc] initWithRootViewController:viewController];
    [self.tabBarController presentViewController:navigationController animated:animated completion:nil];
}

#pragma mark UINavigationBarDelegate
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTop;
}

@end
