//
//  PAGradientView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/09/22.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAGradientView.h"

@implementation PAGradientView

#pragma mark methods
- (void)setStartColor:(UIColor *)startColor {
    _startColor = startColor;
    
    [self setNeedsDisplay];
}

- (void)setEndColor:(UIColor *)endColor {
    _endColor = endColor;
    
    [self setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self setNeedsDisplay];
}

#pragma mark Draw Rect
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect shadow = CGRectMake(0.0f, 0.0f, CGRectGetMaxX(rect), 80.0f);
    CGFloat start_red, start_green, start_blue, start_alpha;
    CGFloat end_red, end_green, end_blue, end_alpha;
    [_startColor getRed:&start_red green:&start_green blue:&start_blue alpha:&start_alpha];
    [_endColor getRed:&end_red green:&end_green blue:&end_blue alpha:&end_alpha];
    CGFloat components[] = {
        start_red, start_green, start_blue, start_alpha,
        end_red, end_green, end_blue, end_alpha
    };
    size_t count = sizeof(components)/ (sizeof(CGFloat)* 4);
    if (_direction == kPAGradientViewDirectionTopToBottom) {
        CGFloat locations[] = { 0.0f, 1.0f};
        CGContextFillVarticalGradientRect(context, shadow, components, locations, count);
    }
    else if (_direction == kPAGradientViewDirectionBottomToTop) {
        CGFloat locations[] = { 1.0f, 0.0f};
        CGContextFillVarticalGradientRect(context, shadow, components, locations, count);
    }
    else if (_direction == kPAGradientViewDirectionLeftToRight) {
        CGFloat locations[] = { 0.0f, 1.0f};
        CGContextFillHorizontalGradientRect(context, shadow, components, locations, count);
    }
    else if (_direction == kPAGradientViewDirectionRightToLeft) {
        CGFloat locations[] = { 1.0f, 0.0f};
        CGContextFillHorizontalGradientRect(context, shadow, components, locations, count);
    }
}

void CGContextFillVarticalGradientRect(CGContextRef context, CGRect gradientRect,CGFloat components[], CGFloat locations[], CGFloat count)
{
    CGContextSaveGState(context);
    
    CGContextAddRect(context, gradientRect);
    CGContextClip(context);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, (size_t)count);
    
    CGContextDrawLinearGradient(context,
                                gradientRef,
                                CGPointMake(CGRectGetMidX(gradientRect), CGRectGetMinY(gradientRect)),
                                CGPointMake(CGRectGetMidX(gradientRect), CGRectGetMaxY(gradientRect)),
                                0);
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    CGContextRestoreGState(context);
}

void CGContextFillHorizontalGradientRect(CGContextRef context, CGRect gradientRect,CGFloat components[], CGFloat locations[], CGFloat count)
{
    CGContextSaveGState(context);
    
    CGContextAddRect(context, gradientRect);
    CGContextClip(context);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, (size_t)count);
    
    CGContextDrawLinearGradient(context,
                                gradientRef,
                                CGPointMake(CGRectGetMinX(gradientRect), CGRectGetMidY(gradientRect)),
                                CGPointMake(CGRectGetMaxX(gradientRect), CGRectGetMidY(gradientRect)),
                                0);
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    CGContextRestoreGState(context);
}

@end
