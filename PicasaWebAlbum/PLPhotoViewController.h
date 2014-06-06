//
//  PLPhotoViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/01.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PLPhotoObject;

@interface PLPhotoViewController : UIViewController

- (id)initWithPhoto:(PLPhotoObject *)photo;

@property (strong, nonatomic, readonly) PLPhotoObject *photo;
@property (copy, nonatomic) void (^viewDidAppearBlock)();
@property (copy, nonatomic) void (^handleSingleTapBlock)();

@end
