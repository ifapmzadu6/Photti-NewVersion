//
//  PAPhotoKit.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAPhotoKit.h"

#import "PADateFormatter.h"

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
        NSURL *url = [NSURL URLWithString:identifier];
        fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
    }
    PHAsset *asset = fetchResult.firstObject;
    NSAssert(asset, nil);
    return asset;
}

+ (NSString *)titleForMoment:(PHAssetCollection *)moment {
    NSString *title = moment.localizedTitle;
    if (!title) {
        NSString *startDate = [[PADateFormatter mmmddFormatter] stringFromDate:moment.startDate];
        NSString *endDate = [[PADateFormatter mmmddFormatter] stringFromDate:moment.endDate];
        if ([startDate isEqualToString:endDate]) {
            title = startDate;
        }
        else {
            title = [NSString stringWithFormat:@"%@ - %@", startDate, endDate];
        }
    }
    return title;
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

+ (void)makeNewAlbumWithTitle:(NSString *)title {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
    } completionHandler:^(BOOL success, NSError *error) {
        if (error) {
#ifdef DEBUG
            NSLog(@"%@", error);
#endif
        }
    }];
}

+ (void)setFavoriteWithAsset:(PHAsset *)asset isFavorite:(BOOL)isFavorite completion:(void (^)())completion {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *changeAssetRequest = [PHAssetChangeRequest changeRequestForAsset:asset];
        changeAssetRequest.favorite = isFavorite;
    } completionHandler:^(BOOL success, NSError *error) {
        if (success && !error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion();
                }
            });
        }
    }];
}

@end
