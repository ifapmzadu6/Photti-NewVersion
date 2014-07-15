//
//  PLRoundedCornerBorderView.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/07/14.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PLRoundedCornerBorderView.h"

@interface PLRoundedCornerBorderView ()

@property (strong, nonatomic) CALayer *borderLayer;

@end

@implementation PLRoundedCornerBorderView

- (id)init {
    self = [super init];
    if (self) {
        _borderLayer = [CALayer new];
        _borderLayer.backgroundColor = self.backgroundColor.CGColor;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _borderLayer = [CALayer new];
        _borderLayer.backgroundColor = self.backgroundColor.CGColor;
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    _borderLayer.frame = frame;
    [self setNeedsDisplay];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    
    _borderLayer.backgroundColor = backgroundColor.CGColor;
    [self setNeedsDisplay];
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    
    _borderLayer.borderColor = borderColor.CGColor;
    [self setNeedsDisplay];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    
    _borderLayer.borderWidth = borderWidth;
    [self setNeedsDisplay];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    
    _borderLayer.cornerRadius = cornerRadius;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [_borderLayer renderInContext:context];
    UIGraphicsEndImageContext();
    [super drawRect:rect];
}

@end
