//
//  PSNewLocalAlbumListViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSNewLocalAlbumListViewController.h"

#import "PEAlbumListDataSource.h"

#import "PATabBarAdsController.h"
#import "PSNewLocalPhotoListViewController.h"

@implementation PSNewLocalAlbumListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self) wself = self;
        self.albumListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album];
            viewController.navigationItem.prompt = sself.navigationItem.prompt;
            [sself.navigationController pushViewController:viewController animated:YES];
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setToolbarHidden:YES animated:NO completion:nil];
}

@end
