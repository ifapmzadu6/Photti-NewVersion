//
//  PWAlbumPickerController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@class PWAlbumObject;

@interface PWAlbumPickerController : UITabBarController

- (id)initWithCompletion:(void (^)(PWAlbumObject *album))completion;

- (void)doneBarButtonActionWithSelectedAlbum:(PWAlbumObject *)selectedAlbum;
- (UIEdgeInsets)viewInsets;

@end
