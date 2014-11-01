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
    if (fetchResult.count == 0) {
        PHFetchOptions *options = [PHFetchOptions new];
        options.predicate = [NSPredicate predicateWithFormat:@"localIdentifier = %@", identifier];
        fetchResult = [PHAssetCollection fetchMomentsWithOptions:options];
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

+ (void)deleteAssetCollection:(PHAssetCollection *)assetCollection completion:(void (^)(BOOL, NSError *))completion {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest deleteAssetCollections:@[assetCollection]];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
        });
    }];
}

+ (void)deleteAssets:(NSArray *)assets completion:(void (^)(BOOL, NSError *))completion {
    if (assets.count == 0) return;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:assets];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
        });
    }];
}

+ (void)deleteAssets:(NSArray *)assets fromAssetCollection:(PHAssetCollection *)assetCollection completion:(void (^)(BOOL, NSError *))completion {
    if (assets.count == 0) return;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        [changeRequest removeAssets:assets];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success, error);
            }
        });
    }];
}

@end
