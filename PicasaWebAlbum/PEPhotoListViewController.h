//
//  PHPhotoListViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import Photos;

#import "PABaseViewController.h"

@class PEPhotoListDataSource;

typedef NS_ENUM(NSUInteger, PHPhotoListViewControllerType){
    PHPhotoListViewControllerType_Album,
    PHPhotoListViewControllerType_Moment,
    PHPhotoListViewControllerType_Video,
    PHPhotoListViewControllerType_Panorama,
    PHPhotoListViewControllerType_Timelapse,
    PHPhotoListViewControllerType_Favorite,
    PHPhotoListViewControllerType_iCloud,
    PHPhotoListViewControllerType_AllPhotos,
    PHPhotoListViewControllerType_Bursts,
    PHPhotoListViewControllerType_SlomoVideo,
    PHPhotoListViewControllerType_Dates
};

@interface PEPhotoListViewController : PABaseViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(PHPhotoListViewControllerType)type;
- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(PHPhotoListViewControllerType)type title:(NSString *)title;
- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(PHPhotoListViewControllerType)type title:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

@property (strong, nonatomic) PEPhotoListDataSource *photoListDataSource;

@end
