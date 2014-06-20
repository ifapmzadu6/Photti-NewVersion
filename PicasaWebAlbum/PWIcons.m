//
//  PWIcons.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWIcons.h"

@implementation PWIcons

+ (UIImage *)albumActionButtonIconWithColor:(UIColor *)color {
    UIImage *defaultImage = nil;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.0f, 30.0f), NO, 0.0f);
    
    [[color colorWithAlphaComponent:1.0f] setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 5.0f, 4.0f, 4.0f)] fill];
    [[color colorWithAlphaComponent:0.7f] setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 12.0f, 4.0f, 4.0f)] fill];
    [[color colorWithAlphaComponent:0.4f] setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 19.0f, 4.0f, 4.0f)] fill];
    
    defaultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return defaultImage;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
	CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
	UIGraphicsBeginImageContext(rect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
    
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, rect);
    
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
	return image;
}

+ (UIImage *)arrowIconWithColor:(UIColor *)color size:(CGSize)size {
    if (CGSizeEqualToSize(CGSizeZero, size)) {
        return nil;
    }
    
    UIImage *defaultImage = nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    CGFloat lineWidth = 3.0f;
    CGFloat upAndDownRadius = ceilf(size.width/3.0f*2.0f)/2.0f;
    
    [[color colorWithAlphaComponent:1.0f] setStroke];
    [[color colorWithAlphaComponent:1.0f] setFill];
    UIBezierPath *line = [UIBezierPath bezierPath];
    [line moveToPoint:CGPointMake(lineWidth/2.0f, size.height/2.0f)];
    [line addLineToPoint:CGPointMake(size.width - lineWidth/2.0f, size.height/2.0f)];
    [line setLineWidth:lineWidth];
    [line stroke];
    
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0.0f, size.height/2.0f - lineWidth/2.0f, lineWidth, lineWidth)] fill];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(size.width - lineWidth, size.height/2.0f - lineWidth/2.0f, lineWidth, lineWidth)] fill];
    UIBezierPath *upLine = [UIBezierPath bezierPath];
    CGPoint upStartPoint = CGPointMake(size.width - upAndDownRadius - lineWidth/2.0f, size.height/2.0f - upAndDownRadius);
    [upLine moveToPoint:upStartPoint];
    [upLine addLineToPoint:CGPointMake(size.width - lineWidth/2.0f, size.height/2.0f)];
    [upLine setLineWidth:lineWidth];
    [upLine stroke];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(upStartPoint.x - lineWidth/2.0f, upStartPoint.y - lineWidth/2.0f, lineWidth, lineWidth)] fill];
    UIBezierPath *downLine = [UIBezierPath bezierPath];
    CGPoint downStartPoint = CGPointMake(size.width - upAndDownRadius - lineWidth/2.0f, size.height/2.0f + upAndDownRadius);
    [downLine moveToPoint:downStartPoint];
    [downLine addLineToPoint:CGPointMake(size.width - lineWidth/2.0f, size.height/2.0f)];
    [downLine setLineWidth:lineWidth];
    [downLine stroke];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(downStartPoint.x - lineWidth/2.0f, downStartPoint.y - lineWidth/2.0f, lineWidth, lineWidth)] fill];
    
    defaultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return defaultImage;
}

@end
