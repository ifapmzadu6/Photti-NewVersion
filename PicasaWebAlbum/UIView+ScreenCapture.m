//
//  UIView+ScreenCapture.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "UIView+ScreenCapture.h"

@implementation UIView (ScreenCapture)

- (UIImage *)screenCapture {
    return [UIView screenCapture:self];
}

+ (UIImage *)screenCapture:(UIView *)view {
    UIImage *capture;
    UIGraphicsBeginImageContextWithOptions(view.frame.size , NO , 0 );
    
    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    } else {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    capture = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return capture;
}

@end
