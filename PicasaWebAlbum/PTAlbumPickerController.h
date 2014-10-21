//
//  PWAlbumPickerController.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/06.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface PTAlbumPickerController : UITabBarController <UITabBarControllerDelegate>

- (id)initWithCompletion:(void (^)(id album, BOOL isWebAlbum))completion;

@property (strong, nonatomic) NSString *prompt;

- (void)doneBarButtonActionWithSelectedAlbum:(id)selectedAlbum isWebAlbum:(BOOL)isWebAlbum;

@end
