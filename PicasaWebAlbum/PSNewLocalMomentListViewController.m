//
//  PSNewLocalMomentListViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSNewLocalMomentListViewController.h"

#import "PEMomentListDataSource.h"
#import "PATabBarAdsController.h"
#import "PSNewLocalPhotoListViewController.h"

@implementation PSNewLocalMomentListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        __weak typeof(self) wself = self;
        self.dataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection){
            typeof(wself) sself = wself;
            if (!sself) return;
            PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:assetCollection type:kPHPhotoListViewControllerType_Album];
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
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
}

@end
