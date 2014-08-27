//
//  PWAlbumShareViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/17.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@class PWAlbumObject;

@interface PWAlbumShareViewController : PABaseViewController

@property (copy, nonatomic) void (^changedAlbumBlock)();

- (id)initWithAlbum:(PWAlbumObject *)album;

@end
