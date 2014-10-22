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

#import "PSNewLocalPhotoListViewController.h"
#import "PECategoryViewCell.h"

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
        PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album];
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
        NSString *title = [PEMomentListDataSource titleForMoment:assetCollection];
        PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:assetCollection type:PHPhotoListViewControllerType_Album title:title];
        viewController.navigationItem.prompt = sself.navigationItem.prompt;
        [sself.navigationController pushViewController:viewController animated:YES];
    };
}

- (void)setUpVideoDataSource {
    [super setUpVideoDataSource];
    
}

- (void)setUpPanoramaDataSource {
    [super setUpPanoramaDataSource];
}

- (void)setUpFavoriteDataSource {
    [super setUpFavoriteDataSource];
}

- (void)setUpTimelapseDataSource {
    [super setUpTimelapseDataSource];
}

- (void)setUpCloudDataSource {
    [super setUpCloudDataSource];
}

- (void)setUpBurstsDataSource {
    [super setUpBurstsDataSource];
}

- (void)setUpSlomoVideosDataSource {
    [super setUpSlomoVideosDataSource];
}

- (void)setUpAllPhotosDataSource {
    [super setUpAllPhotosDataSource];
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
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.panoramaListDataSource.assetCollection type:PHPhotoListViewControllerType_Panorama];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Videos]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.videoListDataSource.assetCollection type:PHPhotoListViewControllerType_Video];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Favorites]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.favoriteListDataSource.assetCollection type:PHPhotoListViewControllerType_Favorite];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Timelapse]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.timelapseListDataSource.assetCollection type:PHPhotoListViewControllerType_Timelapse];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Cloud]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.cloudListDataSource.assetCollection type:PHPhotoListViewControllerType_iCloud];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_Bursts]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.burstsListDataSource.assetCollection type:PHPhotoListViewControllerType_Bursts];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_SlomoVideos]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:sself.slomoVideosListDataSource.assetCollection type:PHPhotoListViewControllerType_SlomoVideo];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        else if ([rowType isEqualToString:kPEHomeViewControllerRowType_AllPhotos]) {
            cell.moreButtonActionBlock = ^{
                typeof(wself) sself = wself;
                if (!sself) return;
                PSNewLocalPhotoListViewController *viewController = [[PSNewLocalPhotoListViewController alloc] initWithAssetCollection:nil type:PHPhotoListViewControllerType_AllPhotos];
                [sself.navigationController pushViewController:viewController animated:YES];
            };
        }
        
        return cell;
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
