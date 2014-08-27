//
//  PLPhotoListViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/26.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import CoreData;

#import "PABaseViewController.h"

@class PLAlbumObject;

@interface PLPhotoListViewController : PABaseViewController

@property (strong, nonatomic, readonly) PLAlbumObject *album;

- initWithAlbum:(PLAlbumObject *)album;

@end
