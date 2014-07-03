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

+ (UIImage *)gradientVerticalFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat gradientLocations[] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)fromColor.CGColor, (id)toColor.CGColor], gradientLocations);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
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

+ (UIImage *)videoButtonIconWithColor:(UIColor *)color size:(CGFloat)size {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat scale = size / 120.0f;
    
    //// Color Declarations
    UIColor* color2 = [UIColor colorWithRed: 0.0f green: 0.0f blue: 0.0f alpha: 0.2f];
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(47.5f*scale, 38.35f*scale)];
    [bezierPath addLineToPoint: CGPointMake(47.5f*scale, 81.65f*scale)];
    [bezierPath addLineToPoint: CGPointMake(85.0f*scale, 60.0f*scale)];
    [bezierPath addLineToPoint: CGPointMake(47.5f*scale, 38.35f*scale)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(102.43f*scale, 17.57f*scale)];
    [bezierPath addCurveToPoint: CGPointMake(102.43f*scale, 102.43f*scale) controlPoint1: CGPointMake(125.86f*scale, 41.01f*scale) controlPoint2: CGPointMake(125.86f*scale, 78.99f*scale)];
    [bezierPath addCurveToPoint: CGPointMake(17.57f*scale, 102.43f*scale) controlPoint1: CGPointMake(78.99f*scale, 125.86f*scale) controlPoint2: CGPointMake(41.01f*scale, 125.86f*scale)];
    [bezierPath addCurveToPoint: CGPointMake(17.57f*scale, 17.57f*scale) controlPoint1: CGPointMake(-5.86f*scale, 78.99f*scale) controlPoint2: CGPointMake(-5.86f*scale, 41.01f*scale)];
    [bezierPath addCurveToPoint: CGPointMake(102.43f*scale, 17.57f*scale) controlPoint1: CGPointMake(41.01f*scale, -5.86f*scale) controlPoint2: CGPointMake(78.99f*scale, -5.86f*scale)];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
    
    //// Polygon Drawing
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 85.0f*scale, 35.0f*scale);
    CGContextRotateCTM(context, 90.0f * M_PI / 180.0f);
    
    UIBezierPath* polygonPath = UIBezierPath.bezierPath;
    [polygonPath moveToPoint: CGPointMake(25.0f*scale, 0.0f*scale)];
    [polygonPath addLineToPoint: CGPointMake(46.65f*scale, 37.5f*scale)];
    [polygonPath addLineToPoint: CGPointMake(3.35f*scale, 37.5f*scale)];
    [polygonPath closePath];
    [color2 setFill];
    [polygonPath fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *)videoIconWithColor:(UIColor *)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
//    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat widthScale = size.width / 100.0f;
    CGFloat heightScale = size.height / 50.0f;
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, 60.0f*widthScale, 50.0f*heightScale) cornerRadius: 10*heightScale];
    [color setFill];
    [rectanglePath fill];
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(100*widthScale, 0)];
    [bezierPath addCurveToPoint: CGPointMake(100*widthScale, 50*heightScale) controlPoint1: CGPointMake(100*widthScale, 0) controlPoint2: CGPointMake(100*widthScale, 50*heightScale)];
    [bezierPath addCurveToPoint: CGPointMake(70*widthScale, 28.53*heightScale) controlPoint1: CGPointMake(100*widthScale, 50*heightScale) controlPoint2: CGPointMake(79.63*widthScale, 35.43*heightScale)];
    [bezierPath addCurveToPoint: CGPointMake(70*widthScale, 21.47*heightScale) controlPoint1: CGPointMake(70*widthScale, 26.33*heightScale) controlPoint2: CGPointMake(70*widthScale, 23.67*heightScale)];
    [bezierPath addCurveToPoint: CGPointMake(100*widthScale, 0) controlPoint1: CGPointMake(79.63*widthScale, 14.57*heightScale) controlPoint2: CGPointMake(100*widthScale, 0)];
    [bezierPath addLineToPoint: CGPointMake(100*widthScale, 0)];
    [bezierPath closePath];
    [bezierPath closePath];
    [color setFill];
    [bezierPath fill];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
