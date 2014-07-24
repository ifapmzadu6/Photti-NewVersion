//
//  PWPhotoListViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/07.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;
@import CoreData;

@class PWAlbumObject;

@interface PWPhotoListViewController : UIViewController

- (id)initWithAlbum:(PWAlbumObject *)album;

@end
