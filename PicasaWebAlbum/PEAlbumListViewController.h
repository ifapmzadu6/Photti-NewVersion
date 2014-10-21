//
//  PHAlbumViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/25.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@class PEAlbumListDataSource;

@interface PEAlbumListViewController : PABaseViewController

@property (strong, nonatomic) PEAlbumListDataSource *albumListDataSource;

@end
