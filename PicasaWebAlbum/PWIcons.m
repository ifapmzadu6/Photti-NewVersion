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
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.0f, 30.0f), NO, 0.0f);
    
    [[color colorWithAlphaComponent:1.0f] setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 5.0f, 4.0f, 4.0f)] fill];
    [[color colorWithAlphaComponent:0.7f] setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 12.0f, 4.0f, 4.0f)] fill];
    [[color colorWithAlphaComponent:0.4f] setFill];
    [[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 19.0f, 4.0f, 4.0f)] fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
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

+ (UIImage *)imageWithImage:(UIImage *)image insets:(UIEdgeInsets)insets {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGRect rect = CGRectMake(insets.left, insets.top, image.size.width - insets.left - insets.right, image.size.height - insets.top - insets.bottom);
    [image drawInRect:rect];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}


+ (UIImage *)arrowIconWithColor:(UIColor *)color size:(CGSize)size {
    if (CGSizeEqualToSize(CGSizeZero, size)) return nil;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    CGFloat lineWidth = 1.0f;
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
    
    UIImage *defaultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return defaultImage;
}

+ (UIImage *)videoButtonIconWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* color2 = [UIColor colorWithRed: 0.0f green: 0.0f blue: 0.0f alpha: 0.2f];
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(47.5f, 38.35f)];
    [bezierPath addLineToPoint: CGPointMake(47.5f, 81.65f)];
    [bezierPath addLineToPoint: CGPointMake(85.0f, 60.0f)];
    [bezierPath addLineToPoint: CGPointMake(47.5f, 38.35f)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(102.43f, 17.57f)];
    [bezierPath addCurveToPoint: CGPointMake(102.43f, 102.43f) controlPoint1: CGPointMake(125.86f, 41.01f) controlPoint2: CGPointMake(125.86f, 78.99f)];
    [bezierPath addCurveToPoint: CGPointMake(17.57f, 102.43f) controlPoint1: CGPointMake(78.99f, 125.86f) controlPoint2: CGPointMake(41.01f, 125.86f)];
    [bezierPath addCurveToPoint: CGPointMake(17.57f, 17.57f) controlPoint1: CGPointMake(-5.86f, 78.99f) controlPoint2: CGPointMake(-5.86f, 41.01f)];
    [bezierPath addCurveToPoint: CGPointMake(102.43f, 17.57f) controlPoint1: CGPointMake(41.01f, -5.86f) controlPoint2: CGPointMake(78.99f, -5.86f)];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
    
    //// Polygon Drawing
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 85.0f, 35.0f);
    CGContextRotateCTM(context, 90.0f * M_PI / 180.0f);
    
    UIBezierPath* polygonPath = UIBezierPath.bezierPath;
    [polygonPath moveToPoint: CGPointMake(25.0f, 0.0f)];
    [polygonPath addLineToPoint: CGPointMake(46.65f, 37.5f)];
    [polygonPath addLineToPoint: CGPointMake(3.35f, 37.5f)];
    [polygonPath closePath];
    [color2 setFill];
    [polygonPath fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    return image;
}

@end
