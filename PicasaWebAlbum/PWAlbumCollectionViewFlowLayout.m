//
//  PWAlbumCollectionViewFlowLayout.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWAlbumCollectionViewFlowLayout.h"

@implementation PWAlbumCollectionViewFlowLayout

- (CGSize)itemSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if ((int)[[UIScreen mainScreen] bounds].size.height > 480) {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                return CGSizeMake(177.0f, ceilf(177.0f * 3.0f / 4.0f) + 40.0f);
            }
            else {
                return CGSizeMake(146.0f, ceilf(146.0f * 3.0f / 4.0f) + 40.0f);
            }
        }
        else {
            if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                return CGSizeMake(147.0f, ceilf(147.0f * 3.0f / 4.0f) + 40.0f);
            }
            else {
                return CGSizeMake(146.0f, ceilf(146.0f * 3.0f / 4.0f) + 40.0f);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(192.0f, ceilf(192.0f * 3.0f / 4.0f) + 40.0f);
        }
        else {
            return CGSizeMake(181.0f, ceilf(181.0f * 3.0f / 4.0f) + 40.0f);
        }
    }
}

- (CGFloat)minimumInteritemSpacing {
    return 1.0f;
}

- (CGFloat)minimumLineSpacing {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return 8.0f;
    }
    return 20.0f;
}

- (CGSize)footerReferenceSize {
    return CGSizeMake(0.0f, 50.0f);
}

@end
