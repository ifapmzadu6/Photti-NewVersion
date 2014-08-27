//
//  PWPhotoViewController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

#import "PABaseViewController.h"

@class PWPhotoObject;

@interface PWPhotoViewController : PABaseViewController

- (id)initWithPhoto:(PWPhotoObject *)photo placeholder:(id)placeholder cache:(NSCache *)cache;

@property (strong, nonatomic, readonly) PWPhotoObject *photo;
@property (copy, nonatomic) void (^viewDidAppearBlock)();
@property (copy, nonatomic) void (^handleSingleTapBlock)();

@end
