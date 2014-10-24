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

typedef NS_ENUM(NSUInteger, kPHPhotoListViewControllerType){
    kPHPhotoListViewControllerType_Album,
    kPHPhotoListViewControllerType_Moment,
    kPHPhotoListViewControllerType_Video,
    kPHPhotoListViewControllerType_Panorama,
    kPHPhotoListViewControllerType_Timelapse,
    kPHPhotoListViewControllerType_Favorite,
    kPHPhotoListViewControllerType_iCloud,
    kPHPhotoListViewControllerType_AllPhotos,
    kPHPhotoListViewControllerType_Bursts,
    kPHPhotoListViewControllerType_SlomoVideo,
    kPHPhotoListViewControllerType_Dates
};

@interface PEPhotoListViewController : PABaseViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type;
- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type title:(NSString *)title;
- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection type:(kPHPhotoListViewControllerType)type title:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

@property (strong, nonatomic) PEPhotoListDataSource *photoListDataSource;

@end
