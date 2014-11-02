//
//  PALinkableTextView.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PALinkableTextView.h"

@interface PALinkableTextView ()

@end

@implementation PALinkableTextView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.scrollEnabled = NO;
        self.editable = NO;
        self.selectable = YES;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollEnabled = NO;
        self.editable = NO;
        self.selectable = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        self.scrollEnabled = NO;
        self.editable = NO;
        self.selectable = YES;
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.userInteractionEnabled) {
        return nil;
    }
    
    CGPoint p = point;
    p.y -= self.textContainerInset.top;
    p.x -= self.textContainerInset.left;
    
    NSInteger i = [self.layoutManager characterIndexForPoint:p inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:NULL];
    NSRange effectiveRange;
    NSDictionary *attr = [self.textStorage attributesAtIndex:i effectiveRange:&effectiveRange];
    if (attr[NSLinkAttributeName]) {
        __block BOOL touchingLink = NO;
        NSInteger glyphIndex = [self.layoutManager glyphIndexForCharacterAtIndex:i];
        [self.layoutManager enumerateLineFragmentsForGlyphRange:NSMakeRange(glyphIndex, 1) usingBlock: ^(CGRect rect, CGRect usedRect, NSTextContainer *textContainer, NSRange glyphRange, BOOL *stop) {
            if (CGRectContainsPoint(usedRect, p)) {
                touchingLink = YES;
                *stop = YES;
            }
        }];
        return (touchingLink) ? self : nil;
    }
    return nil;
}

@end
