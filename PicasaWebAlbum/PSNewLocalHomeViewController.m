//
//  PSNewLocalHomeViewController.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PSNewLocalHomeViewController.h"

#import "PAPhotoKit.h"
#import "PEAlbumListDataSource.h"
#import "PEMomentListDataSource.h"
#import "PEPhotoListDataSource.h"
#import "PEPhotoDataSourceFactoryMethod.h"

#import "PSImagePickerController.h"
#import "PSNewLocalPhotoListViewController.h"
#import "PSNewLocalAlbumListViewController.h"
#import "PSNewLocalMomentListViewController.h"

#import "PSNewLocalPhotoListViewController.h"
#import "PECategoryViewCell.h"
#import "PAHorizontalScrollView.h"

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
    [super setUpAlbumDataSource];
    
    __weak typeof(self) wself = self;
    self.albumListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection){
        typeof(wself) sself = wself;
        if (!sself) return;
        PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:assetCollection type:kPHPhotoListViewControllerType_Album];
        viewController.navigationItem.prompt = sself.navigationItem.prompt;
        [sself.navigationController pushViewController:viewController animated:YES];
    };
}

- (void)setUpMomentsDataSource {
    [super setUpMomentsDataSource];
    
    __weak typeof(self) wself = self;
    self.momentListDataSource.didSelectCollectionBlock = ^(PHAssetCollection *assetCollection) {
        typeof(wself) sself = wself;
        if (!sself) return;
        NSString *title = [PAPhotoKit titleForMoment:assetCollection];
        PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:assetCollection type:kPHPhotoListViewControllerType_Album title:title];
        viewController.navigationItem.prompt = sself.navigationItem.prompt;
        [sself.navigationController pushViewController:viewController animated:YES];
    };
}

- (void)setUpVideoDataSource {
    [super setUpVideoDataSource];
    
    self.videoListDataSource.isSelectMode = YES;
    __weak typeof(self) wself = self;
    self.videoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController addSelectedPhoto:asset];
    };
    self.videoListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController removeSelectedPhoto:asset];
    };
}

- (void)setUpPanoramaDataSource {
    [super setUpPanoramaDataSource];
    
    self.panoramaListDataSource.isSelectMode = YES;
    __weak typeof(self) wself = self;
    self.panoramaListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController addSelectedPhoto:asset];
    };
    self.panoramaListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController removeSelectedPhoto:asset];
    };
}

- (void)setUpFavoriteDataSource {
    [super setUpFavoriteDataSource];
    
    self.favoriteListDataSource.isSelectMode = YES;
    __weak typeof(self) wself = self;
    self.favoriteListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController addSelectedPhoto:asset];
    };
    self.favoriteListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController removeSelectedPhoto:asset];
    };
}

- (void)setUpTimelapseDataSource {
    [super setUpTimelapseDataSource];
    
    self.timelapseListDataSource.isSelectMode = YES;
    __weak typeof(self) wself = self;
    self.timelapseListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController addSelectedPhoto:asset];
    };
    self.timelapseListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController removeSelectedPhoto:asset];
    };
}

- (void)setUpCloudDataSource {
    [super setUpCloudDataSource];
    
    self.cloudListDataSource.isSelectMode = YES;
    __weak typeof(self) wself = self;
    self.cloudListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController addSelectedPhoto:asset];
    };
    self.cloudListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController removeSelectedPhoto:asset];
    };
}

- (void)setUpBurstsDataSource {
    [super setUpBurstsDataSource];
    
    self.burstsListDataSource.isSelectMode = YES;
    __weak typeof(self) wself = self;
    self.burstsListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController addSelectedPhoto:asset];
    };
    self.burstsListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController removeSelectedPhoto:asset];
    };
}

- (void)setUpSlomoVideosDataSource {
    [super setUpSlomoVideosDataSource];
    
    self.slomoVideosListDataSource.isSelectMode = YES;
    __weak typeof(self) wself = self;
    self.slomoVideosListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController addSelectedPhoto:asset];
    };
    self.slomoVideosListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController removeSelectedPhoto:asset];
    };
}

- (void)setUpAllPhotosDataSource {
    [super setUpAllPhotosDataSource];
    
    self.allPhotoListDataSource.isSelectMode = YES;
    __weak typeof(self) wself = self;
    self.allPhotoListDataSource.didSelectAssetBlock = ^(PHAsset *asset, UIImageView *imageView, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController addSelectedPhoto:asset];
    };
    self.allPhotoListDataSource.didDeselectAssetBlock = ^(PHAsset *asset, NSUInteger index, BOOL isSelectMode) {
        typeof(wself) sself = wself;
        if (!sself) return;
        PSImagePickerController *tabBarController = (PSImagePickerController *)sself.tabBarController;
        [tabBarController removeSelectedPhoto:asset];
    };
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        PECategoryViewCell *cell = (PECategoryViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
        
        NSString *rowType = self.enabledItems[indexPath.row];
        __weak typeof(self) wself = self;
        if ([rowType isEqualToString:kPEHomeViewControllerRowType_Albums]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalAlbumListViewController *viewController = [PSNewLocalAlbumListViewController new];
                viewController.navigationItem.prompt = sself.navigationItem.prompt;
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Moments]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalMomentListViewController *viewController = [PSNewLocalMomentListViewController new];
                viewController.navigationItem.prompt = sself.navigationItem.prompt;
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Panoramas]) {
            PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
            [self.panoramaListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
            
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.panoramaListDataSource.assetCollection type:kPHPhotoListViewControllerType_Panorama];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Videos]) {
            PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
            [self.videoListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
            
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.videoListDataSource.assetCollection type:kPHPhotoListViewControllerType_Video];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Favorites]) {
            PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
            [self.favoriteListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
            
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.favoriteListDataSource.assetCollection type:kPHPhotoListViewControllerType_Favorite];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Timelapse]) {
            PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
            [self.timelapseListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
            
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.timelapseListDataSource.assetCollection type:kPHPhotoListViewControllerType_Timelapse];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Cloud]) {
            PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
            [self.cloudListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
            
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.cloudListDataSource.assetCollection type:kPHPhotoListViewControllerType_iCloud];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Bursts]) {
            PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
            [self.burstsListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
            
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.burstsListDataSource.assetCollection type:kPHPhotoListViewControllerType_Bursts];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_SlomoVideos]) {
            PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
            [self.slomoVideosListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
            
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.slomoVideosListDataSource.assetCollection type:kPHPhotoListViewControllerType_SlomoVideo];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_AllPhotos]) {
            PSImagePickerController *tabBarController = (PSImagePickerController *)self.tabBarController;
            [self.allPhotoListDataSource selectAssetIdentifiers:tabBarController.selectedPhotoIDs animated:NO];
            
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:nil type:kPHPhotoListViewControllerType_AllPhotos];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        
        return cell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
