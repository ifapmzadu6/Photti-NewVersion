//
//  UIView+ScreenCapture.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import UIKit;

@interface UIView (ScreenCapture)

- (UIImage *)screenCapture;
+ (UIImage *)screenCapture:(UIView *)view;

@end
