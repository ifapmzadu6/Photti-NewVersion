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

+ (UIImage *)albumActionButtonIconWithColor:(UIColor *)color;
+ (UIImage *)arrowIconWithColor:(UIColor *)color size:(CGSize)size;

@end
