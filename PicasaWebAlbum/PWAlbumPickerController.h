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

- (id)initWithDownloadMode:(BOOL)isDownloadMode completion:(void (^)(PWAlbumObject *album))completion;

@property (strong, nonatomic) NSString *prompt;

- (void)doneBarButtonActionWithSelectedAlbum:(PWAlbumObject *)selectedAlbum;
- (UIEdgeInsets)viewInsets;

@end
