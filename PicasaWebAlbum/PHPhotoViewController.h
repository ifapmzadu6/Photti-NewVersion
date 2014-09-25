//
//  PHPhotoViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import Photos;

#import "PABaseViewController.h"

@interface PHPhotoViewController : PABaseViewController

- (instancetype)initWithAsset:(PHAsset *)asset;

@property (strong, nonatomic, readonly) PHAsset *asset;
@property (copy, nonatomic) void (^viewDidAppearBlock)();
@property (copy, nonatomic) void (^handleSingleTapBlock)();

@end
