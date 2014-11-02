//
//  PSNewLocalPhotoListViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSNewLocalPhotoListViewController.h"

#import "PEPhotoListDataSource.h"

#import "PATabBarAdsController.h"
#import "PSImagePickerController.h"

@implementation PSNewLocalPhotoListViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type title:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    self = [super initWithAssetCollection:assetCollection type:type title:title startDate:startDate endDate:endDate];
    if (self) {
        self.photoListDataSource.isSelectMode = YES;
        __weak typeof(self) wself = self;
        self.photoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
            [tabBarController addSelectedPhoto:asset];
        };
        self.photoListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
            typeof(wself) sself = wself;
            if (!sself) return;
            PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
            [tabBarController removeSelectedPhoto:asset];
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
    
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.photoListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
    });
    
    [tabBarController setUserInteractionEnabled:NO];
}

@end
