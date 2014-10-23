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
        static int size;
        if (!size) {
            size = (int)(MAX(CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds)));
        }
        
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            if (size > 667) {
                return CGSizeMake(114.0f, 148.0f);
            }
            else if (size > 568) {
                return CGSizeMake(104.0f, 138.0f);
            }
            else if (size > 480) {
                return CGSizeMake(104.0f, 138.0f);
            }
            else {
                return CGSizeMake(104.0f, 138.0f);
            }
        }
        else {
            if (size > 667) {
                return CGSizeMake(120.0f, 164.0f);
            }
            else if (size > 568) {
                return CGSizeMake(106.0f, 140.0f);
            }
            else if (size > 480) {
                return CGSizeMake(94.0f, 128.0f);
            }
            else {
                return CGSizeMake(94.0f, 128.0f);
            }
        }
    }
    else {
        if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            return CGSizeMake(192.0f, 226.0f);
        }
        else {
            return CGSizeMake(181.0f, 216.0f);
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
