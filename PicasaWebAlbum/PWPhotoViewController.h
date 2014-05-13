//
//  PWPhotoViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PWPhotoObject;

@interface PWPhotoViewController : UIViewController

- (id)initWithPhoto:(PWPhotoObject *)photo;

@property (strong, nonatomic, readonly) PWPhotoObject *photo;
@property (strong, nonatomic) void (^viewDidAppearBlock)();

@end
