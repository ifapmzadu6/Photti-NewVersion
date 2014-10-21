//
//  PSNewLocalHomeViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSNewLocalHomeViewController.h"

#import "PEAlbumListDataSource.h"
#import "PEMomentListDataSource.h"
#import "PEPhotoListDataSource.h"
#import "PEPhotoDataSourceFactoryMethod.h"

#import "PSImagePickerController.h"
#import "PSNewLocalPhotoListViewController.h"
#import "PSNewLocalAlbumListViewController.h"
#import "PSNewLocalMomentListViewController.h"

#import "PEPhotoListViewController.h"

@implementation PSNewLocalHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *cancelBarButtonitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelBarButtonAction)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonitem;
    UIBarButtonItem *doneBarButtonitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonAction)];
    self.navigationItem.rightBarButtonItem = doneBarButtonitem;
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        view.exclusiveTouch = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PATabBarAdsController *tabBarController = (PATabBarAdsController *)self.tabBarController;
    [tabBarController setAdsHidden:YES animated:NO];
}

#pragma mark UIBarButtonAction
- (void)doneBarButtonAction {
    PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
    [tabBarController doneBarButtonAction];
}

- (void)cancelBarButtonAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark SetUpDaraSource
- (void)setUpAlbumDataSource {
    self.albumListDataSource = [PEAlbumListDataSource new];
    self.albumListDataSource.cellSize = CGSizeMake(100.0f, 134.0f);
    self.albumListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
    self.albumListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection){
        typeof(wself) sself = wself;
        if (!sself) return;
        PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album];
        viewController.navigationItem.prompt = sself.navigationItem.prompt;
        [sself.navigationController pushViewController:viewController animated:YES];
    };
}

- (void)setUpMomentsDataSource {
    self.momentListDataSource = [PEMomentListDataSource new];
    self.momentListDataSource.cellSize = CGSizeMake(100.0f, 134.0f);
    self.momentListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
    self.momentListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection) {
        typeof(wself) sself = wself;
        if (!sself) return;
        NSString *title = [PEMomentListDataSource titleForMoment:assetCollection];
        PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album title:title];
        viewController.navigationItem.prompt = sself.navigationItem.prompt;
        [sself.navigationController pushViewController:viewController animated:YES];
    };
}

- (void)setUpVideoDataSource {
    self.videoListDataSource = [PEPhotoDataSourceFactoryMethod makeVideoListDataSource];
    self.videoListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
    self.videoListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
    self.videoListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
}

- (void)setUpPanoramaDataSource {
    self.panoramaListDataSource = [PEPhotoDataSourceFactoryMethod makePanoramaListDataSource];
    self.panoramaListDataSource.cellSize = CGSizeMake(270.0f, 100.0f);
    self.panoramaListDataSource.landscapeCellSize = CGSizeMake(270.0f, 100.0f);
    self.panoramaListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
}

- (void)setUpFavoriteDataSource {
    self.favoriteListDataSource = [PEPhotoDataSourceFactoryMethod makeFavoriteListDataSource];
    self.favoriteListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
    self.favoriteListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
    self.favoriteListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
}

- (void)setUpTimelapseDataSource {
    self.timelapseListDataSource = [PEPhotoDataSourceFactoryMethod makeTimelapseListDataSource];
    self.timelapseListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
    self.timelapseListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
    self.timelapseListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
}

- (void)setUpCloudDataSource {
    self.cloudListDataSource = [PEPhotoDataSourceFactoryMethod makeCloudListDataSource];
    self.cloudListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
    self.cloudListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
    self.cloudListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
}

- (void)setUpBurstsDataSource {
    self.burstsListDataSource = [PEPhotoDataSourceFactoryMethod makeBurstListDataSource];
    self.burstsListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
    self.burstsListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
    self.burstsListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
}

- (void)setUpSlomoVideosDataSource {
    self.slomoVideosListDataSource = [PEPhotoDataSourceFactoryMethod makeSlomoVideoListDataSource];
    self.slomoVideosListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
    self.slomoVideosListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
    self.slomoVideosListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
}

- (void)setUpAllPhotosDataSource {
    self.allPhotoListDataSource = [PEPhotoDataSourceFactoryMethod makeAllPhotoListDataSource];
    self.allPhotoListDataSource.cellSize = CGSizeMake(100.0f, 100.0f);
    self.allPhotoListDataSource.landscapeCellSize = CGSizeMake(100.0f, 100.0f);
    self.allPhotoListDataSource.minimumLineSpacing = 15.0f;
    __weak typeof(self) wself = self;
}

@end
