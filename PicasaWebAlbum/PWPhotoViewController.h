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

- (id)initWithPhoto:(PWPhotoObject *)photo image:(UIImage *)image cache:(NSCache *)cache;

@property (weak, nonatomic, readonly) PWPhotoObject *photo;
@property (copy, nonatomic) void (^viewDidAppearBlock)();
@property (copy, nonatomic) void (^handleSingleTapBlock)();

@end
