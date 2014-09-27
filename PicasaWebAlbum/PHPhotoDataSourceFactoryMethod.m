//
//  PHPhotoDataSourceFactoryMethod.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PHPhotoDataSourceFactoryMethod.h"

#import "PHPhotoListDataSource.h"

@implementation PHPhotoDataSourceFactoryMethod

+ (PHPhotoListDataSource *)makeCloudListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumBursts options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    PHPhotoListDataSource *dataSource = [[PHPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PHPhotoListDataSource *)makeVideoListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumVideos options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    PHPhotoListDataSource *dataSource = [[PHPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PHPhotoListDataSource *)makeTimelapseListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumTimelapses options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    PHPhotoListDataSource *dataSource = [[PHPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PHPhotoListDataSource *)makePanoramaListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumPanoramas options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    PHPhotoListDataSource *dataSource = [[PHPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PHPhotoListDataSource *)makeFavoriteListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumFavorites options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    PHPhotoListDataSource *dataSource = [[PHPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PHPhotoListDataSource *)makeAllPhotoListDataSource {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:nil];

    PHPhotoListDataSource *dataSource = [[PHPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult];
    return dataSource;
}



+ (PHPhotoListDataSource *)makePhotoInAlbumListDataSourceWithCollection:(PHAssetCollection *)collection {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    PHPhotoListDataSource *dataSource = [[PHPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}


@end
