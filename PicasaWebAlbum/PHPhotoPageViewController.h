//
//  PHPhotoPageViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import Photos;

@interface PHPhotoPageViewController : UIPageViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection index:(NSUInteger)index;
- (instancetype)initWithResult:(PHFetchResult *)result index:(NSUInteger)index;

@end
