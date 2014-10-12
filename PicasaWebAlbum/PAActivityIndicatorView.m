//
//  PAActivityIndicatorView.m
//  Photti
//
//  Created by Keisuke Karijuku on 2014/10/12.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

#import "PAActivityIndicatorView.h"

@interface PAActivityIndicatorView ()

@property (nonatomic) CGFloat red;
@property (nonatomic) CGFloat green;
@property (nonatomic) CGFloat blue;

@property (strong, nonatomic) NSTimer *timer;

@end

@implementation PAActivityIndicatorView

static const CGFloat min = 80;
static const CGFloat max = 240;
static const CGFloat delta = 40;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style {
    self = [super initWithActivityIndicatorStyle:style];
    if (self) {
        [self initialization];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    u_int32_t rand = arc4random_uniform(NSUIntegerMax)%6;
    switch (rand) {
        case 0:
            _red = 80; _green = 80; _blue = 240;
            break;
        case 1:
            _red = 80; _green = 240; _blue = 80;
            break;
        case 2:
            _red = 240; _green = 80; _blue = 80;
            break;
        case 3:
            _red = 240; _green = 240; _blue = 80;
            break;
        case 4:
            _red = 240; _green = 80; _blue = 240;
            break;
        case 5:
            _red = 80; _green = 240; _blue = 240;
            break;
        default:
            break;
    }
    self.color = [UIColor colorWithRed:(_red)/255.0f green:(_green)/255.0f blue:(_blue)/255.0f alpha:1.0f];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(changeColor) userInfo:nil repeats:YES];
}

- (void)dealloc {
    [_timer invalidate];
    _timer = nil;
}

- (void)startAnimating {
    [super startAnimating];
    
    if (!_timer.isValid) {
        [_timer fire];
    }
}

- (void)stopAnimating {
    [super stopAnimating];
    
    [_timer invalidate];
}

- (void)changeColor {
    if (!self.isAnimating) {
        return;
    }
    
    if ((_red==max) && (_green==min) && (_blue!=max)) {
        _blue+=delta;
    }
    else if ((_green==min) && (_blue==max) && (_red!=min)) {
        _red-=delta;
    }
    else if ((_blue==max) && (_red==min) && (_green!=max)) {
        _green+=delta;
    }
    else if ((_red==min) && (_green==max) && (_blue!=min)) {
        _blue-=delta;
    }
    else if ((_green==max) && (_blue==min) && (_red!=max)) {
        _red+=delta;
    }
    else if ((_blue==min) && (_red==max) && (_green!=min)) {
        _green-=delta;
    }
    
    self.color = [UIColor colorWithRed:(_red)/255.0f green:(_green)/255.0f blue:(_blue)/255.0f alpha:1.0f];
}

@end
