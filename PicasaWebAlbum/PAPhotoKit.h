//
//  PAPhotoKit.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;

@interface PAPhotoKit : NSObject

+ (PHAssetCollection *)getAssetCollectionWithIdentifier:(NSString *)identifier;

+ (PHAsset *)getAssetWithIdentifier:(NSString *)identifier;

+ (void)deleteAssetCollection:(PHAssetCollection *)assetCollection completion:(void (^)(BOOL, NSError *))completion;

+ (void)deleteAssets:(NSArray *)assets completion:(void (^)(BOOL, NSError *))completion;

+ (void)deleteAssets:(NSArray *)assets fromAssetCollection:(PHAssetCollection *)assetCollection completion:(void (^)(BOOL, NSError *))completion;

+ (void)makeNewAlbumWithTitle:(NSString *)title;

+ (void)setFavoriteWithAsset:(PHAsset *)asset isFavorite:(BOOL)isFavorite completion:(void (^)())completion;

@end
