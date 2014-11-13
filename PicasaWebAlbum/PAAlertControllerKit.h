//
//  PAAlertControllerKit.h
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/21.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PAAlertControllerKit : NSObject

+ (void)showNotCollectedToNetwork;
+ (void)showNotPermittedToPhotoLibrary;
+ (void)showYouNeedToLoginWebAlbum;

+ (void)showDontRemoveThoseItemsUntilTheTaskIsFinished;

+ (void)attachActivityIndicatorView:(UIAlertView *)alertView;

@end
