//
//  PWPhotoCollectionViewFlowLayout.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAPhotoCollectionViewFlowLayout.h"

@implementation PAPhotoCollectionViewFlowLayout

- (CGSize)itemSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((int)[[UIScreen mainScreen] bounds].size.height > 480) {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                return CGSizeMake(112.0f, 112.0f);
            }
            else {
                return CGSizeMake(106.0f, 106.0f);
            }
        }
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                return CGSizeMake(118.5f, 118.5f);
            }
            else {
                return CGSizeMake(106.0f, 106.0f);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(172.0f, 187.0f);
        }
        else {
            return CGSizeMake(172.0f, 187.0f);
        }
    }
}

- (CGFloat)minimumInteritemSpacing {
    return 1.0f;
}

- (CGFloat)minimumLineSpacing {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return 2.0f;
        }
        else {
            return 1.0f;
        }
    }
    else {
        return 10.0f;
    }
}

- (CGSize)footerReferenceSize {
    return CGSizeMake(0.0f, 50.0f);
}

@end
