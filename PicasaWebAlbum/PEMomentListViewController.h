//
//  PHmomentListViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/29.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@class PEMomentListDataSource;

@interface PEMomentListViewController : PABaseViewController

@property (strong, nonatomic) PEMomentListDataSource *dataSource;

@end
