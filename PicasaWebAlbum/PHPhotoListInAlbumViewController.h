//
//  PHPhotoListInAlbumViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import Photos;

#import "PABaseViewController.h"

@interface PHPhotoListInAlbumViewController : PABaseViewController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection;

@end
