//
//  PHAssetManager.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/29.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;
@import Photos;
@import AssetsLibrary;

@interface PHAssetsManager : NSObject

+ (BOOL)isStatusAuthorized;
+ (BOOL)isStatusRestricted;
+ (BOOL)isStatusDenied;
+ (BOOL)isStatusNotDetermined;
+ (void)requestAuthorizationWithCompletion:(void (^)(BOOL isStatusAuthorized))completion;

+ (PHAssetsManager *)sharedManager;

@end
