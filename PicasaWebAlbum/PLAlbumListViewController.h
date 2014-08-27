//
//  PLAlbumListViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/18.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import CoreData;

#import "PABaseViewController.h"

@interface PLAlbumListViewController : PABaseViewController

@property (copy, nonatomic) void (^viewDidAppearBlock)();

@end
