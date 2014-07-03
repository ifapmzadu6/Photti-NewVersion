//
//  PWIcons.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

@import Foundation;

@interface PWIcons : NSObject

+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)imageWithImage:(UIImage *)image insets:(UIEdgeInsets)insets;
+ (UIImage *)gradientVerticalFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor size:(CGSize)size;

+ (UIImage *)albumActionButtonIconWithColor:(UIColor *)color;
+ (UIImage *)arrowIconWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)videoButtonIconWithColor:(UIColor *)color size:(CGFloat)size;
+ (UIImage *)videoIconWithColor:(UIColor *)color size:(CGSize)size;

@end
