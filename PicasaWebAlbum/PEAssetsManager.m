//
//  PHAssetManager.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/29.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PEAssetsManager.h"

@interface PEAssetsManager ()

@property (nonatomic) BOOL isOS8;

@end

@implementation PEAssetsManager

+ (PEAssetsManager *)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

#pragma mark Authorization
+ (BOOL)isStatusAuthorized {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized;
    }
    else {
        return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized;
    }
}

+ (BOOL)isStatusRestricted {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted;
    }
    else {
        return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusRestricted;
    }
}

+ (BOOL)isStatusDenied {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied;
    }
    else {
        return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied;
    }
}

+ (BOOL)isStatusNotDetermined {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined;
    }
    else {
        return [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined;
    }
}

+ (void)requestAuthorizationWithCompletion:(void (^)(BOOL isStatusAuthorized))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (completion) {
            BOOL isStatusAuthorized = (status == PHAuthorizationStatusAuthorized) ? YES : NO;
            completion(isStatusAuthorized);
        }
    }];
}

#pragma mark 


@end
