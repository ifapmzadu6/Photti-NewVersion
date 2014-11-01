//
//  PAPhotoKit.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAPhotoKit.h"

@interface PAPhotoKit ()

@end

@implementation PAPhotoKit

+ (PHAssetCollection *)getAssetCollectionWithIdentifier:(NSString *)identifier {
    if (!identifier) {
        return nil;
    }
    
    PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[identifier] options:nil];
    if (fetchResult.count == 0) {
        NSURL *url = [NSURL URLWithString:identifier];
        fetchResult = [PHAssetCollection fetchAssetCollectionsWithALAssetGroupURLs:@[url] options:nil];
    }
    PHAssetCollection *assetCollection = fetchResult.firstObject;
    NSAssert(assetCollection, nil);
    return assetCollection;
}

+ (PHAsset *)getAssetWithIdentifier:(NSString *)identifier {
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
    if (fetchResult.count == 0) {
        fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[identifier] options:nil];
    }
    PHAsset *asset = fetchResult.firstObject;
    NSAssert(asset, nil);
    return asset;
}


@end
