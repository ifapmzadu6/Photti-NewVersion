//
//  PWPhotoListViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import CoreData;

#import "PABaseViewController.h"

@class PWAlbumObject;

@interface PWPhotoListViewController : PABaseViewController

- (id)initWithAlbum:(PWAlbumObject *)album;

@end
