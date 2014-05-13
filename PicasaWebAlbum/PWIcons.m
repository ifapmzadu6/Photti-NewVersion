//
//  PWIcons.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/05/08.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWIcons.h"

@implementation PWIcons

+ (UIImage *)albumActionButtonIcon {
	static UIImage *defaultImage = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(20.0f, 30.0f), NO, 0.0f);
		
		[[UIColor colorWithWhite:0.9f alpha:1.0f] setFill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 5.0f, 4.0f, 4.0f)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 12.0f, 4.0f, 4.0f)] fill];
		[[UIBezierPath bezierPathWithRect:CGRectMake(8.0f, 19.0f, 4.0f, 4.0f)] fill];
        
		defaultImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
        
	});
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

@end
