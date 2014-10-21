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

@implementation PSNewLocalPhotoListViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(PHPhotoListViewControllerType)type title:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    self = [super initWithAssetCollection:assetCollection type:type title:title startDate:startDate endDate:endDate];
    if (self) {
        self.photoListDataSource.isSelectMode = YES;
        self.photoListDataSource.didSelectAssetBlock = nil;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setUserInteractionEnabled:NO];
}

@end
