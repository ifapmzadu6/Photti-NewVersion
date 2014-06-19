//
//  PWLoundedCornerBadgeLabel.m
//  PicasaWebAlbum
//
//  Created by Keisuke Karijuku on 2014/06/15.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PWLoundedCornerBadgeLabel.h"

@interface PWLoundedCornerBadgeLabel ()

@property (strong, nonatomic) CALayer *badgeLayer;

@end

@implementation PWLoundedCornerBadgeLabel

- (id)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        self.textAlignment = NSTextAlignmentCenter;
        self.textColor = [UIColor whiteColor];
        
        _badgeLayer = [CALayer layer];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _badgeLayer = [CALayer layer];
        _badgeLayer.backgroundColor = self.backgroundColor.CGColor;
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    _badgeLayer.frame = frame;
    _badgeLayer.cornerRadius = CGRectGetHeight(frame) / 2.0f;
    [self setNeedsDisplay];
}

- (void)setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    _badgeBackgroundColor = badgeBackgroundColor;
    
    _badgeLayer.backgroundColor = badgeBackgroundColor.CGColor;
    [self setNeedsDisplay];
}

- (void)setBadgeBorderColor:(UIColor *)badgeBorderColor {
    _badgeBorderColor = badgeBorderColor;
    
    _badgeLayer.borderColor = badgeBorderColor.CGColor;
    [self setNeedsDisplay];
}

- (void)setBadgeBorderWidth:(CGFloat)badgeBorderWidth {
    _badgeBorderWidth = badgeBorderWidth;
    
    _badgeLayer.borderWidth = badgeBorderWidth;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    _badgeLayer.contents = nil;
    [_badgeLayer renderInContext:context];
    UIGraphicsEndImageContext();
    
    [super drawRect:rect];
}

@end
