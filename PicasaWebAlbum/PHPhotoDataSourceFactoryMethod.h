//
//  PHPhotoDataSourceFactoryMethod.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;

#import "PHPhotoListDataSource.h"

@interface PHPhotoDataSourceFactoryMethod : NSObject

+ (PHPhotoListDataSource *)makeAllPhotoListDataSource;
+ (PHPhotoListDataSource *)makePanoramaListDataSource;
+ (PHPhotoListDataSource *)makeTimelapseListDataSource;
+ (PHPhotoListDataSource *)makeVideoListDataSource;
+ (PHPhotoListDataSource *)makeCloudListDataSource;
+ (PHPhotoListDataSource *)makeFavoriteListDataSource;
+ (PHPhotoListDataSource *)makePhotoListDataSourceWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

//+ (PHPhotoListDataSource *)makeMomentListDataSource;
//+ (PHPhotoListDataSource *)makeMomentListDataSourceWithCollection:(PHAssetCollection *)collection;
+ (PHPhotoListDataSource *)makePhotoInAlbumListDataSourceWithCollection:(PHAssetCollection *)collection;

@end
