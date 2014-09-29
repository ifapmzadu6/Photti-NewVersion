//
//  PHPhotoDataSourceFactoryMethod.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;

#import "PEPhotoListDataSource.h"

@interface PEPhotoDataSourceFactoryMethod : NSObject

+ (PEPhotoListDataSource *)makeAllPhotoListDataSource;
+ (PEPhotoListDataSource *)makePanoramaListDataSource;
+ (PEPhotoListDataSource *)makeTimelapseListDataSource;
+ (PEPhotoListDataSource *)makeVideoListDataSource;
+ (PEPhotoListDataSource *)makeCloudListDataSource;
+ (PEPhotoListDataSource *)makeFavoriteListDataSource;
+ (PEPhotoListDataSource *)makePhotoListDataSourceWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

//+ (PHPhotoListDataSource *)makeMomentListDataSource;
//+ (PHPhotoListDataSource *)makeMomentListDataSourceWithCollection:(PHAssetCollection *)collection;
+ (PEPhotoListDataSource *)makePhotoInAlbumListDataSourceWithCollection:(PHAssetCollection *)collection;

@end
