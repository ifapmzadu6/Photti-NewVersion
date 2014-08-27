//
//  PLAutoCreateAlbumViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@interface PLAutoCreateAlbumViewController : PABaseViewController

@property (copy, nonatomic) void (^completion)();

@end
