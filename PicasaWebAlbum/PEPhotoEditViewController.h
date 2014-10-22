//
//  PEPhotoEditViewController.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/09.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import Photos;

#import "PABaseViewController.h"

@interface PEPhotoEditViewController : PABaseViewController

- (instancetype)initWithAsset:(PHAsset *)asset metadata:(NSDictionary *)metadata;
- (instancetype)initWithAsset:(PHAsset *)asset metadata:(NSDictionary *)metadata backgroundScreenShot:(UIImage *)backgroundScreenshot;

@end
