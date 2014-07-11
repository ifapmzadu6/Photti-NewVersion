//
//  PLPhotoEditViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/11.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PLPhotoObject;

@interface PLPhotoEditViewController : UIViewController

- (id)initWithPhoto:(PLPhotoObject *)photo metadata:(NSDictionary *)metadata;

@end
