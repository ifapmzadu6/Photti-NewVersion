//
//  PWIcons.h
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PWIcons : NSObject

+ (UIImage *)albumActionButtonIconWithColor:(UIColor *)color;
+ (UIImage *)imageWithColor:(UIColor *)color;
+ (UIImage *)arrowIconWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)imageWithImage:(UIImage *)image insets:(UIEdgeInsets)insets;

@end
