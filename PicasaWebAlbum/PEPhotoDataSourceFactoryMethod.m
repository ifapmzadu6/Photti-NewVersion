//
//  PHPhotoDataSourceFactoryMethod.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEPhotoDataSourceFactoryMethod.h"

#import "PEPhotoListDataSource.h"

@implementation PEPhotoDataSourceFactoryMethod

+ (PEPhotoListDataSource *)makeCloudListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumBursts options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PEPhotoListDataSource *)makeVideoListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumVideos options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PEPhotoListDataSource *)makeTimelapseListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumTimelapses options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PEPhotoListDataSource *)makePanoramaListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumPanoramas options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PEPhotoListDataSource *)makeFavoriteListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumFavorites options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PEPhotoListDataSource *)makeBurstListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumBursts options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PEPhotoListDataSource *)makeSlomoVideoListDataSource {
    PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumSlomoVideos options:0];
    PHAssetCollection *collection = collectionResult.firstObject;
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}

+ (PEPhotoListDataSource *)makeAllPhotoListDataSource {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:nil];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:nil ascending:YES];
    return dataSource;
}

+ (PEPhotoListDataSource *)makePhotoListDataSourceWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    PHFetchOptions *options = [PHFetchOptions new];
    options.predicate = [NSPredicate predicateWithFormat:@"(creationDate > %@) AND (creationDate < %@)", startDate, endDate];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithOptions:options];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult];
    return dataSource;
}


+ (PEPhotoListDataSource *)makePhotoInAlbumListDataSourceWithCollection:(PHAssetCollection *)collection {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    
    PEPhotoListDataSource *dataSource = [[PEPhotoListDataSource alloc] initWithFetchResultOfPhoto:fetchResult assetCollection:collection];
    return dataSource;
}


@end
