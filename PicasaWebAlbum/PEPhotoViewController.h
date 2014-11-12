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

@interface PEPhotoViewController : PABaseViewController

- (instancetype)initWithAsset:(PHAsset *)asset index:(NSUInteger)index;

@property (strong, nonatomic, readonly) PHAsset *asset;
@property (nonatomic, readonly) NSUInteger index;
@property (copy, nonatomic) void (^viewDidAppearBlock)();
@property (copy, nonatomic) void (^didSingleTapBlock)();

@end
