//
//  PHPhotoPageViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import Photos;

@interface PEPhotoPageViewController : UIPageViewController

@property (nonatomic, readonly) BOOL ascending;

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection index:(NSUInteger)index;
- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection index:(NSUInteger)index ascending:(BOOL)ascending;
- (instancetype)initWithResult:(PHFetchResult *)result index:(NSUInteger)index;
- (instancetype)initWithResult:(PHFetchResult *)result index:(NSUInteger)index ascending:(BOOL)ascending;

@end
