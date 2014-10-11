//
//  PWAlbumCollectionViewFlowLayout.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/08/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAAlbumCollectionViewFlowLayout.h"

@implementation PAAlbumCollectionViewFlowLayout

- (CGSize)itemSize {
    return [self.class itemSize];
}

+ (CGSize)itemSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            if ((int)(MAX(CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds))) > 480) {
                return CGSizeMake(90.0f, 124.0f);
            }
            else {
                return CGSizeMake(90.0f, 124.0f);
            }
        }
        else {
            if ((int)(MAX(CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds))) > 480) {
                return CGSizeMake(90.0f, 124.0f);
            }
            else {
                return CGSizeMake(90.0f, 124.0f);
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
    return 0.0f;
}

- (CGFloat)minimumLineSpacing {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return 15.0f;
    }
    else {
        return 20.0f;
    }
}

@end
